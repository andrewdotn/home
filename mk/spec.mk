SHELL = /bin/bash -eu
.DELETE_ON_ERROR:

LAST_md = $(shell lastfile *.md)
MAKEFILE_DIR = $(dir $(lastword $(MAKEFILE_LIST)))

ifeq ($(.DEFAULT_GOAL),)
    .DEFAULT_GOAL := $(LAST_md:%.md=%.html)
endif

%.html: %.md ${MAKEFILE_DIR}/spec_header.html ${MAKEFILE_DIR}/spec_footer.html
	(sed 's/@title@/$*/' < ${MAKEFILE_DIR}/spec_header.html \
	    && github-markup $< && cat ${MAKEFILE_DIR}/spec_footer.html) > $@ \
	    && (reload-tab $@ ||:)
