local _, core = ...;
local _G = _G;
local L = core.L;

local DKP = core.DKP;
local GUI = core.GUI;
local Item = core.Item;
local Util = core.Util;
local PDKP = core.PDKP;
local Guild = core.Guild;
local Shroud = core.Shroud;
local Defaults = core.defaults;
local Import = core.import;


local englishFaction, _ = UnitFactionGroup("PLAYER");

PDKP.data = {}
PDKP.raidData = {}
core.initialized = false
core.sortBy = nil
core.sortDir = nil
core.filterOffline = nil
core.pdkp_frame = nil;
core.canEdit = false;

core.GUI = {
    shown = false;
    sortBy = nil;
    sortDir = 'ASC';
    pdkp_frame = nil;
    lastEntryClicked = nil;
    sliderVal = 1;
    hasTimer = false;
}

core.defaults = {
    -- ADDON INFO
    addon_version = 'V0.8.9',
    addon_name = 'PantheonDKP',
    debug = false,
    no_broadcast = true,
    debug_dkp = false;

    -- PLAYER INFO
    playerUID = UnitGUID("PLAYER"), -- Unique Blizzard Player ID
    isInGuild = IsInGuild(), -- Boolean
    faction = englishFaction, -- Alliance or Horde

    -- VIEW TABLE INFO
    displayTable = { -- Data that is currently being displayed to the user.
        data = {}, -- name, class, dkp
        activeFilters = {},
        sortDir = 'ASC',
        sortBy = 'name',
    },


    -- UTILTIY INFO
    classes = { -- Utility table of the available classes for that player's faction.
        'Druid', 'Hunter', 'Mage', 'Paladin', 'Priest', 'Rogue', 'Warlock', 'Warrior', },
    class_colors = { -- Utility table of the available class colors for that player's faction.
        ["Druid"] = { r = 1, g = 0.49, b = 0.04, hex = "FF7D0A" },
        ["Hunter"] = {r = 0.67, g = 0.83, b = 0.45, hex = "ABD473" },
        ["Mage"] = { r = 0.25, g = 0.78, b = 0.92, hex = "40C7EB" },
        ["Paladin"] = { r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
        ["Priest"] = { r = 1, g = 1, b = 1, hex = "FFFFFF" },
        ["Rogue"] = { r = 1, g = 0.96, b = 0.41, hex = "FFF569" },
        ["Warlock"] = { r = 0.53, g = 0.53, b = 0.93, hex = "8787ED" },
        ["Warrior"] = { r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E" }
    }
}

core.raids = {
    'Onyxia\'s Lair',
    'Molten Core',
    'Blackwing Lair',
}

core.raidBosses = {
    ["Onyxia's Lair"] = {
        'Onyxia'
    },
    ["Molten Core"] = {
        "Lucifron",
        'Magmadar',
        'Gehennas',
        'Garr',
        'Shazzrah',
        'Baron Geddon',
        'Sulfuron Harbinger',
        'Golemagg the Incinerator',
        'Majordomo Executus',
        'Ragnaros',
    },
    ["Blackwing Lair"] = {
        "Razorgore the Untamed",
        "Vaelastrasz the Corrupt",
        "Broodlord Lashlayer",
        "Firemaw",
        "Ebonroc",
        "Flamegor",
        "Chromaggus",
        "Nefarian",
    }
}

core.bossIDS = {
    ["Onyxia's Lair"] = {
        [1084] = "Onyxia"
    },
    ["Molten Core"] = {
        [663] = "Lucifron",
        [664] = 'Magmadar',
        [665] = 'Gehennas',
        [666] = 'Garr',
        [667] = 'Shazzrah',
        [668] = 'Baron Geddon',
        [669] = 'Sulfuron Harbinger',
        [670] = 'Golemagg the Incinerator',
        [671] = 'Majordomo Executus',
        [672] = 'Ragnaros',
    },
    ["Blackwing Lair"] = {
        [610] = "Razorgore the Untamed",
        [611] = "Vaelastrasz the Corrupt",
        [612] = "Broodlord Lashlayer",
        [613] = "Firemaw",
        [614] = "Ebonroc",
        [615] = "Flamegor",
        [616] =  "Chromaggus",
        [617] = "Nefarian",
    },
}
