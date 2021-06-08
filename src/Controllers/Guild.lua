local _G = _G;
local PDKP = _G.PDKP

local Guild, GUI, Util, Member, Dev = PDKP:GetInst('Guild', 'GUI', 'Util', 'Member', 'Dev')

local IsInGuild, GetNumGuildMembers, GuildRoster, GuildRosterSetOfficerNote, GetGuildInfo = IsInGuild, GetNumGuildMembers, GuildRoster, GuildRosterSetOfficerNote, GetGuildInfo -- Global Guild Functions
local strsplit, tonumber, tostring, pairs, type, next = strsplit, tonumber, tostring, pairs, type, next -- Global lua functions.
local insert, sort, tContains = table.insert, table.sort, tContains

Guild.initiated = false
Guild.sortDir, Guild.sortBy = nil, nil

function Guild:HasMembers()
    return Guild:GetNumMembers() > 0
end

function Guild:GetNumMembers()
    local total_members, online_members, online_and_mobile = GetNumGuildMembers(true)
    return total_members, online_members, online_and_mobile
end

function Guild:New()
    if IsInGuild() == false or Guild.initiated then return end

    Guild.bankIndex = nil -- TODO: Should be checking the PDKP setting of BankName.
    Guild.officers = {}
    Guild.classLeaders = {}
    Guild.online = {}
    Guild.members = {}
    Guild.memberNames = {}
    Guild.numOfMembers, Guild.numOnlineMembers = 0, 0

    Guild:GetMembers()

    Guild.initiated = true;
end

function Guild:IsNewMemberObject(name)
    return not tContains(Guild.memberNames, name)
end

function Guild:GetMembers()

    Dev:Print('Running Guild:GetMembers()')

    GuildRoster()
    Guild.classLeaders, Guild.officers = {}, {};
    Guild.online = {};
    Guild.numOfMembers, Guild.numOnlineMembers, _ = GetNumGuildMembers();

    --if Guild.numOfMembers > 0 then Guild:UpdateNumOfMembers(Guild.numOfMembers) else Guild.numOfMembers = GuildDB.numOfMembers; end
    for i=1, Guild.numOfMembers do
        local member = Member:new(i)
        local isNew = Guild:IsNewMemberObject(member['name'])

        if member:IsRaidReady() then
            if member.name == nil then member.name = '' end
            if member.isBank then Guild:initBankInfo(i, member) end
            if member.isOfficer then Guild.officers[member.name] = member end
            if member.isClassLeader then Guild.classLeaders[member.name] = member end

            if isNew then
                Guild.members[member.name] = member;
                Guild.memberNames[#Guild.memberNames + 1] = member.name
            end

            if member.online then Guild.online[member.name] = member end
        end
    end

    return Guild.online, Guild.members; -- Always return, even if it's empty.
end

function Guild:GetMemberByName(name)
    if tContains(Guild.memberNames, name) then return Guild.members[name]
    else return nil
    end
end

function Guild:initBankInfo(index, member)
    Guild.bankIndex = index
    Guild.bank = member;
    --Guild:GetSyncStatus()
end