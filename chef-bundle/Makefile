SHELL=/bin/bash -eu
BUNDLE=ruby20-env bundle

install:
	$(BUNDLE) install --local
	for F in $$($(BUNDLE) show --paths); do \
	    rsync -a "$${F}/lib/" lib/; \
	done
	for F in $$($(BUNDLE) show --paths); do \
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
		echo 'unset BUNDLE_BIN_PATH' >> "$${G}"; \
		echo 'unset BUNDLE_GEMFILE' >> "$${G}"; \
		echo 'unset RUBYOPT' >> "$${G}"; \
		echo 'GEM_HOME= GEM_PATH= RUBYLIB="$(PWD)/lib" \' >> "$${G}"; \
		echo '    exec /usr/bin/ruby $(PWD)/'"$$F"' "$${@}"' >> "$${G}"; \
		chmod +x "$${G}"; \
	    fi; \
	done

clean:
	rm -rf lib
	rm -rf bin
	rm -rf gembin
	rm -f Gemfile.lock
