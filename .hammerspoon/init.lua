
local m = hs.menubar.new(true)
m:setTitle('foo')

local log = hs.logger.new("foo", "debug")
log.i('hello world')
local a = hs.screen.allScreens()
for i, s in pairs(a) do
    log.i(s:name())
    for k, v in pairs(s:currentMode()) do
        log.f("%s: %s", k, v)
    end
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
    local l = hs.window.allWindows()
    for i, w in ipairs(l) do
        log.i(w)
    end
end)


-- local wf = hs.window.filter.new(true)
-- wf:setCurrentSpace(nil)
-- log.i(wf)
-- local l = wf:getWindows()
-- -- log.i(l)
-- 
-- for i, w in ipairs(l) do
--    log.i(w)
-- end
-- 
