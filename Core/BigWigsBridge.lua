---@class Private
local Private = select(2, ...)

local function SetupBigWigsMessages()
    Private:DebugPrint("BigWigsBridge: registering on BigWigs message bus")
    local bwCallbackTarget = {}
    local forwardMessages = {
        "BigWigs_CoreEnabled",
        "BigWigs_ProfileUpdate",
        "BigWigs_StartPull",
        "BigWigs_StartBreak",
        "BigWigs_StopBreak",
    }
    for _, bwEvent in ipairs(forwardMessages) do
        BigWigsLoader.RegisterMessage(bwCallbackTarget, bwEvent, function(_, ...)
            local crtEvent = "CRT_" .. bwEvent
            Private:DebugPrint("BigWigsBridge: forwarding", bwEvent, "->", crtEvent)
            Private:SendMessage(crtEvent, ...)
        end)
    end
end

if BigWigsLoader then
    SetupBigWigsMessages()
else
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, addonName)
        if addonName == "BigWigs" then
            self:UnregisterEvent("ADDON_LOADED")
            SetupBigWigsMessages()
        end
    end)
end
