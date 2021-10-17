#!/usr/bin/env python

__doc__ = """
Delete branches, both locally and on the given remote(s), that have been
merged to the current branch.
"""

from argparse import ArgumentParser, BooleanOptionalAction
from collections import defaultdict
from subprocess import check_call, check_output
from textwrap import dedent


def test_load_branches():
    def check_output(cmd):
        if cmd == ["git", "remote", "-v"]:
            return b"foo whatever\nbar whatever\n"
        elif cmd[:2] == ["git", "for-each-ref"]:
            return dedent(
                """
                refs/heads/main 123 blah
                refs/remotes/foo/x12 123
            """
            ).encode("UTF-8")
        else:
            raise Exception("unmocked output")

    assert load_branches(check_output) == [
        {
            "name": "main",
            "commit": "123",
            "remote": None,
            "upstream": "blah",
            "ref": "refs/heads/main",
        },
        {
            "name": "x12",
            "remote": "foo",
            "commit": "123",
            "ref": "refs/remotes/foo/x12",
            "upstream": None,
        },
    ]


def load_branches(check_output=check_output):
    remote_text = (
        check_output(
            [
                "git",
                "remote",
                "-v",
            ]
        )
        .decode("utf-8")
        .strip()
    )
    remotes = set()
    for line in remote_text.split("\n"):
        if line:
            remotes.add(line.split()[0])

    # https://stackoverflow.com/questions/3846380/how-to-iterate-through-all-git-branches-using-bash-script
    ref_and_upstream = (
        check_output(
            [
                "git",
                "for-each-ref",
                "--format",
                # objectname is documented in git-cat-file(1)
                "%(refname) %(objectname) %(upstream)",
                "refs",
                "--merged",
            ]
        )
        .decode("utf-8")
        .strip()
    )

    branches = []

    for line in ref_and_upstream.split("\n"):
        if not line.strip():
            continue
        pieces = line.split()

        if len(pieces) == 3:
            branch_ref, commit, upstream = pieces
        elif len(pieces) == 2:
            upstream = None
            branch_ref, commit = pieces
        else:
            raise Exception(
                f"expected 2 or 3 pieces in {line!r}, got {len(line)} instead"
            )

        # `foo/bar/baz` could be branch `baz` on remote `foo/bar`, or
        # branch `bar/baz` on remote `foo`
        remote = None
        for r in remotes:
            prefix = f"refs/remotes/{r}/"
            if branch_ref.startswith(prefix):
                remote = r
                name = branch_ref.removeprefix(prefix)
                break
        if remote is None:
            if branch_ref.startswith("refs/heads/"):
                name = branch_ref.removeprefix("refs/heads/")

        branches.append(
            {
                "ref": branch_ref,
                "name": name,
                "commit": commit,
                "upstream": upstream,
                "remote": remote,
            }
        )

    return branches


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("remote", nargs="*")
    parser.add_argument("--dry-run", action=BooleanOptionalAction)
    args = parser.parse_args()

    if len(args.remote) == 0 and not args.dry_run:
        print("Warning: no remote specified, using dry run mode")
        args.dry_run = True

    current_branch = (
        check_output(["git", "branch", "--show-current"]).decode("utf-8").strip()
    )

    branches = load_branches()

    local_branches_to_delete = []
    remote_branches_to_delete = defaultdict(list)

    # for now, n^2 linear search
    for i, b1 in enumerate(branches):
        for j, b2 in enumerate(branches):
            if j <= i:
                continue

            if b1["name"] != b2["name"]:
                continue
            if b1["commit"] != b2["commit"]:
                continue
            if b1["name"] in ["main", "master", current_branch]:
                continue

            # without loss of generality, b1 is local
            if b1["remote"] is not None:
                b1, b2 = b2, b1

            # One must be local, one remote
            if not ((b1["remote"] is None and b2["remote"] is not None)):
                continue

            print(f"{b1['ref']} = {b2['ref']}")

            local_branches_to_delete.append(b1["name"])
            remote_branches_to_delete[b2["remote"]].append(b2["name"])

    if args.dry_run:
        print("locally deleteable branches: ", local_branches_to_delete)
        print("remote deleteable branches: ", remote_branches_to_delete)

    for r in args.remote:
        if remote_branches_to_delete[r]:
            cmd = ["git", "push", "-d", r] + remote_branches_to_delete[r]
            print(cmd)
            if not args.dry_run:
                check_call(cmd)
            remote_branches_to_delete[r] = []

    # Only delete a local branch if it is not on any remote. Otherwise we
    # could be leaving an orphan branch on a different remote, with no
    # local branch to point out later that it can be deleted.
    ok_to_delete_locally = set()
    for b in local_branches_to_delete:
        if any(b in remote_branches_to_delete[r] for r in remote_branches_to_delete):
            continue
        ok_to_delete_locally.add(b)

    if len(ok_to_delete_locally) > 0:
        cmd = ["git", "branch", "-d"] + list(ok_to_delete_locally)
        print(cmd)
        if not args.dry_run:
            check_call(cmd)


if __name__ == "__main__":
    main()
