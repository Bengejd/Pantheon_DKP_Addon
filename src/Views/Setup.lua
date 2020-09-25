local _, core = ...;
local _G = _G;
local L = core.L;

local DKP = core.DKP;
local GUI = core.GUI;
local Item = core.Item;
local PDKP = core.PDKP;
local Raid = core.Raid;
local Util = core.Util;
local Comms = core.Comms;
local Setup = core.Setup;
local Guild = core.Guild;
local Shroud = core.Shroud;
local Member = core.Member;
local Import = core.Import;
local Officer = core.Officer;
local Invites = core.Invites;
local Minimap = core.Minimap;
local Defaults = core.Defaults;
local ScrollTable = core.ScrollTable;
local Settings = core.Settings;

local AceGUI = LibStub("AceGUI-3.0")
local pdkp_frame = nil
local PlaySound = PlaySound

local CLOSE_BUTTON_TEXT = "|TInterface\\Buttons\\UI-StopButton:0|t"
local TRANSPARENT_BACKGROUND = "Interface\\TutorialFrame\\TutorialFrameBackground"
local PDKP_TEXTURE_BASE = "Interface\\Addons\\PantheonDKP\\Media\\Main_UI\\PDKPFrame-"
local SHROUD_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"
local HIGHLIGHT_TEXTURE = 'Interface\\QuestFrame\\UI-QuestTitleHighlight'
local SCROLL_BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local ARROW_TEXTURE = 'Interface\\MONEYFRAME\\Arrow-Left-Up'
local ROW_SEPARATOR = 'Interface\\Artifacts\\_Artifacts-DependencyBar-BG'

local filterButtons = {};

local pi = math.pi

--------------------------
-- Local      Functions --
--------------------------

local function setMovable(f)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag('LeftButton')
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
end

local function createCloseButton(f, mini)
    local template = mini and 'pdkp_miniButton' or 'UIPanelButtonTemplate'
    local b = CreateFrame("Button", '$parentCloseButton',  f, template)
    b:SetText(CLOSE_BUTTON_TEXT)
    b:SetParent(f)
    b:SetScript("OnClick", function(self) self:GetParent():Hide() end)
    return b
end

local function createCheckButton(parent, point, x, y, displayText, uniqueName, center, frame)
    uniqueName = uniqueName or nil;
    center = center or false;
    frame = frame or nil;
    local cb = CreateFrame("CheckButton", 'pdkp_filter_' ..uniqueName, parent, "ChatConfigCheckButtonTemplate")
    _G[cb:GetName() .. 'Text']:SetText(displayText)

    if center and frame then
        local cbtw = _G[cb:GetName() .. 'Text']:GetWidth();
        cb:SetPoint('TOPRIGHT', frame, 'CENTER', x - cbtw *0.25, y);
    else
        cb:SetPoint(point, x, y);
    end


    cb.filterOn = uniqueName;
    return cb;
end

--- Opts:
---     name (string): Name of the dropdown (lowercase)
---     parent (Frame): Parent frame of the dropdown.
---     items (Table): String table of the dropdown options.
---     defaultVal (String): String value for the dropdown to default to (empty otherwise).
---     hide (Boolean): A boolean value for whether the dropdown should start hidden.
---     dropdownTable (table): A table of dropdowns for this to be inserted into.
---     showOnValue (string): A custom value for when the table should be shown.
---     changeFunc (Function): A custom function to be called, after selecting a dropdown option.
---     showFunc (Function): A custom function to be called, when the dropdown shows.
---     hideFunc (Function): A custom function to be called, when the dropdown hides.
local function createDropdown(opts)
    local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
    local menu_items = opts['items'] or {}
    local title_text = opts['title'] or ''
    local default_val = opts['defaultVal'] or ''
    local hide = opts['hide'] or false
    local showFunc = opts['showFunc'] or function() end
    local hideFunc = opts['hideFunc'] or function() end
    local change_func = opts['changeFunc'] or function (dropdown_val) end


    local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'], 'UIDropDownMenuTemplate')
    local dd_title = dropdown:CreateFontString(dropdown, 'OVERLAY', 'GameFontNormal')
    dd_title:SetPoint("TOPLEFT", 20, 10)

    dropdown.uniqueID = opts['name']
    dropdown.showOnValue = opts['showOnValue'] or 'Always'
    local dropdown_width = 0;
    dropdown.initialized = false

    for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
        dd_title:SetText(item)
        local text_width = dd_title:GetStringWidth() + 20
        if text_width > dropdown_width then
            dropdown_width = text_width
        end
    end

    dropdown:SetScript("OnShow", showFunc)
    dropdown:SetScript("OnHide", hideFunc)

    dropdown.isValid = function()
        if dropdown:IsVisible() then
            local box_text = UIDropDownMenu_GetSelectedValue(dropdown)
            if box_text and box_text ~= "" and box_text ~= 0 then
                return true
            else
                return false
            end
        else
            return true
        end
    end

    if hide then dropdown:Hide() end

    UIDropDownMenu_SetWidth(dropdown, dropdown_width)
    UIDropDownMenu_SetText(dropdown, default_val)
    dd_title:SetText(title_text)

    UIDropDownMenu_Initialize(dropdown, function(self, level, _)
        local info = UIDropDownMenu_CreateInfo()

        for key, val in pairs(menu_items) do
            info.text = val;
            info.checked = false
            info.menuList= key
            info.hasArrow = false
            info.func = function(b)
                UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
                UIDropDownMenu_SetText(dropdown, b.value)
                b.checked = true
                change_func(dropdown, b.value)
            end
            UIDropDownMenu_AddButton(info)
        end

        if not dropdown.initialized and default_val and default_val ~= '' then
            dropdown.initialized = true;
            UIDropDownMenu_SetSelectedValue(dropdown, default_val, default_val)
        end
    end)

    if opts['dropdownTable'] then opts['dropdownTable'][opts['name']]=dropdown end

    return dropdown
end

local function createEditBox(opts)
    local name = opts['name'] or 'edit_box'
    local parent = opts['parent'] or pdkp_frame
    local box_label_text = opts['title'] or ''
    local multi_line = opts['multi']
    local max_chars = opts['max_chars'] or 225
    local textValidFunc = opts['textValidFunc'] or function() end
    local numeric = opts['numeric'] or false

    local box = CreateFrame("EditBox", "$parent_" .. name, parent)
    box:SetHeight(30)
    box:SetWidth(150)
    box:SetFrameStrata("DIALOG")
    box:SetMaxLetters(max_chars)
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetMultiLine(multi_line)
    box:SetNumeric(numeric)

    box.isValid = function()
        if box:IsVisible() then
            local box_text = box:GetText()
            if box_text and box_text ~= "" and box_text ~= 0 then
                return true
            else
                return false
            end
        else
            return true
        end
    end

    box:SetScript("OnEscapePressed", function() box:ClearFocus() end)
    box:SetScript("OnTextChanged", function()
        if box.isValid() then textValidFunc(box) end
    end)

    local box_frame = CreateFrame("Frame", '$parent_edit_frame', box)
    box_frame:SetBackdrop( {
        bgFile = TRANSPARENT_BACKGROUND,
        edgeFile = SHROUD_BORDER, tile = true, tileSize = 17, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    });
    box_frame:SetWidth(170)

    if multi_line then
        box_frame:SetPoint("TOPLEFT", box, "TOPLEFT", -10, 10)
        box_frame:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 10, -15)
        box_frame:SetHeight(50)
    else
        box_frame:SetPoint("TOPLEFT", box, "TOPLEFT", -10, 0)
        box_frame:SetHeight(30)
    end

    box_frame:SetFrameLevel(box:GetFrameLevel() - 4)

    -- label
    local el = box:CreateFontString(box_frame, "OVERLAY", 'GameFontNormal')
    el:SetText(box_label_text)
    el:SetPoint("TOPLEFT", box_frame, "TOPLEFT", 5, 10)

    GUI.editBoxes[name]=box

    box.frame = box_frame
    box.title = el
    return box
end

--------------------------
-- Setup      Functions --
--------------------------

function Setup:MainUI()
    local f = CreateFrame("Frame", "pdkp_frame", UIParent)
    f:SetFrameStrata("HIGH");
    f:SetClampedToScreen(true);

    f:SetWidth(742) -- Set these to whatever height/width is needed
    f:SetHeight(682) -- for your Texture

    local function createTextures(tex)
        local x = tex['x'] or 0
        local y = tex['y'] or 0

        local t = f:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(PDKP_TEXTURE_BASE .. tex['file'])
        t:SetPoint(tex['dir'], f, x, y)
        f.texture = t
    end

    local textures = {
        { ['dir'] = 'BOTTOMLEFT', ['file'] = 'BotLeft.tga', },
        { ['dir'] = 'BOTTOM', ['file'] = 'BotMid.tga', ['y']=1.5},
        { ['dir'] = 'BOTTOMRIGHT', ['file'] = 'BotRight.tga', },
        { ['dir'] = 'CENTER', ['file'] = 'Middle.tga', },
        { ['dir'] = 'LEFT', ['file'] = 'MidLeft.tga', ['y']=-42},
        { ['dir'] = 'RIGHT', ['file'] = 'MidRight.tga', ['x']=2.35},
        { ['dir'] = 'TOPLEFT', ['file'] = 'TopLeft.tga', ['x']=-8},
        { ['dir'] = 'TOP', ['file'] = 'Top.blp', },
        { ['dir'] = 'TOPRIGHT', ['file'] = 'TopRight.blp', },
    }

    for _, t in pairs(textures) do createTextures(t) end

    f:SetPoint("TOP",0,0)
    f:Show()

    setMovable(f)

    -- Close button

    local b = createCloseButton(f, false)
    b:SetSize(22, 25) -- width, height
    b:SetPoint("TOPRIGHT", -2, -10)

    pdkp_frame = f

    Setup:RandomStuff()

    return pdkp_frame
end

function Setup:Debugging()
    local f = CreateFrame("Frame", "pdkp_debug_frame", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetPoint("BOTTOMLEFT")
    f:SetHeight(500)
    f:SetWidth(200)

    f:SetBackdrop( {
        bgFile = TRANSPARENT_BACKGROUND,
        edgeFile = SHROUD_BORDER, tile = true, tileSize = 64, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    });

    setMovable(f)

    -- mini close button
    local b = createCloseButton(f, true)
    b:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -6, -6)

    -- title
    local t = f:CreateFontString(f, 'OVERLAY', 'GameFontNormal')
    t:SetPoint("TOPLEFT", 5, -10)
    t:SetPoint("TOPRIGHT", -10, -30)
    t:SetText("PDKP Debugging")
    t:SetParent(f)

    local buttons = {
        ['reload']=function()
            ReloadUI()
        end,
        ['show']=function()
            GUI:Show()
        end,
        ['hide']=function()
            GUI:Hide()
        end,
        ['debug']=function()
            Settings:ToggleDebugging()
        end,
        ['shroud']=function()
            DKP:TestShroud()
        end,
        ['roll']=function()
            DKP:TestShroud()
        end,
        ['reset DKP']=function()
            DKP:ResetDKP()
        end,
        ['compressString']=function()
            local testTime = 1600749114
            local encoded_time, compressed_time, serialized_time = Comms:DataEncoder(testTime)
            print(testTime)
            print(encoded_time)
            print(compressed_time)
            print(serialized_time)
        end
    }
    local button_counter_x = 1
    local button_counter_y = 1
    local button_counter = 1
    for name, func in pairs(buttons) do
        local db = CreateFrame("Button", nil, f, "UiPanelButtonTemplate")
        db:SetSize(80, 22)
        db:SetText(name)

        db:SetScript("OnClick", func)

        pos_x = 10
        pos_y = -25

        pos_y = pos_y * button_counter

        db:SetPoint("TOPLEFT", f, "TOPLEFT", pos_x, pos_y)

        button_counter = button_counter + 1
    end
end

function Setup:RandomStuff()
    --Setup:ShroudingBox()
    Setup:Debugging()

    Setup:ScrollTable()
    Setup:Filters()
    Setup:DKPAdjustments()
    Setup:RaidDropdown()
    --Setup:BossKillLoot()
    --Setup:TabView()


end

function Setup:TableSearch()
    -- edit frame
    local ef = CreateFrame("Frame", "$parent_edit_frame", pdkp_frame)
    ef:SetHeight(25)
    ef:SetWidth(165)
    ef:SetPoint('BOTTOMLEFT', pdkp_frame, "BOTTOMLEFT", 10, 10)

    -- search label
    local sl = ef:CreateFontString(ef, 'OVERLAY', 'GameFontNormalSmall')
    sl:SetText("Search:")
    sl:SetPoint("LEFT", ef, "LEFT", -12, 0)
    sl:SetWidth(80)

    -- edit clear button
    local clearButton = CreateFrame("Button", "$parent_clear_button", ef, "UIPanelButtonTemplate")
    clearButton:SetText("Clear")
    clearButton:SetSize(45, 15)
    clearButton:SetPoint("RIGHT", ef, "RIGHT", -2, 0)

    -- edit box
    local eb = CreateFrame("EditBox", "$parent_editBox", pdkp_frame)
    eb:SetWidth(75)
    eb:SetHeight(50)
    eb:SetPoint("LEFT", ef, "LEFT", 48, 0)
    eb:SetFontObject(GameFontNormalSmall)
    eb:SetFrameStrata("DIALOG")
    eb:SetMaxLetters(11)
    eb:SetAutoFocus(false)

    local function toggleClearButton(text)
        if text == nil or text == "" then
            clearButton:Hide()
        else
            clearButton:Show()
        end
    end

    local function resetSearch()
        eb:ClearFocus()
        toggleClearButton(eb:GetText())
    end

    eb:SetScript("OnEscapePressed", function() resetSearch() end)
    eb:SetScript("OnEnterPressed", function() resetSearch() end)
    eb:SetScript("OnTextChanged", function()
        local text = eb:GetText()
        toggleClearButton(text)
        PDKP.memberTable:SearchChanged(text)
    end)
    eb:SetScript("OnEditFocusLost", function() toggleClearButton(eb:GetText()) end)
    eb:SetScript("OnEditFocusGained", function() toggleClearButton(eb:GetText()) end)

    clearButton:SetScript("OnClick", function()
        eb:SetText("")
        resetSearch()
    end)

    clearButton:Hide()

    ef.editBox = eb
    ef.searchLabel = sl
    ef.clearButton = clearButton

    return ef
end

function Setup:Filters()
    local f = CreateFrame("Frame", "$parentFilterFrame", pdkp_frame)

    f:SetBackdrop({
        tile = true, tileSize = 0,
        edgeFile = SCROLL_BORDER, edgeSize = 8,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetHeight(150)
    f:SetPoint("TOPLEFT", PDKP.memberTable.frame, "TOPRIGHT", -3, 0)
    f:SetPoint("TOPRIGHT", pdkp_frame, "RIGHT", -10,0)

    f:Show()

    local rows = { -- Our filter rows
        { -- Row 1
            { ['point']='TOPLEFT', ['x']=20, ['y']=-20, ['displayText']='Selected', ['filterOn']='selected', },
            { ['point']='TOPLEFT', ['x']=85, ['y']=0, ['displayText']='Online', ['filterOn']='online' },
            { ['point']='TOPLEFT', ['x']=85, ['y']=0, ['displayText']='In Raid', ['filterOn']='raid' },
        },
        { -- Row 2
            { ['point']='TOPLEFT', ['x']=0, ['y']=-30, ['displayText']='Select All', ['filterOn']='Select_All' },
        },
        { -- Row 3
            { ['x']=0, ['y']=0, ['displayText']='All Classes', ['filterOn']='Class_All',
              ['center']=true,
            },
        },
        {}, -- First Class Row
        {}, -- Second Class Row
    }

    for key, class in pairs(Defaults.classes) do
        local classBtn = { ['point']='TOPLEFT', ['x']=60, ['y']=50, ['displayText']=class, ['filterOn']='Class_'..class}

        if key >= 1 and key <= 4 then
            table.insert(rows[4], classBtn);
        else
            table.insert(rows[5], classBtn)
        end
    end

    for rowKey, row in pairs(rows) do
        for fKey, filter in pairs(row) do
            local parent = f -- Default parent.
            table.insert(filterButtons, {});

            if fKey > 1 or rowKey > 1 then
                local pcb = filterButtons[#filterButtons -1];
                local pcbt = _G[pcb:GetName() .. 'Text']
                parent = pcb;
                if #row > 1 then -- To better space out the buttons.
                    filter['x'] = filter['x'] + pcbt:GetWidth();
                end
            end

            local cb = createCheckButton(parent, filter['point'], filter['x'], filter['y'], filter['displayText'],
                    filter['filterOn'], filter['center'], f)

            if rowKey == 4 or rowKey == 5 then
                cb:ClearAllPoints();
                if rowKey == 4 then
                    if fKey == 1 then
                        cb:SetPoint("LEFT", f, "LEFT", 20, -40);
                    else
                        cb:SetPoint("TOPRIGHT", filterButtons[#filterButtons-1], "TOPRIGHT", filter['x'], 0);
                    end
                elseif rowKey == 5 then
                    cb:SetPoint("TOPLEFT", filterButtons[#filterButtons-4], "TOPLEFT", 0, -20);
                end
            end

            if rowKey >= 3 and rowKey <=5 then
                cb:SetChecked(true);
            end

            cb:SetScript("OnClick", function(b)
                local function loop_all_class(setStatus)
                    local all_checked = true;
                    for i=1, #Defaults.classes do
                        local button = _G['pdkp_filter_Class_' .. Defaults.classes[i]];
                        if setStatus ~= nil then
                            button:SetChecked(setStatus);
                        end
                        if not button:GetChecked() then
                            all_checked = false
                        end
                    end
                    return all_checked
                end
                if rowKey == 3 then -- All Classes
                    loop_all_class(b:GetChecked());
                elseif rowKey == 4 or rowKey == 5 then
                    local all_checked = loop_all_class();
                    _G['pdkp_filter_Class_All']:SetChecked(all_checked);
                end

                local st = PDKP.memberTable;
                st:ApplyFilter(b.filterOn, b:GetChecked());
            end)
            filterButtons[#filterButtons] = cb;
        end
    end

    local st = PDKP.memberTable;
    for _, b in pairs(filterButtons) do
        st:ApplyFilter(b.filterOn, b:GetChecked());
    end
end

function Setup:DKPAdjustments()
    local f = CreateFrame("Frame", "$parent_adjustment_frame", pdkp_frame)

    f:SetBackdrop({
        tile = true, tileSize = 0,
        edgeFile = SCROLL_BORDER, edgeSize = 8,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetHeight(250)
    f:SetPoint("BOTTOMLEFT", PDKP.memberTable.frame, "BOTTOMRIGHT", -3, 0)
    f:SetPoint("BOTTOMRIGHT", pdkp_frame, "BOTTOMRIGHT", -10,0)

    local adjustHeader = f:CreateFontString(f, "OVERLAY", 'GameFontNormal')
    adjustHeader:SetText("DKP Adjustments")
    adjustHeader:SetPoint("TOPLEFT", 5, -5)

    local mainDD;
    local boss_dropdowns = {};

    --- Main Dropdown

    local reason_opts = {
        ['name']='reasons',
        ['parent']=f,
        ['title']='Reason',
        ['items']= {'On Time Bonus', 'Completion Bonus', 'Boss Kill', 'Unexcused Absence', 'Item Win', 'Other'},
        ['defaultVal']='',
        ['dropdownTable']=GUI.adjustmentDropdowns,
        ['changeFunc']=PDKP_ToggleAdjustmentDropdown
    }

    mainDD = createDropdown(reason_opts)
    mainDD:SetPoint("TOPLEFT", f, "TOPLEFT", -3, -50)

    --- Bosses section

    for raid, _ in pairs(Defaults.raidBosses) do
        local boss_opts = {
            ['name']='boss_' .. raid,
            ['parent']=mainDD,
            ['title']='Boss',
            ['hide']=true,
            ['dropdownTable']=GUI.adjustmentDropdowns,
            ['showOnValue']=raid,
            ['changeFunc']=PDKP_ToggleAdjustmentDropdown,
            ['items']=Defaults.raidBosses[raid],
        }
        local bossDD = createDropdown(boss_opts)
        bossDD:SetPoint("LEFT", mainDD, "RIGHT", -20, 0)

        table.insert(boss_dropdowns, bossDD)
    end

    --- Amount section
    local amount_opts = {
        ['name']='amount',
        ['parent']=mainDD,
        ['title']='Amount',
        ['multi']=false,
        ['max_chars']=7,
        ['textValidFunc']=function(box)
            print('Box is valid')
            PDKP_ToggleAdjustmentDropdown()
        end
    }
    local amount_box = createEditBox(amount_opts)

    amount_box.frame:SetWidth(75)
    amount_box:SetWidth(60)
    amount_box:SetPoint("TOPLEFT", mainDD, "BOTTOMLEFT", 25, -20)

    --- Other Edit Box Section

    local other_opts = {
        ['name']= 'other',
        ['parent']= mainDD,
        ['title']='Other',
        ['multi']=true,
        ['textValidFunc']=function(box)
            print('Box is valid')
            PDKP_ToggleAdjustmentDropdown()
        end
    }
    local other_box = createEditBox(other_opts)
    other_box:SetPoint("LEFT", mainDD, "RIGHT", 20, 0)
    other_box:Hide()

    --- Submit button
    local sb = CreateFrame("Button", "$parent_submit", f, "UIPanelButtonTemplate")
    sb:SetSize(80, 22) -- width, height
    sb:SetText("Submit")
    sb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 4, -22)
    sb:SetScript("OnClick", function() DKP:Submit() end)
    sb.canSubmit = false
    sb.toggle = function()
        if sb.canSubmit then sb:Enable() else sb:Disable() end
    end
    sb:Disable()

    GUI.submit_entry = sb

    mainDD:Show()

    if not Settings:CanEdit() then f:Hide() end

end

function PDKP_ToggleAdjustmentDropdown()
    if tEmpty(GUI.adjustmentDropdowns) then return end

    local gui_dds = GUI.adjustmentDropdowns;

    wipe(GUI.adjustment_entry) -- Wipe the old entry details.

    local entry_details = GUI.adjustment_entry

    --- Submit Button
    local sb = GUI.submit_entry

    local reasonDD, raidDD, bwlDD, mcDD, aqDD, naxxDD = gui_dds['reasons'], gui_dds['raid'], gui_dds['boss_Blackwing Lair'],
    gui_dds['boss_Molten Core'], gui_dds['boss_Ahn\'Qiraj'], gui_dds['boss_Naxxramas']

    local other_box = GUI.editBoxes['other']
    local amount_box = GUI.editBoxes['amount']

    local reason_val = UIDropDownMenu_GetSelectedValue(reasonDD)
    local raid_val = UIDropDownMenu_GetSelectedValue(raidDD)

    entry_details['raid']=raid_val
    entry_details['reason']=reason_val

    local function toggleFrameVisiblity(frame, show)
        if show then
            frame:Show()
        else
            frame:Hide()
        end
    end

    for _, b_dd in pairs({bwlDD, mcDD, aqDD, naxxDD} ) do
        toggleFrameVisiblity(b_dd, reason_val == 'Boss Kill' and b_dd.uniqueID == 'boss_' .. raid_val)
    end
    toggleFrameVisiblity(other_box, reason_val == 'Other')

    local adjust_amount_setting = Defaults.adjustment_amounts[raid_val][reason_val]
    if adjust_amount_setting ~= nil then amount_box:SetText(adjust_amount_setting) end

    for _, b_dd in pairs({bwlDD, mcDD, aqDD, naxxDD}) do
        if b_dd:IsVisible() then
            GUI.adjustment_entry['boss']=UIDropDownMenu_GetSelectedValue(b_dd)
        end
    end

    local can_submit = true

    local entry_frames = {reasonDD, raidDD, bwlDD, mcDD, aqDD, naxxDD, other_box, amount_box}

    --- Validate every frame.
    for _, frame in pairs(entry_frames) do
        can_submit = can_submit and frame.isValid()
    end

    --- Selection check
    can_submit = can_submit and #PDKP.memberTable.selected > 0

    if reason_val == 'Item Win' then
        can_submit = can_submit and #PDKP.memberTable.selected == 1
    end

    sb.canSubmit = can_submit

    print(can_submit)

    sb.toggle()
end

function Setup:RaidDropdown()

    local parent_frame = _G['pdkp_frameFilterFrame']

    local raid_opts = {
        ['name']='raid',
        ['parent']=parent_frame,
        ['title']='Raid Selection',
        ['items']= Defaults.dkp_raids,
        ['defaultVal']=Settings.current_raid,
        ['dropdownTable']=GUI.adjustmentDropdowns,
        ['changeFunc']=function(dropdown, dropdown_val)
            Settings:ChangeCurrentRaid(dropdown_val);
            PDKP.memberTable:RaidChanged()
            PDKP_ToggleAdjustmentDropdown()
        end
    }
    local raid_dd = createDropdown(raid_opts)
    raid_dd:SetPoint("TOPRIGHT", parent_frame, "TOPRIGHT", 15, 75);
end

function Setup:TabView()

    local tc = CreateFrame("Frame", 'myTabContainerFrame', UIParent, nil)
    tc:SetSize(200, 200);
    tc:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    tc:SetMovable(true)
    tc:EnableMouse(true)
    tc:SetParent(UIParent)

    tc:SetBackdrop({
        tile = true, tileSize = 32,
        edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border', edgeSize = 32,
        bgFile= 'Interface\\DialogFrame\\UI-DialogBox-Background',
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local header = tc:CreateFontString(tc, 'OVERLAY', 'GameFontNormal')
    header:SetSize(356, 64)
    header:SetPoint("TOP", 0, 12)
    header:SetText("My Frame")

    local tab_pages = {}
    local tab_buttons = {}

    local tab_page_opts = {
        [1]={
            ['name']='Filter',
            ['text']='Filter Page',
            ['title']='Filter',
            ['points']={
                ['side']='TOPLEFT',
                ['rel']='TOPLEFT',
            },
        },
        [2]={
            ['name']='History',
            ['text']='History Page',
            ['title']='History',
            ['points']={
                ['side']='TOPRIGHT',
                ['rel']='TOPRIGHT',
            },

        },
    }

    local function createTabButton(opts, page)
        local t = CreateFrame("Button", page:GetName() .. '_Tab', tc, "CharacterFrameTabButtonTemplate")
        t:SetText(opts['text'])
        t:SetSize(t:GetTextWidth() + 30, 30)
        t:SetPoint(opts['points']['side'], "$parent", opts['points']['rel'], 0, 30)
        t:SetFrameLevel(tc:GetFrameLevel() + 4)

        local textures = {'LeftDisabled', 'MiddleDisabled', 'RightDisabled', 'Left', 'Middle', 'Right'}

        local text_down = {'LeftDisabled', 'Left'}
        local text_left = {'MiddleDisabled', 'Middle'}
        local text_up = {'RightDisabled', 'Right'}

        local rotate_270 = (pi / 180) * 270
        local rotate_90 = (pi / 180) * 90
        local rotate_360 = (pi / 180) * 360
        local rotate_180 = (pi / 180) * 180

        for _, tex in pairs(textures) do
            _G[t:GetName() .. tex]:SetRotation(rotate_180)
        end

        --_G[t:GetName() .. 'LeftDisabled']:SetTexCoord(0, 0.15625, 0, 0.546875)
        _G[t:GetName() .. 'Left']:SetTexCoord(0, 0.84375, 1, 0)
        --_G[t:GetName() .. 'MiddleDisabled']:SetTexCoord(0.15625, 0.84375, 0, 0.546875)
        --_G[t:GetName() .. 'Middle']:SetTexCoord(0.15625, 0.84375, 0, 1.0)
        --_G[t:GetName() .. 'RightDisabled']:SetTexCoord(0.84375, 1.0, 0, 0.546875)
        --_G[t:GetName() .. 'Right']:SetTexCoord(0.84375, 1.0, 0, 1.0)

        --local midTex = _G[t:GetName() .. 'Middle']:SetRotation()
        --midTex:SetRotation(rotate_left)

        PanelTemplates_TabResize(t, 0, nil, 36, 60);

        local tab_text = _G[t:GetName() .. 'Text']
        tab_text:SetAllPoints(t)

        return t
    end

    local function rotateTab(tab)
        --rotate_down
    end

    local function toggleTab(t)
        for _, page in pairs(tab_pages) do
            if page.tab:GetName() == t:GetName() then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    local function createTabPage(opts)
        local page = CreateFrame("Frame", '$parent_' .. opts['name'] .. '_Page', tc, nil)
        page:SetPoint("TOPLEFT", tc)
        page:SetPoint("BOTTOMRIGHT", tc)

        local page_text = page:CreateFontString(page, "OVERLAY", 'GameFontNormal')
        page_text:SetText(opts['text'])
        page_text:SetPoint("TOPLEFT", page)
        page_text:SetPoint("BOTTOMRIGHT", page)
        page_text:SetSize(20, 30)

        page.text = page_text

        page.tab = createTabButton(opts, page)

        page.tab:SetScript("OnClick", function()
            toggleTab(page.tab)
        end)

        return page
    end

    for key, page_opts in pairs(tab_page_opts) do
        local page = createTabPage(page_opts)
        table.insert(tab_pages, page)
        if key ~= 1 then page:Hide() end

        local tab = page.tab
        tab:SetScript("OnClick", function()
            toggleTab(tab)
        end)
    end
    tc:Show()
end

function Setup:BossKillLoot()
    local f = CreateFrame("Frame", "$parentBossLoot", pdkp_frame)
    f:SetBackdrop({
        tile = true, tileSize = 0,
        edgeFile = SCROLL_BORDER, edgeSize = 8,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetHeight(225);
    f:SetPoint("BOTTOMLEFT", PDKP.memberTable.frame, "BOTTOMRIGHT", -3, 0)
    f:SetPoint("BOTTOMRIGHT", pdkp_frame, "RIGHT", -10,0)
    f:Show()

    -- mini close button
    local b = createCloseButton(f, true)
    b:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -6, -6)

    -- title
    local t = f:CreateFontString(f, 'OVERLAY', 'GameFontNormal')
    t:SetPoint("TOPLEFT", 5, -10)
    t:SetPoint("TOPRIGHT", -10, -30)
    t:SetText("PDKP Shrouding")
    t:SetParent(f)

    f:Show()
end

function Setup:ShroudingBox()
    local f = CreateFrame("Frame", "pdkp_shroud_frame", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetPoint("BOTTOMLEFT")
    f:SetHeight(200)
    f:SetWidth(200)

    f:SetBackdrop( {
        bgFile = TRANSPARENT_BACKGROUND,
        edgeFile = SHROUD_BORDER, tile = true, tileSize = 64, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    });

    setMovable(f)

    -- mini close button
    local b = createCloseButton(f, true)
    b:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -6, -6)

    -- title
    local t = f:CreateFontString(f, 'OVERLAY', 'GameFontNormal')
    t:SetPoint("TOPLEFT", 5, -10)
    t:SetPoint("TOPRIGHT", -10, -30)
    t:SetText("PDKP Shrouding")
    t:SetParent(f)

    f:Show()
end

function Setup:ScrollTable()
    local st = {};

    local function compare(a,b)
        local sortDir = st.sortDir;
        local sortBy = st.sortBy;
        -- Set the data object explicitly here
        -- Since this is pointing to a row
        -- Not a member object.
        a = a.dataObj;
        b = b.dataObj;

        if sortBy == 'name' then
            a = a['name']
            b = b['name']
        elseif sortBy == 'class' then
            if a['class'] == b['class'] then
                return a['name'] < b['name']
            else
                a = a['class']
                b = b['class']
            end
        elseif sortBy == 'dkp' then
            a = a:GetDKP(nil, 'total')
            b = b:GetDKP(nil, 'total')
        end

        if sortDir == 'ASC' then return a > b else return a < b end
    end

    local table_settings = {
        ['name']= 'ScrollTable',
        ['parent']=pdkp_frame,
        ['height']=500,
        ['width']=330,
        ['movable']=true,
        ['enableMouse']=true,
        ['retrieveDataFunc']=function()
            Guild:GetMembers()
            return Guild.memberNames
        end,
        ['retrieveDisplayDataFunc']=function(self, name)
            return Guild:GetMemberByName(name)
        end,
        ['anchor']={
            ['point']='TOPLEFT',
            ['rel_point_x']=12,
            ['rel_point_y']=-120,
        }
    }
    local col_settings = {
        ['height']=14,
        ['width']=90,
        ['firstSort']=1, -- Denotes the header we want to sort by originally.
        ['headers'] = {
            [1] = {
                ['label']='name',
                ['sortable']=true,
                ['point']='LEFT',
                ['showSortDirection'] = true,
                ['compareFunc']=compare
            },
            [2] = {
                ['label']='class',
                ['sortable']=true,
                ['point']='CENTER',
                ['showSortDirection'] = true,
                ['compareFunc']=compare
            },
            [3] = {
                ['label']='dkp',
                ['sortable']=true,
                ['point']='RIGHT',
                ['showSortDirection'] = true,
                ['compareFunc']=compare,
                ['getValueFunc']= function (member)
                    return member:GetDKP(nil, 'total')
                end,
            },
        }
    }
    local row_settings = {
        ['height']=20,
        ['width']=285,
        ['max_values'] = 425,
        ['indexOn']=col_settings['headers'][1]['label'], -- Helps us keep track of what is selected, if it is filtered.
    }

    st = ScrollTable:newHybrid(table_settings, col_settings, row_settings)
    st.cols[1]:Click()

    PDKP.memberTable = st;
    GUI.memberTable = st;

    st.searchFrame = Setup:TableSearch()

    -- Entries label
    -- 0 Entries shown | 0 selected
    local label = st.searchFrame:CreateFontString(st.searchFrame, 'OVERLAY', 'GameFontNormalLeftYellow')
    label:SetSize(200, 14)
    label:SetPoint("LEFT", st.searchFrame.clearButton, "LEFT", 60, 0)
    label:SetText("0 Players shown | 0 selected")

    st.entryLabel = label

end


