PLUGIN_NAME=nx
TESTS_INIT=minimal_init.lua

.PHONY: nvim test watch

nvim:
	@nvim --noplugin -u ${TESTS_INIT}

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory . { minimal_init = '${TESTS_INIT}' }"

watch:
	@echo -e '\nRunning tests on "$(PLUGIN_NAME)/**/*_spec.lua" when any .lua file on "../lua/" and "$(PLUGIN_NAME)/" changes\n'
	@find $(PLUGIN_NAME) ../lua/ -name '*.lua' \
	  | entr make test
