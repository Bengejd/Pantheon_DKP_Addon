local _G = _G;
local PDKP = _G.PDKP
local Util, Defaults, Dev = PDKP:GetInst('Util', 'Defaults', 'Dev')

local strsplit, strlower, strmatch, strfind, strupper = strsplit, strlower, strmatch, strfind, strupper;
local replace, format, tostring, gsub, split, trim = string.rep, string.format, tostring, string.gsub, strsplit, strtrim
local floor, fmod = math.floor, math.fmod;
local insert, sort, next = table.insert, table.sort, next;
local date, type, print = date, type, print
local getn, pairs, ipairs = table.getn, pairs, ipairs

local daysInWeek = 7
local daysInYear = 365
local secondsInHour = 60 * 60

Util.warning = Defaults.warning
Util.info = Defaults.info
Util.success = Defaults.success

-----------------------------
--     Debug Functions     --
-----------------------------

local watchedVars = {};

function Util:WatchVar(tData, strName)
    if ViragDevTool_AddData and Dev:IsDev() and not watchedVars[strName] then
        ViragDevTool_AddData(tData, strName)
        watchedVars[strName]=true
    end
end

-----------------------------
--     Color Functions     --
-----------------------------

function Util:FormatTextColor(text, color_hex)
    if text == nil then return text end
    if not color_hex then
        PDKP:Print("No Default Color given")
        color_hex = 'ff0000' end
    return "|cff" .. color_hex .. text .. "|r"
end

function Util:FormatFontTextColor(color_hex, text)
    PDKP:Print('FormatFontTextColor() is depreciated, please change to FormatTextColor()')
    return Util:FormatTextColor(text, color_hex)
end

function Util:FormatTextByClass(text, class)
    local class_color = Defaults.class_colors[class]
    local colored_text, colored_class = Util:FormatTextColor(text, class_color), Util:FormatTextColor(class, class_color)
    return colored_text, colored_class
end

function Util:RemoveColorFromText(name)
    local fixedName = name
    for _, val in pairs(Defaults.class_colors) do
        fixedName = fixedName:gsub('|cff' .. val, '')
    end
    local fName = fixedName:sub(1, -3)
    fName = fName:gsub("%s+", "")
    fName = gsub(fName, "%s+", "")
    return fName
end

-----------------------------
--     Time Functions      --
-----------------------------

function Util:Init()

    local server_time = GetServerTime()
    local daily_reset_time = GetQuestResetTime() -- Seconds until daily quests reset.
    local seconds_until_hour = fmod(daily_reset_time, secondsInHour)
    local seconds_until_daily_reset = daily_reset_time - seconds_until_hour
    local hours_until_daily_reset = seconds_until_daily_reset / 60 / 60

    -- Blizzard Format Sunday (1), Monday (2), Tuesday (3), Wednesday (4), Thursday (5), Friday (6), Saturday (7)
    local day = date("*t", server_time)
    local wday = day.wday
    local yday = day.yday

    -- custom date schedule.
    local customWeeklySchedule = {
        [1] = { -- Old Sunday
            ['daysFromReset'] = 2
        },
        [2] = { -- Old Monday
            ['daysFromReset'] = 1
        },
        [3] = { -- Old Tuesday
            ['daysFromReset'] = 0 -- Tuesday can either be 0 or 7 depending on time of day.
        },
        [4] = { -- Old Wednesday
            ['daysFromReset'] = 6
        },
        [5] = { -- Old Thursday
            ['daysFromReset'] = 5
        },
        [6] = { -- Old Friday
            ['daysFromReset'] = 4
        },
        [7] = { -- Old Saturday
            ['daysFromReset'] = 3
        },
    }

    local customDay = customWeeklySchedule[wday]
    local daysUntilReset = customDay['daysFromReset']
    local isResetDay = daysUntilReset == 0
    local serverReset = false

    -- Today is weekly reset day, Daily reset happens at 9:59:59 AM, server time.
    if daysUntilReset == 0 and hours_until_daily_reset >= 10 then
        serverReset = true
        daysUntilReset = 7
    end

    local dayOfReset = yday + daysUntilReset

    if dayOfReset > daysInYear then
        dayOfReset = dayOfReset - daysInYear
    end

    isResetDay = isResetDay or yday == dayOfReset

    --Dev:Print("IsResetDay:", isResetDay, "ServerReset:" , serverReset, "DayOfReset:" , dayOfReset, "DaysUntilReset:" , daysUntilReset)

    -- Set our globals
    Util.isResetDay = isResetDay
    Util.serverReset = serverReset
    Util.dayOfReset = dayOfReset
    Util.daysUntilReset = daysUntilReset
    Util.wday = wday
    Util.yday = yday
end

-- Subtracts two timestamps from one another.
function Util:SubtractTime(baseTime, subTime)
    local secondsSinceSync = (subTime - baseTime) -- the seconds since our last sync
    local minsSinceFirstReset = floor(secondsSinceSync / 60) -- Minutes since last sync.
    return minsSinceFirstReset
end

function Util:AddTime(base, seconds)
    return base + seconds
end

function Util:SecondsToDays(days)
    local secondsInDay = 86400
    return secondsInDay * days
end

-- Utility function that provides all date & time variations that LUA & WoW have.
function Util:GetDateTimes()
    local dDate = date("%m/%d/%y"); -- LUA implementation of date.
    local tTime = date('%r'); -- LUA implementation of time.
    local server_time = GetServerTime() -- WoW API of the server time.
    local datetime = time() -- LUA implementation of local machine time.
    return lDate, lTime, server_time, datetime
end

function Util:GetFormattedServerTime(serverTime, formatType)
    serverTime = serverTime or GetServerTime()

    if formatType == 'day' then
        return date("*t", serverTime)
    end
end

function Util:FormatDateTime(formatType)
    formatType = formatType or ''; -- Default value.
    if formatType == 'twelve' then
        return date("%a, %b %d | %I:%M %p", dateTime); -- Thur, Jan 4 - 12:32 PM
    elseif formatType == 'weekday' then
        return date("%a", dateTime)
    elseif formatType == 'date' then
        return date('%m/%d/%Y', dateTime); -- 06/21/2020
    else
        return date("%m/%d/%y %H:%M:%S", dateTime); -- 06/21/20 07:30:21
    end
end

-- Calculates the difference in timestamps, and returns it to you in minutes and seconds.
function Util:CalculateTimeDifference(startTime, endTime)
    local difference = endTime - startTime -- in seconds
    local mins = floor(difference / 60) -- mins
    local seconds = difference - (mins * 60) -- seconds
    return mins .. ':'..seconds
end

-- Displays timestamps in D:H:M format.
function Util:displayTime(timeInSeconds)
    local days = floor(timeInSeconds/86400)
    local hours = floor(fmod(timeInSeconds, 86400)/3600)
    local minutes = floor(fmod(timeInSeconds,3600)/60)
    local seconds = floor(fmod(timeInSeconds,60))
    return format("%dD:%2dHr:%2dMin",days,hours,minutes)
end

function Util:Format12HrDateTime(dateTime)
    return date("%a, %b %d | %I:%M %p", dateTime)
end

-----------------------------
--     String Functions    --
-----------------------------

function Util:GetMyName()
    local pName, _ = UnitName("PLAYER")
    return pName
end

-- Utility function to help determine if the string is empty or nil.
function Util:IsEmpty(string)
    return string == nil or string == '';
end

-- Utility function that removes the server name from a characters string.
function Util:RemoveServerName(name)
    if Util:IsEmpty(name) then return nil end;
    -- Names come in with server attached e.g: XYZ-Blaumeux (We gotta remove the server name)
    local newName, _ = strsplit('-', name)
    return newName
end

-- Utility function to help tell if the baseString contains the searchString
function Util:StringsMatch(baseString, searchString)
    return not Util:IsEmpty(strmatch(strlower(baseString), strlower(searchString), nil, true));
end

-- Utility function to help determine if a string matches another in order
function Util:StringsMatchInOrder(baseString, searchString)
    local first, last = strfind(strlower(baseString), strlower(searchString), nil, true);
    return first == 1;
end

-- Utility function to make the first character uppercase, and the rest of the string lowercase.
function Util:Capitalize(str)
    return strlower(str):gsub("^%l", strupper)
end

-- Utility function to remove non-numerics (except minus) from a number.
function Util:RemoveNonNumerics(str)
    return str:gsub("%D+", "")
end

function Util:SplitString(string, delim)
    local arr = {split(delim, string)}

    for i=1, #arr do
        local v = arr[i]
        arr[i] = trim(v, " \t\r") -- Trims  spaces, tabs or newlines from the left or right of the string.
    end

    return arr
end

function Util:RemoveColorFromname(name)
    local fixedName = name
    for _, val in pairs(class_colors) do
        fixedName = fixedName:gsub('|cff' .. val, '')
    end
    local fName = fixedName:sub(1, -3)
    fName = fName:gsub("%s+", "")
    fName = string.gsub(fName, "%s+", "")

    return fName
end

-----------------------------
--     Global Functions    --
-----------------------------

function dumpTable(tbl, indent, depth, currentDepth)
    indent = indent or 0;
    depth = depth or 1
    currentDepth = currentDepth or 0;

    local toprint = string.rep(" ", indent) .. "\r\n"
    indent = indent + 2
    if type(tbl) == 'table' then
        for key, value in pairs(tbl) do
            value = value or 'nil'
            toprint = toprint .. string.rep(" ", indent)
            if type(value) == 'table' then
                currentDepth = currentDepth + 1
                toprint = toprint .. format("[%s] => table \n", tostring(key))
                if currentDepth < depth then
                    toprint = toprint .. dumpTable(value, indent, depth, currentDepth)
                end
            else
                toprint = toprint .. format("[%s] => %s \n", tostring(key), tostring(value))
            end
        end
    else
        print(tbl .. "\n")
    end
    return toprint
end

function tremoveByKey(tab, val)
    for i, v in ipairs (tab) do
        if type(v) == type({}) then
            if (v.id == val) then
                tab[i] = nil
            end
        elseif v == val then
            tab[i] = nil
        end
    end
end

-- Custom function for finding table index.
function tfind(t, item, objIndex)
    objIndex = objIndex or nil;
    t = t or {};
    local index = 1;
    while t[index] do
        if objIndex and (item == t[index]['dataObj'][objIndex]) then
            return true, index
        elseif (item == t[index]) then
            return true, index
        end
        index = index + 1;
    end
    return nil, nil;
end

function tfindObj(t, item, objIndex)
    t = t or {};
    local index = 1;
    while t[index] do
        if (item == t[index][objIndex]) then
            return true, index
        end
        index = index + 1
    end
    return nil, nil
end

-- OrderedNext helper function
function __genOrderedIndex( t )

    local orderedIndex = {}
    for key, _ in pairs(t) do
        if type(key) == type(1) then
            insert( orderedIndex, key )
        else
        end
    end
    sort( orderedIndex )
    return orderedIndex
end

-- OrderedPairs helper function
function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

-- Equivalent of the pairs() function on tables. But this allows you to iterate in order.
function orderedPairs(t)
    return orderedNext, t, nil
end

function tEmpty(t)
    if type(t) ~= type({}) then return true end
    return next(t) == nil;
end

function tenaryAssign(cond, T, F)
    if cond then return T else return F end
end

local waitTable = {};
local waitFrame = nil;
function PDKP__wait(delay, func, ...)
    if(type(delay)~="number" or type(func)~="function") then
        return false;
    end
    if(waitFrame == nil) then
        waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
        waitFrame:SetScript("onUpdate",function (self,elapse)
            local count = #waitTable;
            local i = 1;
            while(i<=count) do
                local waitRecord = tremove(waitTable,i);
                local d = tremove(waitRecord,1);
                local f = tremove(waitRecord,1);
                local p = tremove(waitRecord,1);
                if(d>elapse) then
                    tinsert(waitTable,i,{d-elapse,f,p});
                    i = i + 1;
                else
                    count = count - 1;
                    f(unpack(p));
                end
            end
        end);
    end
    tinsert(waitTable,{delay,func,{...}});
    return true;
end
