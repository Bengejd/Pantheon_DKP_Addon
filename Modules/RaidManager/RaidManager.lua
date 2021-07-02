local _, PDKP = ...

local LOG = PDKP.LOG
local MODULES = PDKP.MODULES
local GUI = PDKP.GUI
local GUtils = PDKP.GUtils;
local Utils = PDKP.Utils;

local Raid = {}

local tinsert = tinsert
local PromoteToAssistant, GetRaidRosterInfo, SetLootMethod = PromoteToAssistant, GetRaidRosterInfo, SetLootMethod

local GroupManager, GuildManager;

function Raid:Initialize()
    self.settings_DB = MODULES.Database:Settings()
    local db = self.settings_DB

    GroupManager = MODULES.GroupManager
    GuildManager = MODULES.GuildManager

    self.ignore_from = db['ignore_from']
    self.invite_commands = db['invite_commands']
    self.ignore_pugs = db['ignore_pugs'] or false
    self.invite_spam_text = "[TIME] [RAID] invites going out. Pst for Invite"

    if Utils:tEmpty(self.invite_commands) then
        self.settings_DB['invite_commands'] = {'inv', 'invite'}
    end
end

function Raid:GetClassMemberNames(class)
    local names = {}
    local classNames = MODULES.GroupManager.classes[class]

    if classNames then
        for i=1, #classNames do
            tinsert(names, classNames[i])
        end
    end

    return names
end

function Raid:PromoteLeadership()
    if not GroupManager:IsLeader() then return end
    for i=1, 40 do
        local name, _, _, _, _, _, _, _, _, _, isML, _ = GetRaidRosterInfo(i);
        if name ~= nil then
            local m = GuildManager:GetMemberByName(name)
            if m ~= nil then
                if m.isInLeadership or isML then
                    PromoteToAssistant('raid' .. i)
                end
            end
        end
    end
end

function Raid:SetLootCommon()
    if not GroupManager:IsInRaid() or not GroupManager:IsLeader() then return end
    local ml = GroupManager.leadership.masterLoot or Utils:GetMyName()
    SetLootMethod("Master", ml, '1')
    PDKP.CORE:Print("Loot threshold updated to common")
end

MODULES.RaidManager = Raid