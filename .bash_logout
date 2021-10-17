if type -p sudo >& /dev/null; then
    sudo -K
fi

# Clear the screen if on a physical console
if [ "${TERM%-*}" != "xterm" ] && [[ "$(tty)" =~ /tty[0-9]+$ ]]; then
    clear

    # Clear scrollback by reloading the default font
    setfont
fi
