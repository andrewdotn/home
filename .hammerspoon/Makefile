all:
	luarocks install --local luaunit # luacheck
	lua rewindow/test_init.lua
	~/.luarocks/bin/luacheck .
