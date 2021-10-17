require "luarocks.loader"

luaunit = require("luaunit")

function add(v1, v2)
    if v1 < 0 or v2 < 0 then
        error('can only add positive or null numbers, received '..v1..' and '..v2)
    end
    return v1+v2
end

os.exit(luaunit.LuaUnit.run())
