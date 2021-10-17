.DELETE_ON_ERROR:
.SECONDARY:
.SUFFIXES:

LANGUAGE = en
REGIONS  = AU CA GB NZ US

${LANGUAGE}.utf-8.spl: ${REGIONS:%=${LANGUAGE}_%.dic} ${REGIONS:%=${LANGUAGE}_%.aff}
	vim -e \
	    --cmd 'set encoding=utf-8' \
	    --cmd 'mkspell! ${LANGUAGE} ${REGIONS:%=${LANGUAGE}_%}' \
	    --cmd q

${LANGUAGE}_%.aff ${LANGUAGE}_%.dic: ${LANGUAGE}_%.zip ${LANGUAGE}_%.diff fixup.py
	unzip -o ${LANGUAGE}_${*}.zip
	patch -p0 < ${LANGUAGE}_${*}.diff
	python fixup.py "${LANGUAGE}_${*}.dic" "${LANGUAGE}_${*}.aff"

${LANGUAGE}_%.zip:
	curl -LO http://ftp.services.openoffice.org/pub/OpenOffice.org/contrib/dictionaries/${LANGUAGE}_${*}.zip

${LANGUAGE}_%.diff:
	curl -LO https://vim.svn.sourceforge.net/svnroot/vim/trunk/runtime/spell/${LANGUAGE}/${LANGUAGE}_${*}.diff
	# The patches include word counts from the third-party
	# dictionaries, which are ignored and easily get out of sync.
	vim -T dumb -e \
	    -c '%s/^\(---.*\.dic.*\n\)\*\{15\}\n\*\*\* 1,2 \(.*\n\)\{6\}/\1/g' \
	    "${@}" -c wq ||:

clean:
	rm -f *${LANGUAGE}_*.{dic,aff} ${LANGUAGE}.utf-8.{spl,sug}
realclean: clean
	rm -f *${LANGUAGE}_* dictionary.lst
