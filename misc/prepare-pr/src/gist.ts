import { configFilePath, loadConfig } from "./config";
import { Octokit } from "@octokit/core";
import { RequestError } from "@octokit/request-error";
import type { paths } from "@octokit/openapi-types";
import yargs, { Options } from "yargs";
import { readFile, remove, writeFile } from "fs-extra";
import { basename, resolve } from "path";
import isValidUTF8 from "utf-8-validate";
import { run } from "./run";
import { dir } from "tmp-promise";

function stripTrailingSlash(url: string) {
  while (url.endsWith("/")) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

async function readStdin() {
  const ret = [];
  for await (const chunk of process.stdin) {
    ret.push(chunk);
  }
  return Buffer.concat(ret);
}

type GistPayload = paths["/gists"]["post"]["requestBody"]["content"]["application/json"];

async function postGist(ghClient: Octokit, gistContent: GistPayload) {
  try {
    return await ghClient.request("POST /gists", gistContent);
  } catch (e) {
    if (e instanceof RequestError) {
      if (e.status === 401) {
        console.error(`Unable to create gist at ${e.request.url}: ${e}`);
        process.exit(1);
      }
      if (e.status === 404) {
        const scopes = e.headers["X-OAuth-Scopes".toLowerCase()];
        if (
          typeof scopes === "string" &&
          !scopes.split(", ").includes("gist")
        ) {
          console.error(
            `Unable to create gist at ${e.request.url}: token is valid but lacks ‘gist’ scope. Token does have scopes: ${scopes}.`
          );
          process.exit(1);
        }
      }
    }
    throw e;
  }
}

const PLACEHOLDER_FILENAME = "_";

class GistBuilder {
  constructor({
    public_,
    description,
  }: {
    public_: boolean;
    description?: string;
  }) {
    this.payload = {
      public: public_,
      description,
      files: {},
    };
  }

  hasBinaries() {
    return this.binaries.size > 0;
  }

  build() {
    if (Object.keys(this.payload.files).length === 0) {
      this.payload.files[PLACEHOLDER_FILENAME] = { content: "\0" };
      this.placeholderUsed = true;
    }
    return this.payload;
  }

  addFile(filename: string, content: string | Buffer) {
    if (filename in this.payload.files || this.binaries.has(filename)) {
      throw new Error(`Duplicate file ‘${filename}’`);
    }
    if (filename.includes("/") || filename.includes("\\")) {
      throw new Error(
        `Sorry, ‘${filename}’ is invalid; gists do not support directories`
      );
    }
    if (/^\.+$/.test(filename)) {
      throw new Error("invalid filename");
    }

    if (typeof content === "string") {
      this.payload.files[filename] = { content };
      return;
    }
    // TODO: what if characters are valid UTF-8 but not valid in JSON?
    if (isValidUTF8(content)) {
      this.payload.files[filename] = { content: content.toString("utf-8") };
    } else {
      this.binaries.set(filename, content);
    }
  }

  payload: GistPayload;
  placeholderUsed = false;
  binaries = new Map<string, Buffer>();
}

async function main() {
  const config = await loadConfig();
  const hostDefaults: Options = {};
  if (config._default) {
    hostDefaults.default = config._default;
  }

  const argv = yargs
    .strict()
    .usage("$0 [options] [FILE...]")
    .epilog("If no files are specified, gist contents will be read from stdin")
    .option("host", { type: "string", ...hostDefaults })
    .option("open", {
      type: "boolean",
      default: true,
      description: "open a browser with the newly-created gist",
    })
    .option("public", { type: "boolean", default: "false" })
    .option("filename", {
      type: "string",
      default: "gist.txt",
      description: "Used for stdin input",
    })
    .option("description", { type: "string" })
    .option("verbose", { type: "boolean", description: "print gist object" })
    .option("dry-run", { type: "boolean", default: false }).argv;

  if (!argv.host) {
    console.error(`No host specified.`);
    process.exit(1);
  }
  const myConfig = config[argv.host as string];
  if (!myConfig) {
    console.error(`No config for ${argv.host} found in ${configFilePath()}`);
    process.exit(1);
  }
  const baseUrl = stripTrailingSlash(myConfig.apiUrl);

  const ghClient = new Octokit({
    auth: myConfig.token,
    baseUrl,
  });

  const gistBuilder = new GistBuilder({
    public_: (argv.public as any) as boolean,
    description: argv.description,
  });

  if (argv._.length === 0) {
    gistBuilder.addFile(argv["filename"], await readStdin());
  } else {
    for (const f of argv._ as string[]) {
      gistBuilder.addFile(basename(f), await readFile(f));
    }
  }

  if (argv["dry-run"]) {
    console.log(`Would post to ${baseUrl}/gists :`);
    console.log(gistBuilder.build());
    if (gistBuilder.hasBinaries()) {
      console.log(`And then use git to add ${gistBuilder.binaries.keys()}`);
    }
  } else {
    const gist = await postGist(ghClient, gistBuilder.build());

    if (argv.verbose) {
      console.log(gist);
    }

    const gitUrl = `git@${argv.host}:${gist.data.id}.git`;

    if (gistBuilder.hasBinaries()) {
      const tempDir = await dir();
      try {
        await run(["git", "clone", gitUrl, "."], { cwd: tempDir.path });
        if (gistBuilder.placeholderUsed) {
          await run(["git", "rm", PLACEHOLDER_FILENAME], { cwd: tempDir.path });
        }
        for (const [filename, content] of gistBuilder.binaries.entries()) {
          await writeFile(resolve(tempDir.path, filename), content);
        }
        await run(["git", "add", ...gistBuilder.binaries.keys()], {
          cwd: tempDir.path,
        });

        const gitAuthorName = (
          await run(["git", "log", "-n1", "--pretty=format:%an"], {
            cwd: tempDir.path,
          })
        ).stdout.trim();
        const gitAuthorEmail = (
          await run(["git", "log", "-n1", "--pretty=format:%ae"], {
            cwd: tempDir.path,
          })
        ).stdout.trim();

        await run(
          [
            "git",
            "commit",
            "--author",
            `${gitAuthorName} <${gitAuthorEmail}>`,
            "-m",
            "Add binaries",
          ],
          {
            env: {
              ...process.env,
              GIT_COMMITTER_NAME: gitAuthorName,
              GIT_COMMITTER_EMAIL: gitAuthorEmail,
            },
            cwd: tempDir.path,
          }
        );

        await run(["git", "push", gitUrl], { cwd: tempDir.path });
      } finally {
        await remove(tempDir.path);
      }
    }

    console.log(gist.data.html_url);
    if (argv.open) {
      await run(["open", gist.data.html_url!]);
    }
  }
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
