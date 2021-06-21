local _, PDKP = ...

local LOG = PDKP.LOG
local MODULES = PDKP.MODULES
local GUI = PDKP.GUI
local GUtils = PDKP.GUtils
local Utils = PDKP.Utils

local unpack, CreateFrame, UIParent, UISpecialFrames = unpack, CreateFrame, UIParent, UISpecialFrames
local tinsert = table.insert

local AuctionGUI = {}
AuctionGUI.itemLink = nil;

function AuctionGUI:Initialize()
    local title_str = Utils:FormatTextColor('PDKP Active Bids', MODULES.Constants.ADDON_HEX)

    local f = CreateFrame("Frame", "pdkp_auction_frame", UIParent, MODULES.Media.BackdropTemplate)
    f:SetFrameStrata('DIALOG')
    f:SetWidth(256)
    f:SetHeight(256)
    f:SetPoint("BOTTOMRIGHT", pdkp_frame, "BOTTOMLEFT", 0, 0)
    GUtils:setMovable(f)
    f:SetClampedToScreen(true);

    -- TODO: Get Rid of this, and hook it up properly.
    local DevDKP = 30

    local stopBid, bid_box;

    f:SetScript("OnShow", function()
        -- TODO: Set up this to grab their DKP total.
        f.dkp_title:SetText('Total DKP: ' .. 30)

        -- TODO: Possible that I don't need the IsAuctionInProgress part...
        if PDKP.canEdit and MODULES.AuctionManager:IsAuctionInProgress() then
            stopBid:SetEnabled(true)
            stopBid:Show()
        end
    end)

    local sourceWidth, sourceHeight = 256, 512
    local startX, startY, width, height = 0, 0, 216, 277

    local texCoords = {
        startX / sourceWidth,
        (startX + width) / sourceWidth,
        startY / sourceHeight,
        (startY+height) / sourceHeight
    }

    local tex = f:CreateTexture(nil, 'BACKGROUND')
    tex:SetTexture(MODULES.Media.BID_FRAME)

    tex:SetTexCoord(unpack(texCoords))
    tex:SetAllPoints(f)

    local title = f:CreateFontString(f, 'OVERLAY', 'GameFontNormal')
    title:SetText(title_str)
    title:SetPoint("CENTER", f, "TOP", 25, -22)

    local dkp_title = f:CreateFontString(f, 'OVERLAY', 'GameFontNormal')
    dkp_title:SetPoint("TOP", title, "BOTTOM", -5, -25)

    local bid_counter_frame = CreateFrame('Frame', nil, f)
    local bid_tex = bid_counter_frame:CreateTexture(nil, 'BACKGROUND')
    bid_counter_frame:SetPoint('TOPLEFT', f, 'TOPLEFT', 5, 0)
    bid_counter_frame:SetSize(78, 64)

    --- Old
    local bid_counter = bid_counter_frame:CreateFontString(bid_counter_frame, 'OVERLAY', 'BossEmoteNormalHuge')
    bid_counter:SetText("0")
    bid_counter:SetPoint("CENTER", bid_counter_frame, "CENTER")
    bid_counter:SetPoint("TOP", bid_counter_frame, "CENTER", 0, 10)

    local close_btn = GUtils:createCloseButton(f, true)
    close_btn:SetSize(24, 22)
    close_btn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -10)

    local sb = CreateFrame("Button", "$parent_submit", f, "UIPanelButtonTemplate")
    sb:SetSize(80, 22) -- width, height
    sb:SetText("Submit Bid")
    sb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
    sb:SetScript("OnClick", function()
        local bid_amt = f.bid_box.getValue()
        f.current_bid:SetText(bid_amt)

        --TODO: Submit this to the Bid Manager/Comms
    end)
    sb:SetEnabled(false)

    local cb = CreateFrame("Button", "$parent_submit", f, "UIPanelButtonTemplate")
    cb:SetSize(80, 22) -- width, height
    cb:SetText("Cancel Bid")
    cb:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 28, 10)
    cb:Hide()
    cb:SetEnabled(false)
    cb:SetScript("OnClick", function()
        -- TODO: Setup Cancel logic
        f.current_bid:SetText("")
        f.cancel_btn:SetEnabled(false)
        f.cancel_btn:Hide()
    end)
    cb:SetScript("OnShow", function()
        if f.current_bid.getValue() > 0 then
            f.submit_btn:SetText("Update Bid")
        else
            f.submit_btn:SetText("Submit Bid")
        end
    end)
    cb:SetScript("OnHide", function()
        f.submit_btn:SetText("Submit Bid")
    end)

    stopBid = CreateFrame("Button", "$parent_stop_btn", f, "UIPanelButtonTemplate")
    stopBid:SetSize(80, 22) -- width, height
    stopBid:SetText("Manually End Current Auction")
    stopBid:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, -22)
    stopBid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 0)
    stopBid:SetScript("OnClick", function()
        -- TODO: Submit this to the AuctionManager Comms
    end)
    stopBid:SetEnabled(false)
    stopBid:Hide()

    local item_icon = f:CreateTexture(nil, 'OVERLAY')
    item_icon:SetSize(46, 35)
    item_icon:SetPoint("LEFT", f, "LEFT", 32, 21)

    local item_link = GUtils:createItemLink(f)
    item_link:SetPoint("LEFT", item_icon, "RIGHT", 5, 0)
    item_link:SetWidth(150)
    item_link.icon = item_icon

    -- TODO: Cleanup this dev stuff.
    --local ateish = 22589
    --local kingsfall = 22802
    --local blade = 17780
    --local edge = 14551
    --local test_item_id = kingsfall

    local bid_box_opts = {
        ['name'] = 'bid_input',
        ['parent'] = f,
        ['title'] = 'Bid Amount',
        ['multi_line'] = false,
        ['hide'] = false,
        ['max_chars'] = 5,
        ['textValidFunc'] = function(box)
            if box == nil then box = bid_box end

            local box_val = box.getValue()
            local curr_bid_val = f.current_bid.getValue()
            if box_val and box_val <= DevDKP and box_val > 0 and box_val ~= curr_bid_val then
                return sb:SetEnabled(true)
            end
            return sb:SetEnabled(false)
        end,
        ['numeric'] = true,
        ['small_title'] = false,
    }
    bid_box = GUtils:createEditBox(bid_box_opts)
    bid_box:SetWidth(80)
    bid_box:SetPoint("LEFT", f, "LEFT", 45, -35)
    bid_box:SetFrameLevel(f:GetFrameLevel() + 5)
    bid_box.frame:SetFrameLevel(bid_box:GetFrameLevel() - 2)
    bid_box:SetScript("OnTextSet", function()
        local val = bid_box.getValue()
        f.submit_btn.isEnabled = val > 0
        f.submit_btn:SetEnabled(f.submit_btn.isEnabled)
    end)

    local current_bid_opts = {
        ['name'] = 'display_bid',
        ['parent'] = f,
        ['title'] = 'Pending Bid',
        ['multi_line'] = false,
        ['max_chars'] = 5,
        ['textValidFunc'] = nil,
        ['numeric'] = true,
        ['small_title'] = false,
    }
    local current_bid = GUtils:createEditBox(current_bid_opts)
    current_bid:SetWidth(80)
    current_bid:SetPoint("LEFT", bid_box, "RIGHT", 15, 0)
    current_bid.frame:SetFrameLevel(current_bid:GetFrameLevel() - 2)
    current_bid:SetEnabled(false)
    current_bid.frame:SetBackdrop(nil)
    current_bid:SetScript("OnTextSet", function()
        local val = current_bid.getValue()
        f.cancel_btn.isEnabled = val > 0
        f.cancel_btn:SetEnabled(f.cancel_btn.isEnabled)
        f.bid_box:SetText(0)

        if f.cancel_btn.isEnabled then
            f.cancel_btn:Show()
        else
            f.cancel_btn:Hide()
        end
    end)

    local bids_open_btn = CreateFrame("Button", nil, f)
    bids_open_btn:SetSize(45, 25);
    bids_open_btn:SetNormalTexture(MODULES.Media.ARROW_RIGHT_TEXTURE)
    bids_open_btn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -45)


    bids_open_btn:SetScript("OnClick", function()
        if AuctionGUI.current_bidders_frame:IsVisible() then
            AuctionGUI.current_bidders_frame:Hide()
            bids_open_btn:SetNormalTexture(MODULES.Media.ARROW_RIGHT_TEXTURE)
        else
            AuctionGUI.current_bidders_frame:Show()
            bids_open_btn:SetNormalTexture(MODULES.Media.ARROW_LEFT_TEXTURE)
        end
    end)

    tinsert(UISpecialFrames, f:GetName())

    f.current_bid = current_bid
    f.bid_box = bid_box
    f.item_link = item_link
    f.submit_btn = sb
    f.cancel_btn = cb
    f.bid_counter = bid_counter
    f.dkp_title = dkp_title

    AuctionGUI.frame = f

    self:CreateBiddersWindow()

    f:Hide()
end

function AuctionGUI:CreateBiddersWindow()
    local f = GUtils:createBackdropFrame('pdkp_bidders_frame', self.frame, 'Bidders')
    f:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 0, -30)
    f:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMRIGHT", 0, 0)
    f:SetSize(200, 150)

    f.border:SetBackdropColor(unpack({ 0, 0, 0, 0.85 }))

    local scroll = PDKP.SimpleScrollFrame:new(f.content)
    local scrollFrame = scroll.scrollFrame
    local scrollContent = scrollFrame.content;

    f.scrollContent = scrollContent;
    f.scrollContent:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT");
    f.scroll = scroll;
    f.scrollFrame = scrollFrame;

    --local shroud_events = {'CHAT_MSG_RAID', 'CHAT_MSG_RAID_LEADER'}
    --for _, eventName in pairs(shroud_events) do f:RegisterEvent(eventName) end
    --f:SetScript("OnEvent", PDKP_Shroud_OnEvent)

    f:Hide()

    self.current_bidders_frame = f;
end

--- Bid info:
---
---Name, Bid Amount, Total DKP
function AuctionGUI:CreateNewBidder(bid_info)
    local bidders_frame = self.current_bidders_frame;
    local scrollContent = bidders_frame.scrollContent;

    scrollContent:WipeChildren() -- Wipe previous shrouding children frames.

    table.insert(MODULES.AuctionManager.CURRENT_BIDDERS, bid_info)

    local bidders = MODULES.AuctionManager.CURRENT_BIDDERS
    local padding = 95

    local createProspectFrame = function()
        local f = CreateFrame("Frame", nil, scrollContent, nil)
        f:SetSize(scrollContent:GetWidth(), 18)
        f.name = f:CreateFontString(f, "OVERLAY", "GameFontHighlightLeft")
        f.total = f:CreateFontString(f, 'OVERLAY', 'GameFontNormalRight')
        f.name:SetHeight(18)
        f.total:SetHeight(18)
        f.name:SetPoint("LEFT")
        f.total:SetPoint("RIGHT")
        return f
    end

    for i=1, #bidders do
        local prospect_frame = createProspectFrame()
        local prospect_info = bidders[i]

        prospect_frame.name:SetText(prospect_info['name'])
        prospect_frame.total:SetText(prospect_info['dkpTotal'])

        local name_width = prospect_frame.name:GetStringWidth()
        local total_width = prospect_frame.total:GetStringWidth()

        --if bidders_frame.scrollContent:GetWidth() < (name_width + total_width + padding) then
        --    bidders_frame:SetWidth(name_width + total_width + padding)
        --end

        scrollContent:AddChild(prospect_frame)
    end
end

function AuctionGUI:StartAuction(itemName, itemLink)
    self.frame.item_link.SetItemLink(itemName)
    self.frame:Show()

    local bidders = {
        { ['name'] = 'Pamplemousse', ['bid'] = 16, ['dkpTotal'] = 3000, },
        { ['name'] = 'Neekio', ['bid'] = 17, ['dkpTotal'] = 30, },
        { ['name'] = 'Veltrix', ['bid'] = 12, ['dkpTotal'] = 30, },
        { ['name'] = 'Nightshelf', ['bid'] = 05, ['dkpTotal'] = 30, },
        { ['name'] = 'Advanty', ['bid'] = 01, ['dkpTotal'] = 30, },
        { ['name'] = 'Athico', ['bid'] = 14, ['dkpTotal'] = 30, },
    }

    for i=1, #bidders do
        self:CreateNewBidder(bidders[i])
    end

end



GUI.AuctionGUI = AuctionGUI