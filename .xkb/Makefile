SHELL=/bin/bash -eu
.DELETE_ON_ERROR:

xkbmap.xkm: neitsch.xkbsym

install: xkbmap.xkm
	setxkbmap
	xkbcomp "${<}" "${DISPLAY}"

%.xkbsym: %.klc
	klc2xkb --compose=XCompose.dead_keys "${<}" > "${@}"
%.xkm: %.xkb symbols
	xkbcomp -I. ${XKBCOMPFLAGS} "${<}" -o "${@}"
symbols:
	ln -s . $@

clean:
	rm -f *.xkbsym *.xkm XCompose.dead_keys symbols

install-system:
	sudo cp ca_andrew /usr/share/X11/xkb/symbols/
