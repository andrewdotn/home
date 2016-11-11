SHELL=/bin/bash -eu

install:
	bundle install --local --without=rake
	for COMPONENT in lib data; do \
	    for F in $$(bundle show --paths); do \
		if [ -d "$${F}/$${COMPONENT}" ]; then \
		    rsync -a "$${F}/$${COMPONENT}/" $${COMPONENT}/; \
		fi; \
	    done; \
	done
	for F in $$(bundle show --paths); do \
	    if [ -d "$${F}/bin" ]; then \
		rsync -a "$${F}/bin/" gembin/; \
	    fi; \
	done
	mkdir -p bin
	for F in gembin/*; do \
	    if [ "$${F#gembin/chef}" != "$${F}" ] \
		|| [ "$${F#gembin/knife}" != "$${F}" ]; \
	    then \
		G="bin/$${F#gembin/}"; \
		echo '#!/bin/bash' > "$${G}"; \
		echo 'GEM_HOME= GEM_PATH= RUBYLIB="$(PWD)/lib" \' >> "$${G}"; \
		echo '    exec ruby $(PWD)/'"$$F"' "$${@}"' >> "$${G}"; \
		chmod +x "$${G}"; \
	    fi; \
	done

clean:
	rm -rf lib
	rm -rf data
	rm -rf bin
	rm -rf gembin
