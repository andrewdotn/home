import yargs from "yargs";
import { run, runInteractively } from "./run";
import { parseRemotes } from "./remote";
import { queryGh } from "./gh-query";
import { dir } from "tmp-promise";
import { remove } from "fs-extra";
import { promisify } from "util";
import read from "read";

/**
 * Return the single object matching predicate, or raise an exception
 * if zero or multiple objects match.
 */
function findOne<T>(list: Iterable<T>, predicate: (t: T) => boolean): T {
  let found = false;
  let result: T;
  for (const t of list) {
    if (predicate(t)) {
      if (found) {
        throw Error("Multiple objects match predicate");
      }
      found = true;
      result = t;
    }
  }
  if (found) {
    return result!;
  }
  throw Error("No objects match predicate");
}

function stripSuffix(string: string, suffix: string) {
  if (string.endsWith(suffix)) {
    return string.substring(0, string.length - suffix.length);
  }
  return string;
}

async function preparePr() {
  const argv = yargs
    .strict()
    .option("pick", { type: "array", nargs: 1 })
    .option("new-branch-name", { type: "string", default: "<slug>" })
    .option("pr-base-commit", {
      type: "string",
      help: "default: tip of parent repo’s default branch",
    })
    .demandCommand(0, 0).argv;

  const remoteInfo = (await run(["git", "remote", "-v"])).stdout;
  const ghRepos = await parseRemotes(remoteInfo);

  const ghInfo = await queryGh(ghRepos);

  const user = ghInfo.viewer.viewer.login;
  const personalRemote = findOne(
    ghInfo.repos.keys(),
    (r) => ghInfo.repos.get(r)!.repository?.owner.login === user
  );

  if (!ghInfo.repos.get(personalRemote)!.repository?.isFork) {
    throw Error("personal remote is not a fork");
  }

  const mainForkRemote = findOne(
    ghInfo.repos.keys(),
    (r) =>
      ghInfo.repos.get(r)!.repository?.url ===
      ghInfo.repos.get(personalRemote)!.repository?.parent?.url
  );

  let gitTopLevel = (await run(["git", "rev-parse", "--show-toplevel"])).stdout;
  gitTopLevel = stripSuffix(gitTopLevel, "\n");

  let prBaseCommit =
    argv["pr-base-commit"] ??
    ghInfo.repos.get(mainForkRemote)!.repository?.defaultBranchRef?.target?.oid;
  if (!prBaseCommit) {
    throw new Error("Unknown base commit");
  }

  const commitList: string[] = [];
  if (argv.pick && argv.pick.length > 0) {
    commitList.splice(0, 0, ...(argv.pick as string[]));
  } else {
    const commitListText = (
      await run([
        "git",
        "rev-list",
        "--topo-order",
        // defaults to showing newest first
        "--reverse",
        // https://stackoverflow.com/questions/462974/what-are-the-differences-between-double-dot-and-triple-dot-in-git-com
        // r1..r2 for rev-parse means, commits reachable from r2 but not r1
        `${prBaseCommit}..HEAD`,
      ])
    ).stdout;
    for (let line of commitListText.split("\n")) {
      line = line.trim();
      if (line) {
        commitList.push(line);
      }
    }
  }

  if (commitList.length === 0) {
    throw new Error("must specify some commits to pick");
  }

  const tempDir = await dir();
  try {
    await run(["git", "clone", "--shared", gitTopLevel, "."], {
      cwd: tempDir.path,
    });
    await run(["git", "reset", "--hard", prBaseCommit], {
      cwd: tempDir.path,
    });

    let newBranch = argv["new-branch-name"];
    if (newBranch === "<slug>") {
      // git-log(1), %f: “sanitized subject line, suitable for a filename”
      newBranch = (await run(["git", "log", "--pretty=format:%f", "-n1"]))
        .stdout;
    }

    for (const devCommitHash of commitList) {
      const commitDate = (
        await run(
          ["git", "log", "-n1", "--pretty=format:%aD", "-n1", devCommitHash],
          {
            cwd: tempDir.path,
          }
        )
      ).stdout.trim();

      await run(["git", "cherry-pick", devCommitHash], {
        cwd: tempDir.path,
        env: { ...process.env, GIT_COMMITTER_DATE: commitDate },
      });
    }

    console.log(`cherry picked thing to ${newBranch} in ${tempDir.path}`);

    const newHead = (
      await run(["git", "rev-parse", "HEAD"], { cwd: tempDir.path })
    ).stdout.trim();

    // Copy the new commit into the original repo
    await run(["git", "fetch", "--no-write-fetch-head", tempDir.path, newHead]);

    console.log(
      (await run(["git", "log", `${prBaseCommit}..${newHead}`])).stdout
    );

    const pushCommand = [
      "git",
      "push",
      // Create upstream tracking branch
      "-u",
      personalRemote.url,
      newBranch,
    ];

    const mainForkDefaultBranch = ghInfo.repos.get(mainForkRemote)!.repository
      ?.defaultBranchRef?.name;
    const openCommand = [
      "open",
      `https://github.com/${mainForkRemote.owner}/${mainForkRemote.repoName}/compare/${mainForkDefaultBranch}...${personalRemote.owner}:${newBranch}?expand=1`,
    ];

    let input;
    let breakOutOfLoop = false;
    while (
      (input = await promisify(read)({
        prompt: "What next? Type ‘h’ for help: ",
      }))
    ) {
      switch (input) {
        case "p":
          // Runs in original dir, not tmpdir, so that `git push -u` creates
          // upstream tracking info in correct working dir
          await run(["git", "branch", newBranch, newHead]);
          await run(pushCommand);
          break;
        case "o":
          await run(openCommand);
          break;
        case "q":
          breakOutOfLoop = true;
          break;
        case "s":
          try {
            await runInteractively(["bash", "--login"], { cwd: tempDir.path });
          } catch (e) {
            console.error(e);
          }
          break;
        default:
          console.log("Press p to push:", pushCommand);
          console.log("Press o to open:", openCommand);
          console.log("Press q to quit");
          console.log("Press s for shell");
      }
      if (breakOutOfLoop) {
        break;
      }
    }
  } finally {
    await remove(tempDir.path);
  }
}

if (require.main === module) {
  preparePr().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
