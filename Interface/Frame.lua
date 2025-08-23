---@class Private
local Private = select(2, ...)

local AceGUI = LibStub("AceGUI-3.0")

local function DestroyFrame(w)
    AceGUI:Release(w)
    Private.frame = nil
end

---@type TabDescription?
local currentTab = nil

local function CreateFrame()
    ---@type AceGUIFrame
    local frame = AceGUI:Create("Frame")
    frame:SetLayout("Fill")
    frame:SetTitle("Coffee Raid Tools")
    frame:SetStatusText("v@project-version@")
    frame:SetCallback("OnClose", DestroyFrame)
    frame:EnableResize(false)

    ---@type AceGUITabGroup
    local tabGroup = AceGUI:Create("TabGroup")

    local tabs = {}
    for i, desc in Private:IterateTabDescriptions() do
        tinsert(tabs, { text = desc.title, value = desc.key })
    end
    tabGroup:SetTabs(tabs)

    local function SelectGroup(container, event, group)
        if currentTab then
            if currentTab.release ~= nil then
                currentTab.release(container)
            end
            container:ReleaseChildren()
        end

        currentTab = Private:GetTabDescription(group)
        if currentTab then
            currentTab.draw(container)
        end
    end

    frame:AddChild(tabGroup)
    tabGroup:SetCallback("OnGroupSelected", SelectGroup)
    tabGroup:SelectTab(tabs[1] and tabs[1].value or "")

    return frame
end

function CoffeeRaidTools:OpenFrame()
    if Private.frame == nil then
        Private.frame = CreateFrame()
    end
end

function CoffeeRaidTools:CloseFrame()
    if Private.frame ~= nil then
        Private.frame:Hide()
    end
end

function CoffeeRaidTools:ToggleFrame()
    if Private.frame == nil then
        CoffeeRaidTools:OpenFrame()
    else
        CoffeeRaidTools:CloseFrame()
    end
end
