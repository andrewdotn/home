import { expect } from "chai";
import { describe } from "mocha";
import { parseRemotes, parseRepoNameAndOrg, Remote } from "./remote";

describe("parse-remote", function () {
  it("works", function () {
    expect(
      parseRemotes(`
xyz	https://github.com/foo/bar (fetch)
xyz	you really didn’t want to do that (push)
github.com/foo2/bar	git@github.com:foo2/bar.git (fetch)
github.com/foo2/bar	git@github.com:foo2/bar (push)
`)
    ).to.eql([
      new Remote({
        url: "https://github.com/foo/bar",
        remoteName: "xyz",
        userOrOrg: "foo",
        repoName: "bar",
      }),
      new Remote({
        url: "git@github.com:foo2/bar.git",
        remoteName: "github.com/foo2/bar",
        userOrOrg: "foo2",
        repoName: "bar",
      }),
    ]);
  });
});

describe("parseRepoNameAndOrg", function () {
  for (const [input, expectOk, userOrOrg, repoName] of [
    ["https://github.com/foo/bar", true, "foo", "bar"],
    ["https://github.com/foo/bar.git", true, "foo", "bar"],
    ["https://github.com/foo/bar/", true, "foo", "bar"],
    // not github
    ["/foo/bar", false, null, null],
    ["example.com:foo/bar", false, null, null],
    ["git@example.com:foo/bar.git", false, null, null],
    // ssh
    ["github.com:foo/bar", true, "foo", "bar"],
    ["github.com:/foo/bar", true, "foo", "bar"],
    ["github.com:foo/bar.git", true, "foo", "bar"],
    ["github.com:/foo/bar.git", true, "foo", "bar"],
    ["git@github.com:foo/bar", true, "foo", "bar"],
    ["git@github.com:/foo/bar", true, "foo", "bar"],
    ["git@github.com:foo/bar.git", true, "foo", "bar"],
    ["git@github.com:/foo/bar.git", true, "foo", "bar"],
  ] as const) {
    it(`works on ${input}`, function () {
      const result = parseRepoNameAndOrg(input);
      if (!expectOk) {
        expect(result).to.be.false;
      } else {
        expect(result).to.eql({ userOrOrg, repoName });
      }
    });
  }
});
