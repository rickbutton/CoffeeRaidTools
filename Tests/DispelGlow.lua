---@class Private
local Private = select(2, ...)

local Tests, Asserts = Private.Tests:CreateSuite("DispelGlow")
local IsTrue, IsFalse, Replace = Asserts.IsTrue, Asserts.IsFalse, Asserts.Replace

local DG = Private.DispelGlow

-- ---------------------------------------------------------------------------
-- ShouldGlow tests
-- ---------------------------------------------------------------------------

function Tests:ShouldGlowDisabled()
    Private.db.dispelGlowEnabled = "disabled"
    DG.SetIsHealer(true)
    DG.SetEncounter(nil, nil)
    IsFalse(DG.ShouldGlow())
end

function Tests:ShouldGlowHealerModeWhenHealer()
    Private.db.dispelGlowEnabled = "healer"
    Private.db.dispelGlowBossOverrides = {}
    DG.SetIsHealer(true)
    DG.SetEncounter(nil, nil)
    IsTrue(DG.ShouldGlow())
end

function Tests:ShouldGlowHealerModeWhenNotHealer()
    Private.db.dispelGlowEnabled = "healer"
    DG.SetIsHealer(false)
    DG.SetEncounter(nil, nil)
    IsFalse(DG.ShouldGlow())
end

function Tests:ShouldGlowAlwaysMode()
    Private.db.dispelGlowEnabled = "always"
    DG.SetIsHealer(false)
    DG.SetEncounter(nil, nil)
    IsTrue(DG.ShouldGlow())
end

function Tests:ShouldGlowBossOverrideDisabled()
    Private.db.dispelGlowEnabled = "always"
    Private.db.dispelGlowBossOverrides = {
        [1234] = { name = "TestBoss", enabled = false },
    }
    DG.SetIsHealer(true)
    DG.SetEncounter(1234, "TestBoss")
    IsFalse(DG.ShouldGlow())
end

function Tests:ShouldGlowBossOverrideEnabled()
    Private.db.dispelGlowEnabled = "always"
    Private.db.dispelGlowBossOverrides = {
        [1234] = { name = "TestBoss", enabled = true },
    }
    DG.SetIsHealer(false)
    DG.SetEncounter(1234, "TestBoss")
    IsTrue(DG.ShouldGlow())
end

function Tests:ShouldGlowBossNoOverrideInheritsGlobal()
    Private.db.dispelGlowEnabled = "always"
    Private.db.dispelGlowBossOverrides = {}
    DG.SetIsHealer(false)
    DG.SetEncounter(9999, "UnknownBoss")
    IsTrue(DG.ShouldGlow())
end
