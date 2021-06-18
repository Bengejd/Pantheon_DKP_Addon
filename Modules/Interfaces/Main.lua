local _, PDKP = ...

local LOG = PDKP.LOG
local MODULES = PDKP.MODULES
local GUI = PDKP.GUI
local GUtils = PDKP.GUtils;
local Utils = PDKP.Utils;

local Main = {}

local CreateFrame, strlower, unpack = CreateFrame, strlower, unpack
local tinsert = tinsert
local UIParent, UISpecialFrames = UIParent, UISpecialFrames

function Main:Initialize()
    -- TODO: Find why Main:Initialize() is being called twice...
    if pdkp_frame ~= nil then return end

    local f = CreateFrame("Frame", "pdkp_frame", UIParent)
    f:SetFrameStrata("HIGH");
    f:SetClampedToScreen(true);

    f:SetWidth(742) -- Set these to whatever height/width is needed
    f:SetHeight(632) -- for your Texture

    local function createTextures(tex)
        local x = tex['x'] or 0
        local y = tex['y'] or 0

        local t = f:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(MODULES.Media.PDKP_TEXTURE_BASE .. tex['file'])

        if tex['file'] == 'BG.tga' then
            t:SetDrawLayer("Background", -8)
            t:SetPoint('TOPLEFT', f, 5, -15)
            t:SetPoint('BOTTOMRIGHT', f, -5, 15)
            t:SetAlpha(0.9)
        else
            t:SetPoint(tex['dir'], f, x, y)
        end

        f.texture = t
    end

    local textures = {
        { ['dir'] = 'BOTTOMLEFT', ['file'] = 'BotLeft.tga', },
        { ['dir'] = 'BOTTOM', ['file'] = 'BotMid.tga', ['y'] = 1.5 },
        { ['dir'] = 'BOTTOMRIGHT', ['file'] = 'BotRight.tga', },
        { ['dir'] = 'CENTER', ['file'] = 'Middle.tga', },
        { ['dir'] = 'LEFT', ['file'] = 'MidLeft.tga', ['y'] = -42 },
        { ['dir'] = 'RIGHT', ['file'] = 'MidRight.tga', ['x'] = 2.35 },
        { ['dir'] = 'TOPLEFT', ['file'] = 'TopLeft.tga', ['x'] = -8 },
        { ['dir'] = 'TOP', ['file'] = 'Top.tga', },
        { ['dir'] = 'TOPRIGHT', ['file'] = 'TopRight.tga', },
        { ['dir'] = 'TOPLEFT', ['file'] = 'BG.tga', }
    }

    for _, t in pairs(textures) do createTextures(t) end

    f:SetPoint("TOP", 0, 0)

    GUtils:setMovable(f)

    --- Close button
    local b = GUtils:createCloseButton(f, false)
    b:SetSize(22, 25) -- width, height
    b:SetPoint("TOPRIGHT", -2, -10)

    local addon_title = f:CreateFontString(f, "Overlay", "BossEmoteNormalHuge")
    addon_title:SetText(Utils:FormatTextColor('PantheonDKP', MODULES.Constants.ADDON_HEX))
    addon_title:SetSize(200, 25)
    addon_title:SetPoint("CENTER", f, "TOP", 0, -28)
    addon_title:SetScale(0.9)

    --- Addon Version
    local addon_version = f:CreateFontString(f, "Overlay", "GameFontNormalSmall")
    addon_version:SetSize(50, 14)
    addon_version:SetText(Utils:FormatTextColor(PDKP.CORE.versionString, MODULES.Constants.ADDON_HEX))
    addon_version:SetPoint("RIGHT", b, "LEFT", 0, -3)

    --- Addon Author
    local addon_author = f:CreateFontString(f, "Overlay", "Game11Font")
    addon_author:SetSize(200, 20)
    addon_author:SetText("Author: Neekio-Blaumeux")
    addon_author:SetPoint("TOPLEFT", f, "TOPLEFT", 40, -15)

    f.addon_title = addon_title
    f.addon_version = addon_version

    pdkp_frame = f

    tinsert(UISpecialFrames, f:GetName())

    return pdkp_frame
end

MODULES.Main = Main;