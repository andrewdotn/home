export class Remote {
  constructor(args: {
    url: string;
    remoteName: string;
    userOrOrg: string;
    repoName: string;
  }) {
    this.url = args.url;
    this.remoteName = args.remoteName;
    this.owner = args.userOrOrg;
    this.repoName = args.repoName;
  }

  readonly url: string;
  readonly remoteName: string;
  readonly owner: string;
  readonly repoName: string;
}

export function parseRemotes(s: string) {
  const ret = [];
  const seenRemotes = new Set();

  for (let line of s.split("\n")) {
    if (!line.trim()) {
      continue;
    }
    const match = /^([^\t]+)\t([^\t]+) \([a-z]+\)$/.exec(line);
    if (!match) {
      continue;
    }

    const remoteName = match[1];
    const url = match[2];

    if (seenRemotes.has(remoteName)) {
      continue;
    }
    const parsedRepoName = parseRepoNameAndOrg(url);
    if (parsedRepoName) {
      seenRemotes.add(remoteName);
      ret.push(
        new Remote({
          url,
          remoteName,
          ...parsedRepoName,
        })
      );
    }
  }
  return ret;
}

export function parseRepoNameAndOrg(remoteUrl: string) {
  const match = /^(?:git@|https:\/\/|)(?:www\.)?github.com[:\/]\/?([^\/]+)\/([^\/]+?)(?:\.git)?\/?$/.exec(
    remoteUrl
  );
  if (match) {
    return { userOrOrg: match[1], repoName: match[2] };
  }
  return false;
}
