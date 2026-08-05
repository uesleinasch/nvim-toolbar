.PHONY: test test-mouse fmt

test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/spec { minimal_init = 'tests/minimal_init.lua' }"

test-mouse:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/mouse { minimal_init = 'tests/minimal_init.lua', timeout = 60000 }"

fmt:
	stylua lua tests demo
