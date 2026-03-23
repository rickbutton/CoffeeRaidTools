---@diagnostic disable: undefined-global

---@class Private
local Private = select(2, ...)

local CATALYST_WARNING_TEXT = "Do not use any catalyst charges until told to do so by an officer!"
local GREAT_VAULT_WARNING_TEXT = "Do not select your Great Vault reward until told to do so by an officer!"

local function CreateWarningPanel(parent, warningText)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOP", parent, "BOTTOM", 0, -6)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("|cffff4040" .. warningText .. "|r")
    text:SetJustifyH("CENTER")

    frame:SetWidth(math.max(parent:GetWidth(), text:GetStringWidth() + 32))
    frame:SetHeight(text:GetStringHeight() + 24)

    frame:Hide()
    return frame
end

-- Catalyst warning (ItemInteractionFrame, ItemConversion only)

local catalystWarning

local function EvaluateCatalystWarning()
    if not catalystWarning then
        return
    end

    catalystWarning:Hide()

    if not ItemInteractionFrame:IsShown() then
        return
    end

    if ItemInteractionFrame:GetInteractionType() ~= Enum.UIItemInteractionType.ItemConversion then
        return
    end

    catalystWarning:Show()
end

local function SetupCatalystHooks()
    catalystWarning = CreateWarningPanel(ItemInteractionFrame, CATALYST_WARNING_TEXT)

    hooksecurefunc(ItemInteractionFrame, "Show", function()
        C_Timer.After(0, EvaluateCatalystWarning)
    end)

    hooksecurefunc(ItemInteractionFrame, "Hide", function()
        if catalystWarning then
            catalystWarning:Hide()
        end
    end)
end

if Private.catalystWarningEnabled then
    if ItemInteractionFrame then
        SetupCatalystHooks()
    else
        local loader = CreateFrame("Frame")
        loader:RegisterEvent("ADDON_LOADED")
        loader:SetScript("OnEvent", function(self, _, addon)
            if addon ~= "Blizzard_ItemInteractionUI" then
                return
            end
            self:UnregisterAllEvents()
            SetupCatalystHooks()
        end)
    end
end

-- Great Vault warning (WeeklyRewardsFrame, always)

local vaultWarning

local function SetupVaultHooks()
    vaultWarning = CreateWarningPanel(WeeklyRewardsFrame, GREAT_VAULT_WARNING_TEXT)

    hooksecurefunc(WeeklyRewardsFrame, "Show", function()
        C_Timer.After(0, function()
            if not vaultWarning then
                return
            end
            if WeeklyRewardsFrame:IsShown() then
                vaultWarning:Show()
            end
        end)
    end)

    hooksecurefunc(WeeklyRewardsFrame, "Hide", function()
        if vaultWarning then
            vaultWarning:Hide()
        end
    end)
end

if Private.greatVaultWarningEnabled then
    if WeeklyRewardsFrame then
        SetupVaultHooks()
    else
        local loader = CreateFrame("Frame")
        loader:RegisterEvent("ADDON_LOADED")
        loader:SetScript("OnEvent", function(self, _, addon)
            if addon ~= "Blizzard_WeeklyRewards" then
                return
            end
            self:UnregisterAllEvents()
            SetupVaultHooks()
        end)
    end
end
