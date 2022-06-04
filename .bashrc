# ~/.bashrc: executed by bash for interactive non-login shells

# If this file is accidentally sourced multiple times, the next line will
# print a warning. Run bash --login -xv to get a dump.
readonly _HOME_BASHRC_ALREADY_READ=1

unset LC_ALL
export LANG=en_CA.UTF-8

unalias -a

if [ -e "${HOME}/.bashrc.local" ]; then
    . "${HOME}/.bashrc.local"
fi

function check_exit_status ()
{
    local status="$?"
    local signal=""

    if (( status != 0 )); then
        # If process exited by a signal, determine name of signal.
        if [ ${status} -gt 128 ]; then
            signal="$(builtin kill -l $((${status} - 128)) 2>/dev/null)"
            if [ "$signal" ]; then signal="($signal)"; fi
        fi
        if [ -z "$signal" ]; then
            echo "Returned ${status}." 1>&2
        else
            echo "Returned ${status} ${signal}." 1>&2
        fi
    fi
    return 0
}
PROMPT_COMMAND="check_exit_status; $PROMPT_COMMAND"
PROMPT_COMMAND="${PROMPT_COMMAND%; }"

## This was found on the internet many years ago
cd_func ()
{
    local x2 the_new_dir adir index
    local -i cnt

    if [[ $1 ==  "--" ]]; then
        dirs -v
        return 0
    fi

    set -- "$(echo "$1" |sed -e ':a
s@\.\.\.@../..@g
t a')"
    the_new_dir="$1"
    [[ -z "$1" ]] && the_new_dir="$HOME"

    if [[ ${the_new_dir:0:1} == '-' ]]; then
        #
        # Extract dir N from dirs
        index=${the_new_dir:1}
        [[ -z $index ]] && index=1
        adir=$(dirs +$index)
        [[ -z $adir ]] && return 1
        the_new_dir=$adir
    fi

    #
    # '~' has to be substituted by ${HOME}
    [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

    #
    # Now change to the new dir and add to the top of the stack
    pushd "${the_new_dir}" > /dev/null
    [[ $? -ne 0 ]] && return 1
    the_new_dir=$(pwd)

    #
    # Trim down everything beyond 11th entry
    popd -n +15 2>/dev/null 1>/dev/null

    #
    # Remove any other occurence of this dir, skipping the top of the stack
    for ((cnt=1; cnt <= 10; cnt++)); do
        x2=$(dirs +${cnt} 2>/dev/null)
        [[ $? -ne 0 ]] && return 0
        [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
        if [[ "${x2}" == "${the_new_dir}" ]]; then
            popd -n +$cnt 2>/dev/null 1>/dev/null
            cnt=cnt-1
        fi
    done

    return 0
}

if [ -d ~/.volta ]; then
    export VOLTA_HOME=~/.volta
fi

add_to_path() {
    # add_to_path VAR DIR...
    #
    # Adds each DIR that exists on disk to the front of the colon-separated
    # list $VAR. If DIR Is already in the list, it is moved to the front.
    #
    # For example,
    #   add_to_path PATH ~/bin /opt/local/bin
    # is like doing
    #   PATH=~/bin:/opt/local/bin:${PATH}
    # except that the directories will be added to the front of $PATH only
    # if they exist, and will not appear multiple times in $PATH.

    path_name="${1}"
    shift
    eval local path=\"\${"${path_name}"}\"

    # Add leading and trailing colon to allow matching on :/path-path:
    local path="${path%:}:"
    path=":${path#:}"
    local extra_parts=
    local p

    for arg in "${@}"; do
        if [ -d "${arg}" ]; then
            p="${extra_parts}:"
            if [ "${p}" != "${p//:${arg}:/:}" ]; then
                # Skip duplicate argument
                continue
            fi

            # Need to loop because // cannot remove overlapping duplicates
            # like :foo:foo:
            while [ "${path}" != "${path//:${arg}:/:}" ]; do
                path="${path//:${arg}:/:}"
            done
            extra_parts="${extra_parts}:${arg}"
        fi
    done
    extra_parts="${extra_parts#:}"
    path="${path%:}"
    path="${path#:}"

    path="${extra_parts}:${path}"
    # Clean again in case either part was empty
    path="${path%:}"
    path="${path%#}"
    eval export "${path_name}"="\${path}"
}

JAVA_HOME="$(/usr/libexec/java_home -F 2>/dev/null)"
if [ -z "${JAVA_HOME}" ] && [ -d /usr/java/latest ]; then
    JAVA_HOME="$(readlink /usr/java/latest)"
fi

if [ -n "${JAVA_HOME}" ]; then
    export JAVA_HOME
    JAVA_HOME_BIN="${JAVA_HOME}/bin"
else
    # If JAVA_HOME is unset, add_to_path below would put `/bin` way too
    # early
    JAVA_HOME_BIN=~/bin
fi

# gls often won’t be found until after setting PATH, but it’s needed for
# ls_drv_if_exist
for F in /opt/homebrew/bin/gls /opt/homebrew-x64/bin/gls; do
    if [ -x "${F}" ]; then
        GNU_LS_CMD="${F}"
        break
    fi
done

function ls_drv_if_exist() {
    if [ -e "${1}" ]; then
        "${GNU_LS_CMD:-ls}" -drv "${@}"
    fi
}

add_to_path PATH \
    ~/work/bin \
    /opt/chef-workstation/bin \
    /opt/chefdk/bin \
    ~/ruby-shim/bin \
    ~/bin \
    ~/go/bin \
    ~/.local/bin \
    ~/.cargo/bin \
    "$VOLTA_HOME/bin" \
    $(ls_drv_if_exist ~/opt/node/*/bin) \
    $(ls_drv_if_exist ~/Library/Python/*/bin) \
    $(ls_drv_if_exist ~/.gem/ruby/*/bin) \
    $(ls_drv_if_exist ~/.local/share/gem/ruby/*/bin) \
    $(ls_drv_if_exist ~/.gem/jruby/*/bin) \
    ~/.yarn/bin \
    "${JAVA_HOME_BIN}" \
    /opt/texlive2020/bin/x86_64-darwin \
    $(ls_drv_if_exist /Library/Frameworks/Python.framework/Versions/*/bin) \
    $(ls_drv_if_exist ~/.pyenv/versions/*/bin) \
    $(ls_drv_if_exist /opt/ruby/*/bin) \
    $(ls_drv_if_exist /opt/jruby/*/bin) \
    ~/perl5/bin \
    ~/opt/miniconda3/bin \
    /opt/gradle/bin \
    /opt/homebrew/bin \
    /opt/homebrew/sbin \
    /opt/homebrew-x64/bin \
    /opt/homebrew-x64/sbin \
    /opt/vagrant/bin \
    /opt/packer \
    /usr/local/go/bin \
    /opt/go/bin \
    ~/Android/Sdk/cmdline-tools/latest/bin \
    ~/opt/csdr/bin \
    ~/opt/git/bin \
    ~/Library/Application\ Support/JetBrains/Toolbox/bin \
    ~/.local/share/JetBrains/Toolbox/bin \
    /Library/Developer/CommandLineTools/usr/bin \
    /usr/libexec \
    ;

add_to_path INFOPATH \
    /opt/homebrew/share/info \
    /opt/homebrew-x64/share/info \
    ;

MANPATH="$(manpath 2>/dev/null)"
add_to_path MANPATH \
    /Library/Developer/CommandLineTools/usr/share/man \
    /usr/llvm-gcc-*/share/man \
    /usr/local/MacGPG2/share/man \
    ~/Library/Python/*/lib/python/site-packages/*.egg/share/man \
    /opt/homebrew-x64/lib/node_modules/*/man \
    /opt/homebrew-x64/lib/erlang/man \
    /Library/Frameworks/R.framework/Resources \
    /usr/local/lib/node_modules/*/man \
    /usr/local/MacGPG2/share/man \
    ~/xgit/docker/man \
    ;

alias cd=cd_func

## Aliases

alias erase=rm
# note, macOS cp does not have a -h/--help option
if cp --help 2>/dev/null | grep -q reflink; then
    alias cp='cp -i --reflink=auto'
else
    alias cp='cp -i'
fi
alias mv='mv -i'
alias rm='rm -i'
if grep --help 2>&1 | grep -q color; then
    alias grep='grep --color=auto'
fi
alias import="echo \"You thought you were in a python shell, didn't you?\"
              false"
alias latex='latex -interaction=nonstopmode'
alias pdflatex='pdflatex -interaction=nonstopmode'
alias xelatex='xelatex -interaction=nonstopmode'
alias tree='tree -aF'
# Only affects repl; `node --use_strict foo.js` does nothing
alias node='node --use_strict --experimental-repl-await'

if type -p setsid >& /dev/null; then
    for F in \
        idea \
        pycharm \
        webstorm \
    ; do
    alias $F="setsid $F < /dev/null >& /dev/null"
    done
fi

if type -p gls >& /dev/null; then
    GNU_LS_CMD=gls
elif ls --version 2>&1 | grep -q GNU; then
    GNU_LS_CMD="$(type -p ls)"
fi

if [ -n "${GNU_LS_CMD}" ]; then
    # Process argument list and insert --si if -h is given
    ls() {
        local ARGS=()
        local process=true
        local dash_h_seen=false
        for A in "${@}"; do
            if ! $process; then
                ARGS+=("${A}")
                continue
            fi

            if [ "${A}" = "--" ]; then
                process=false
                if $dash_h_seen; then
                    ARGS+=("--si")
                fi
            fi

            if (( ${#A} >= 2 )); then
                if [ "${A:0:1}" = "-" ] && [ "${A:1:1}" != "-" ]; then
                    for (( i = 0; i < ${#A}; i++ )); do
                        if [ "${A:i:1}" = "h" ]; then
                            dash_h_seen=true
                        fi
                    done
                fi
            fi

            ARGS+=("${A}")
        done
        if $process && $dash_h_seen; then
            ARGS+=("--si")
        fi
        "${GNU_LS_CMD}" "--block-size='1" -AF --color=auto "${ARGS[@]}"
    }
else
    alias ls='ls -AF'
fi

function mytmpdir() {
    local t="$(mktemp -dt ${LOGNAME}.XXXXXX)"
    cd "${t}"
}

function datedir() {
    local DATE="$(date +%Y-%m-%d)"
    mkdir -p "${DATE}"
    cd "${DATE}"
}

## Variables for export
export LS_COLORS='no=00:fi=00:di=34:ln=36:pi=40;33:so=35:do=35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=32:ow=48;5;158:'
export LSCOLORS="exgxfxdxcxdaDa"
export CLICOLOR=1
export GCC_COLORS=1

unset LD_ASSUME_KERNEL
export EDITOR=vim
export VISUAL=vim
export BLOCK_SIZE=1
export PAGER=less
export GIT_PAGER="diff-highlight | less -R"
export LESS='-iM -z-3 -j3'
if less --help |grep -q -- --mouse-support; then
    export LESS="${LESS} --mouse-support"
fi
export PERLDOC_PAGER="less -fr"
export RI="--format bs"
export RUBYLIB=~/.ruby
if type -p nproc >& /dev/null; then
    CORE_COUNT="$(nproc)"
elif type -p gnproc >& /dev/null; then
    CORE_COUNT="$(gnproc)"
else
    CORE_COUNT="$(python3 -c "
import multiprocessing
print multiprocessing.cpu_count()")"
fi
export BUNDLE_JOBS="${CORE_COUNT}"
# Pseudo word wrap instead of truncation.
# https://github.com/erikhuda/thor/commit/1f91d12fce7
export THOR_COLUMNS=100000
export PERL_MM_USE_DEFAULT=1
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
export PERL5LIB="$HOME/perl5/lib/perl5"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5"
export PERL_MB_OPT="--install_base \"$HOME/perl5\""
export PYTHONSTARTUP=~/.pyrc
export PYTHONPATH=~/.python
export DOCKER_BUILDKIT=1
export BASH_SILENCE_DEPRECATION_WARNING=1
export CHEF_TELEMETRY_OPT_OUT=1
# Remove -S from the default ca. early-2021
export SYSTEMD_LESS="FRXMK"

# https://stackoverflow.com/questions/64570510/why-does-pip3-want-to-create-a-kdewallet-after-installing-updating-packages-on-u
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring

export HOMEBREW_DISPLAY_INSTALL_TIMES=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1

if type -p sccache >& /dev/null; then
    export RUSTC_WRAPPER="$(which sccache)"
fi

# Keep Vagrant VMs where they won’t clog Time Machine
case "${OSTYPE}" in
    darwin*)
        export VAGRANT_VMWARE_CLONE_DIRECTORY=~/Virtual\ Machines.localized/Vagrant
        export VAGRANT_DEFAULT_PROVIDER=vmware_fusion
        ;;
esac
export PACKER_CACHE_DIR=~/Downloads

export CVS_RSH=ssh

## Shell settings

shopt -s cdspell checkwinsize dotglob checkhash
# Stop expansions like ~/.* from including ~/..
export GLOBIGNORE="*/.:*/.."

# Completion
for COMPLETION_FILE in \
    /opt/homebrew/etc/bash_completion \
    /opt/homebrew-x64/etc/bash_completion \
    /etc/bash_completion \
; do
    [ -f "${COMPLETION_FILE}" ] && . "${COMPLETION_FILE}" ]
done
# Disable default tilde-expansion
function _expand() {
    :
}
function __expand_tilde_by_ref() {
    :
}
# The default is _root_command which limits PATH, but that breaks sudo -e
complete -r sudo 2>/dev/null
complete -r kubectl 2>/dev/null
complete -r scp 2>/dev/null
complete -r rsync 2>/dev/null
complete -r vim 2>/dev/null
complete -r unzip 2>/dev/null

umask 022 # rw-r--r--

MAILCHECK=-1

## Terminal

# Are we on a terminal?
if [ -t 0 ];
then
    stty sane
    stty stop ''
    stty start ''
    stty werase ''
fi

# IntelliJ’s terminal supports 256 colours, but sets TERM to plain xterm
if [ "${TERM}" = xterm ] \
        && ps -o command "${PPID}" 2>/dev/null | grep -q IntelliJ;
then
    TERM="xterm-256color"
fi

case "${TERM}" in
    # http://nion.modprobe.de/blog/archives/572-less-colors-for-man-pages.html
    xterm-256color)
            export LESS_TERMCAP_md=$'\e[35m'
            export LESS_TERMCAP_us=$'\e[38;5;19m'
            export LESS_TERMCAP_ue=$'\e[0m'
            export GREP_COLOR='48;5;226'
            ;;

    xterm*)
	    export LESS_TERMCAP_md=$'\e[35m';;
    dumb)
	    # The default cygwin prompt sets the xterm title, which gets
	    # mangled in xemacs shell mode.
	    PS1="${PS1#\\[\\e\]0;\\w\\a\\\]}";;
esac

# Set the prompt colour as a function of hostname
PROMPT_COLOURS=(1 2 4 6 8 12 13 18 19 21 27 28 29 53 58 134)
HOST_COLOUR_INDEX="$(python3 -c "
import socket
import codecs
n = int(codecs.encode(socket.gethostname().encode('UTF-8'), 'hex'), 16)
print(n % ${#PROMPT_COLOURS[@]})")"
HOST_COLOUR="${PROMPT_COLOURS[${HOST_COLOUR_INDEX}]}"

PS1="\u@\h:\w\\\$ "
TERM_EXTRA="\e]2;\D{%a %b %e %k:%M:%S}\a"
case "${TERM}" in
   xterm-256color)
     PS1="\[\e[38;5;${HOST_COLOUR}m\]${PS1}\[\e[0m${TERM_EXTRA}\]" ;;
   xterm*)
     PS1="\[\e[34m\]${PS1}\[\e[0m${TERM_EXTRA}\]" ;;
   *) ;;
esac
ORIG_PS1="${PS1}"

# History settings
HISTFILE=~/.bash_history
HISTSIZE=10000000
HISTFILESIZE=${HISTSIZE}
HISTCONTROL=ignorespace:ignoredups
# This is only used by the output of the history builtin
HISTTIMEFORMAT="%a %Y-%m-%d %H:%M:%S "
shopt -s histappend
# I type exclamation marks in strings more often than I use the ! history
# command, so place the history command on something unlikely to be typed.
histchars=$'\177^#'
export -n HISTFILE HISTSIZE HISTFILESIZE HISTIGNORE HISTTIMEFORMAT

# Sometimes bash history gets mysteriously trimmed; this keeps a copy at
# most one hour old, and warns when trimming happens.
function snapshot_bash_history_hourly() {
    if [ "${HISTFILE}" -nt "${HISTFILE}.checkstamp" ]; then
        python -c '
from __future__ import print_function

import fcntl
import os
import sys
import time

histfile, checkstamp = sys.argv[1:]
backup_file = histfile + ".hourly"

def file_size(path):
    return os.stat(path).st_size

def file_time(path):
    return os.stat(path).st_mtime

if os.path.exists(backup_file) and file_size(histfile) < file_size(backup_file):
    sys.stderr.write("Warning: bash_history size shrunk!\n")
    sys.exit(1)

with open(histfile, "r") as infile:
    fcntl.flock(infile, fcntl.LOCK_EX)
    try:
        if (not os.path.exists(backup_file)
                or file_time(backup_file) < time.time() - 60):
            with open(backup_file + ".tmp", "w") as outfile:
                outfile.write(infile.read())
            os.rename(backup_file + ".tmp", backup_file)
    finally:
        fcntl.flock(infile, fcntl.LOCK_UN)

# Touch a file 1 hour into the future to avoid both having to do date
# computations in shell and forking python often
future_time = time.time() + 60 * 60
if not os.path.exists(checkstamp):
    with open(checkstamp, "w") as f:
        pass
os.utime(checkstamp, (future_time, future_time))

' "${HISTFILE}" "${HISTFILE}.checkstamp"
    fi
}
PROMPT_COMMAND="$PROMPT_COMMAND; snapshot_bash_history_hourly;"
PROMPT_COMMAND="${PROMPT_COMMAND#; }"

# Documentation is sorely lacking, but the built-in clang(++) can no longer
# find standard header files on my machine running 10.15.3. For example:
#
#     $ echo '#include <stdio.h>' | clang -v -E -
#     ...
#     <stdin>:1:10: fatal error: 'stdio.h' file not found
#
# This workaround is pulled from part of the discussion on
#
# https://github.com/Homebrew/homebrew-core/pull/45304
# “llvm: add missing flag for macOS Catalina”
if type -p xcrun >& /dev/null; then
    export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
fi

function presentation_terminal() {
    export IN_PRESENTATION=true
    PS1="$ "
    xterm-title ''
    function update_terminal_cwd() { :; }
    printf '\e]7;%s\a' file:///System/Applications/Utilities/Terminal.app
    clear
}
if [ "${IN_PRESENTATION}" = "true" ]; then
    presentation_terminal
fi

trap 'history -a' DEBUG

# Ubuntu sources ~/.profile which sources ~/.bashrc from an X startup script
set_history=true
for F in "${BASH_SOURCE[@]}"; do
    if [ "${F}" = "/etc/gdm3/Xsession" ]; then
        set_history=false
    fi
done

# Needs to be last command in file
#
# DO NOT ADD ANYTHING AFTER THIS
$set_history && set -o history
