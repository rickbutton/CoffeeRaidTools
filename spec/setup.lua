-- Busted helper loaded once before any spec files run.
---@diagnostic disable: undefined-global

-- 1. Mock WoW globals.
dofile("spec/helpers/wow_mocks.lua")

-- 2. Load Ace3 libraries and addon source (populates _G.Private).
dofile("spec/helpers/addon_loader.lua")

-- 3. Expose the Replace/Restore mocking helpers as globals.
dofile("spec/helpers/mocks.lua")
