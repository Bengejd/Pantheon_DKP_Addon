local _, core = ...;
local _G = _G;
local L = core.L;

local Shroud = core.Shroud;
local Raid = core.Raid;
local Guild = core.Guild;
local PDKP = core.PDKP;
local Util = core.Util;
local Settings = core.Settings;
local GUI = core.GUI;

local trim, lower = strtrim, strlower

local shroud_commands = {'shroud', 'thirst'}

Shroud.shrouders = {};

function PDKP_Shroud_OnEvent(self, event, arg1, ...)
    if not Raid:InRaid() then return end
    -- If not DKP Officer or Master Looter, ignore event.

    local msg, _, _, _, name, _, _, _, _, _, _, _, _, _, _, _, _ = arg1, ...
    msg = lower(trim(msg))

    if not tContains(shroud_commands, msg) then return end -- Not a shrouding message.

    if not Shroud.shrouders[name] then
        Shroud.shrouders[name .. ' ' .. tostring(random(0, 9999))] = {
            ['Molten Core']=math.floor(random(0, 9999)),
            ['Blackwing Lair']=math.floor(random(0, 9999)),
            ['Ahn\'Qiraj']=math.floor(random(0, 9999)),
        }
    end

    local shroud_box = GUI.shroud_box;
    local scrollContent = shroud_box.scrollContent;

    scrollContent:WipeChildren() -- Wipe previous shrouding children frames.

    local compare = function(a, b) return a[Settings.current_raid] < b[Settings.current_raid] end
    table.sort(Shroud.shrouders, compare)

    --- TODO: Figure out how to do pairs in order instead of randomly. It's fucking up the order of things.

    for name, dkp in pairs(Shroud.shrouders) do
        local shrouder = scrollContent:CreateFontString(scrollContent, 'OVERLAY', 'GameFontHighlightLeft')
        shrouder:SetHeight(18)
        shrouder:SetText(dkp[Settings.current_raid] .. " | " .. name)
        scrollContent:AddChild(shrouder)
    end

    local raid_text = Settings.current_raid .. ' Shrouds'
    GUI.shroud_box.title:SetText(raid_text)



    --Raid.events_frame = CreateFrame("Frame", nil, UIParent)
    --for _, eventName in pairs(raid_events) do Raid.events_frame:RegisterEvent(eventName) end
    --Raid.events_frame:SetScript("OnEvent", PDKP_Raid_OnEvent)
    --
    --function PDKP_Raid_OnEvent(self, event, arg1, ...)
    --
    --    local regular_events = {
    --        ['CHAT_MSG_WHISPER']=function(arg1, ...)
    --            local msg, _, _, _, name, _, _, _, _, _, _, _, _, _, _, _, _ = arg1, ...
    --            msg = lower(msg)
    --            msg = trim(msg)
    --            local invite_cmds = GUI.invite_control['commands']
    --            if contains(invite_cmds, msg) then return Raid:InviteName(name) end
    --        end,
    --    }
    --
    --    if regular_events[event] then return regular_events[event](arg1, ...) end
    --
    --    if not Raid:InRaid() then return Util:Debug("Not In Raid, Ignoring event") end
    --    local raid_size = GetNumGroupMembers()
    --
    --    local raid_group_events = {
    --        ['GROUP_ROSTER_UPDATE']=function()
    --            if not GetRaidRosterInfo(raid_size) then return end
    --            Raid.raid:Init()
    --        end,
    --    }
    --
    --    if raid_group_events[event] then raid_group_events[event]() end
    --
    --end
end

function Shroud:Setup()

end