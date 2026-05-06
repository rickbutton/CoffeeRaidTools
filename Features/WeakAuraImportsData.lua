---@class Private
local Private = select(2, ...)

---@class WeakAuraImportEntry
---@field name string
---@field description? string
---@field importString string

---@class WeakAuraImportBossSection
---@field boss string
---@field auras WeakAuraImportEntry[]

-- Boss names must match the `boss` field used in PrivateAuraSoundsData.lua so
-- the entries line up with the encounter pages in the Settings tab.
---@type WeakAuraImportBossSection[]
Private.WeakAuraImportSections = {
    {
        boss = "Lightblinded Vanguard",
        auras = {
            {
                name = "Paladins Heal Absorb",
                description = "Shows the Avenger's Shield heal absorb on raidframes.",
                importString = "",
            },
            {
                name = "Paladins Dispel Assign",
                description = "Assigns Avenger's Shield dispels across healers, warlocks and dwarfs.",
                importString = "",
            },
        },
    },
    {
        boss = "Crown of the Cosmos",
        auras = {
            {
                name = "Alleria P1 Damage Amp",
                description = "Shows stacks of the damage amp debuff on the nameplates of the three big adds.",
                importString = "",
            },
        },
    },
}
