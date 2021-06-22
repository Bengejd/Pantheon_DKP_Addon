local _, PDKP = ...

local LOG = PDKP.LOG
local MODULES = PDKP.MODULES
local GUI = PDKP.GUI
local GUtils = PDKP.GUtils;
local Utils = PDKP.Utils;

local Adjust = {}
Adjust.entry = {}

function Adjust:Update(adjustments)
    if tonumber(adjustments['amount']) == nil then return end

    local temp_entry = {
        ['reason'] = adjustments['reason'],
        ['dkp_change'] = adjustments['amount'],
        ['names'] = PDKP.memberTable:GetSelected(),
        ['officer'] = PDKP.char.name,
    }

    if adjustments['raid_boss'] then
        temp_entry['boss'] = adjustments['raid_boss']
        temp_entry['raid'] = MODULES.Constants.BOSS_TO_RAID[temp_entry['boss']]
    end

    if adjustments['item'] then
        temp_entry['item'] = adjustments['item']
    end

    if adjustments['other'] then
        temp_entry['other_text'] = adjustments['other']
    end

    self.entry = MODULES.DKPEntry:new(temp_entry)

    return GUI.Adjustment:UpdatePreview()
end

function Adjust:_HasCore(entry)

end

function Adjust:_IsEntryValid()

end

MODULES.Adjustment = Adjust