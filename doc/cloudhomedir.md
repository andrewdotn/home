<!DOCTYPE html>
<!-- This dialect of Markdown-in-HTML works with
     https://pypi.python.org/pypi/Markdown/2.0.1 -->
<html>
<head>
<meta charset=UTF-8>
<title>cloudhomedir functional specification</title>
<style>
body {
    background-color: #ccc;
    margin: 0;
}
body #content {
    max-width: 30em;
    margin: 1em auto;
    background-color: white;
    border: 1px solid black;
    padding: 0 1em;
}
.warning {
    border: 1px solid red;
    padding: 0 1em;
    background-color: #fff799;
    font-size: 120%;
}
.technote, .openissue {
    padding: 0 1em;
    margin-bottom: 1em;
    clear: both;
}
.technote {
    border: 1px solid gray;
    background-color: #d9edc6;
}
ul .technote, ul .openissue {
    margin-right: 30px;
}
.technote h1, .openissue h1 {
    font-size: 100%;
}
.openissue {
    border: 1px solid red;
    background-color: #fdc689;
}
pre {
    float: left;
    margin: 0;
}
pre code {
    border: 1px solid #bbb;
    display: block;
    padding: 0.5em 2em 0.5em 0.25em;
    margin: 0 2em 1em  0;
    background-color: #f5f5f5;
}
code {
    background-color: #f5f5f5;
    outline: 1px solid #eee;
}
p code {
    padding: 1px 3px;
    white-space: nowrap;
}
h1, h2, h3, h4, h5, h6, p {
    clear: both;
}
</style>
</head>
<body>
<div id=content>

# cloudhomedir specification
## Andrew Neitsch
### June 2013

<div class=warning>

#### Disclaimer

**This is not complete.** This [functional specification][joel-specs] is a
work-in-progress that will need extensive rewriting and many additional
details before it is finished. It reflects the current understanding of how
the software should work.

Both the current development version and the final completed version are
likely to be substantially different from what is described here.

If you have any comments, concerns, or ideas for improvement, please let
the author know!

 [joel-specs]: http://www.joelonsoftware.com/articles/fog0000000036.html

</div>

## Overview

`cloudhomedir` automatically sets up your command-line environment on new
machines, and keeps it in sync across all of your machines.

Not only does it keep your dotfiles and scripts in sync, but it also has
these handy features:

- It can combine files from multiple source-control repositories, so that
  you can publish most of your dotfiles and scripts on the web, while
  keeping more sensitive files like `~/.ssh/config` private.

- It automatically recognizes new dotfiles that you edit and starts
  tracking them for you, without getting confused by all the other `~/.*`
  files you don’t care about.

- Automatically runs setup scripts. e.g. make directories like ~/tmp with
  appropriate privileges.

- For convenience and portability, it automatically creates cross-platform
  wrapper scripts.

## cloudhomedir

`cloudhomedir` reads the configuration file `~/.cloudhomedir`

For now, mercurial is the only supported version control system.

### `[repositories]`

The contents of all repositories specified in this section are aggregated
and symlinked into `~`.

The syntax is

    PATH-TO-REPO = [option]...

Currently, `PATH-TO-REPO` must be a local path to a working directory on
disk, not a remote path.

<div class=openissue>

#### Open issue

cloudhomedir should query the version control system and only link
committed files. But what if you’re setting up a new machine, you don’t
have your version control system configured yet, and you were hoping to
have cloudhomedir do that for you?

</div>

    [repositories]
    ~/home =
    ~/home.private = private

Current options are:

<dl>
<dt><code>private</code></dt>
<dd>All files and directories linked from this repository will have
permissions set so that only the owner can access them.
</dd>
</dl>

#### Handling conflicts

If the same file is included in multiple repositories, use the version from
the first repository listed. Maybe print a warning in verbose mode.

When going to symlink a file from a repository, e.g., making `~/.foo` a
symlink to `home/.foo`, it may happen that a file already exists where the
symlink is supposed to go.

  - If it is a directory, that is an error.

  - It may be a regular file that has the same contents as the file in the
    repository. For example this will happen if someone copies an existing
    file into the repo, and then tries to sync.

    In this case, replace the file with a symlink.

  - If the file contents are not identical, do a unified diff and use some
    sort of heuristic to guess if they are different versions of the same
    file, or if they are totally different. For example, are at least

        max(4 lines, 60% of the number of lines in the longer file)

    identical?

    If they appear to be different versions of the same file, and the
    repository version has no uncommitted changes, then replace the
    repository version and make the symlink.

    Otherwise, do not change any files, and warn the user.

#### Why support multiple repositories?

Most things should probably be public, but there are some things that
should definitely be private. For example, your your personal dictionary
for your editor will contain the names of all the people you’ve written
about in your diary. Your `~/.ssh/config` file often contains the hostname
and your username(s) for every account you have access to--which is a bad
thing to have public if someone ever tries to hack you!

<div class=openissue>

#### Open issue

Technically this could also support sharing repositories—someone could
publish the ultimate configuration for `foo`, and you could list it here.

</div>


### `[filter]`

    exclude = .hgignore
    exclude = .gitignore
    exclude = path/to/script.testinput
    exclude = *~

### `[aliases]`

This section allows you to automatically generate wrapper scripts.

    photoshop = "Adobe Photoshop CS4.app"
    skim = Skim.app
    gdate = date gdate --version~="GNU coreutils"

<div class=technote>

#### Technical note

Use shlex for parsing

</div>

## Setup

## Non-goals

  - Templating. Some dotfiles contain user-specific information, such as
    your real name and email in `~/.hgrc`. If there was a templating
    system, e.g., a `/.hgrc.in` file with `username = @USERNAME@`, then it
    would be possible for different people to use the same repository and
    merge in patches and so on.

    But configuring all the command-line software you use is such a
    personal thing that there really isn’t enough overlap between the
    configurations of different people to justify the added complexity.
    People pick and choose bits of things they need over *decades*—there’s
    no point in trying to keep that in sync between a bunch of different
    people.

## Open issues

- How to notice new dotfiles that should be checked in? Editor hook that
  notices when you edit a dotfile, and automatically adds it to a list of
  files to track.

</div>
</body>
</html>
