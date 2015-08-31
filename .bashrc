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

# Mac OS Unicode support for Terminal.app and bash
#
# This overrides the default update_terminal_cwd() function, which sends an
# escape code with the current directory to the terminal, by properly
# quoting the URL. This makes the icon in the titlebar work for directories
# with non-ASCII names.
#
# It also sets PS1 to an expanded version of $ORIG_PS1 in which \w is
# replaced with a version of $PWD in the Normalization Form C that bash
# understands, as opposed to Mac OS’s default Normalization Form D.
# Otherwise, in directories with non-ASCII names, e.g., andré, the
# combining characters in the prompt totally confuse readline: entering
# long commands will wrap to the beginning of the same line, the prompt
# will disappear, and trying to backspace out of the mess will erase the
# output of previous commands, because readline doesn’t know what line the
# cursor is on anymore. Even with this hack, readline still gets a bit
# confused, but no longer gets totally confused.
#
# Calling Python on every directory change is a bit heavy-handed, but
# nothing simpler works correctly!
#
# To test changes, create directories with crazy names like \$PWD, `, \\\",
# and so on, then run:
#
# for F in *; do (echo in "${F}" && cd "$F" && bash); done; echo done
#
# using Ctrl-D to exit each test shell.
#
update_terminal_cwd () {

    if [ "${PWD}" = "${PREV_PWD}" ]; then
        return
    fi

    eval "$(python -sSEc '
import sys
sys.path.remove("")

import os
import unicodedata
import urllib

pwd = os.getenv("PWD", os.getcwd())
print "local URLQUOTED_PWD=%s" % urllib.quote(pwd)

home = os.getenv("HOME", "")
rel_pwd = pwd
if rel_pwd.startswith(home):
    rel_pwd = "~" + pwd[len(home):]
# Yes that is a large number of backslashes, but they need to be doubled
# for Python syntax, for use in "", for substitution into ORIG_PS1, and
# once more because backslashes in PS1 have to be escaped as well!
rel_pwd = rel_pwd.replace("\\", "\\\\\\\\\\\\\\\\")
for c in "`$\"":
    rel_pwd = rel_pwd.replace(c, "\\\\\\" + c)

print "local NORMALIZED_PWD=\"%s\"" % (
    unicodedata.normalize("NFC", rel_pwd.decode("UTF-8")).encode("UTF-8"))')"

    local PWD_URL="file://$HOSTNAME$URLQUOTED_PWD"
    printf '\e]7;%s\a' "$PWD_URL"
    PS1="${ORIG_PS1/\\w/$NORMALIZED_PWD}"

    PREV_PWD="${PWD}"
}

function check_exit_status ()
{
    local status="$?"
    local signal=""

    if [ ${status} -ne 0 -a ${status} != 128 ]; then
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

trap 'history -a' DEBUG

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

JAVA_HOME="$(/usr/libexec/java_home -Fv 1.8 2>/dev/null)"

if [ -n "${JAVA_HOME}" ]; then
    export JAVA_HOME
fi

add_to_path PATH \
    ~/work/bin \
    ~/chef-bundle/bin \
    ~/bin \
    ~/Library/Python/2.7/bin \
    ~/.gem/ruby/2.2.0/bin \
    ~/.gem/ruby/2.0.0/bin \
    ~/.local/bin \
    ~/node_modules/.bin \
    "${JAVA_HOME}/bin" \
    /opt/texlive2013/bin/x86_64-darwin \
    /opt/homebrew/bin \
    /opt/homebrew/sbin \
    /opt/vagrant/bin \
    /opt/packer \
    /opt/go/bin \
    /usr/libexec \
    /opt/homebrew/Cellar/ruby*/*/bin \
    ;

# Homebrew defaults to deleting all info pages
# https://github.com/mxcl/homebrew/commit/557f500d11f2
export HOMEBREW_KEEP_INFO=1

add_to_path INFOPATH \
    /opt/homebrew/share/info \
    ;

MANPATH="$(manpath 2>/dev/null)"
add_to_path MANPATH \
    /usr/llvm-gcc-*/share/man \
    /usr/local/MacGPG2/share/man \
    ~/Library/Python/*/lib/python/site-packages/*.egg/share/man \
    /opt/homebrew/lib/node_modules/*/man \
    /opt/homebrew/lib/erlang/man \
    /Library/Frameworks/R.framework/Resources \
    /usr/local/lib/node_modules/*/man \
    /usr/local/MacGPG2/share/man \
    ;

alias cd=cd_func

## Aliases

alias erase=rm
alias cp='cp -i'
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
export GIT_PAGER="less -R"
export LESS='-iM -z-3'
if less --help |grep -q -- --mouse-support; then
    export LESS="${LESS} --mouse-support"
fi
export PERLDOC_PAGER="less -fr"
export RI="--format bs"
export RUBYLIB=~/.ruby
export BUNDLE_JOBS="$(python2.7 -c 'import multiprocessing; \
    print multiprocessing.cpu_count()')"
# Pseudo word wrap instead of truncation.
# https://github.com/erikhuda/thor/commit/1f91d12fce7
export THOR_COLUMNS=100000
export PERL_MM_USE_DEFAULT=1
export PYTHONSTARTUP=~/.pyrc
export PYTHONPATH=~/.python
export GOROOT=/opt/go
export GOPATH=~/.go

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
shopt -u extglob
# Stop expansions like ~/.* from including ~/..
export GLOBIGNORE="*/.:*/.."
# Only use built-in filename completion
complete -r

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

PS1="\u@\h:\w\\\$ "
TERM_EXTRA="\e]2;\D{%a %b %e %k:%M:%S}\a"
case "${TERM}" in
   xterm-256color)
     PS1="\[\e[38;5;18m\]${PS1}\[\e[0m${TERM_EXTRA}\]" ;;
   xterm*)
     PS1="\[\e[34m\]${PS1}\[\e[0m${TERM_EXTRA}\]" ;;
   *) ;;
esac
ORIG_PS1="${PS1}"

# History settings
HISTFILE=~/.bash_history
HISTSIZE=500000
HISTFILESIZE=${HISTSIZE}
HISTCONTROL=ignorespace:ignoredups
# This is only used by the output of the history builtin
HISTTIMEFORMAT="%a %Y-%m-%d %H:%M:%S "
shopt -s histappend
# I type exclamation marks in strings more often than I use the ! history
# command, so place the history command on something unlikely to be typed.
histchars=$'\177^#'
export -n HISTFILE HISTSIZE HISTFILESIZE HISTIGNORE HISTTIMEFORMAT

# Needs to be last command in file
#
# DO NOT ADD ANYTHING AFTER THIS
set -o history
