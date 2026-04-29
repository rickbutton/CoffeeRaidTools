---@meta

-- LuaLS definitions for busted globals and the Replace/Restore mocking helpers
-- exposed by spec/helpers/mocks.lua. Loaded by LuaLS only — never executed.

---@param name string
---@param body fun()
function describe(name, body) end

---@param name string
---@param body fun()
function it(name, body) end

---@param name string
---@param body fun()
function pending(name, body) end

---@param body fun()
function before_each(body) end

---@param body fun()
function after_each(body) end

---@param body fun()
function setup(body) end

---@param body fun()
function teardown(body) end

---@param body fun()
function lazy_setup(body) end

---@param body fun()
function lazy_teardown(body) end

---@param body fun()
function finally(body) end

---@param body fun()
function insulate(body) end

---@param body fun()
function expose(body) end

-- Busted's assert library replaces Lua's assert. Typed as `any` so that the
-- chained-style assertions (assert.are.equal, assert.is_true, ...) all
-- type-check without listing every method individually.
---@diagnostic disable-next-line: lowercase-global
---@type any
assert = nil

-- Replace / Restore globals exposed by spec/helpers/mocks.lua.
--
-- Replace has two call shapes:
--   Replace(name, value)              -- replaces _G[name]
--   Replace(target, key, replacement) -- replaces target[key]

---@overload fun(name: string, value: any)
---@overload fun(target: table, key: any, replacement: any)
function Replace(...) end

function Restore() end
