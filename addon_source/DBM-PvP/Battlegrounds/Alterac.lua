-- Alterac mod v3.0
-- rewrite by Nitram and Tandanu

local Alterac    = DBM:NewMod("AlteracValley", "DBM-PvP", 2)
local L            = Alterac:GetLocalizedStrings()

Alterac:SetZone(DBM_DISABLE_ZONE_DETECTION)

Alterac:AddBoolOption("AutoTurnIn")
Alterac:RemoveOption("HealthFrame")

Alterac:RegisterEvents(
    "ZONE_CHANGED_NEW_AREA",     -- Required for BG start
    "CHAT_MSG_MONSTER_YELL",
    "CHAT_MSG_BG_SYSTEM_ALLIANCE",
    "CHAT_MSG_BG_SYSTEM_HORDE",
    "CHAT_MSG_BG_SYSTEM_NEUTRAL",
    "GOSSIP_SHOW",
    "QUEST_PROGRESS",
    "QUEST_COMPLETE"
)

local allyTowerIcon = "Interface\\AddOns\\DBM-PvP\\Textures\\GuardTower"
local allyColor = {
    r = 0,
    g = 0,
    b = 1,
}

local hordeTowerIcon = "Interface\\AddOns\\DBM-PvP\\Textures\\OrcTower"
local hordeColor = {
    r = 1,
    g = 0,
    b = 0,
}

local startTimer = Alterac:NewTimer(62, "TimerStart")
local towerTimer = Alterac:NewTimer(243, "TimerTower")
local gyTimer = Alterac:NewTimer(243, "TimerGY", "Interface\\Icons\\Spell_Shadow_AnimateDead")

-- http://www.wowwiki.com/API_GetMapLandmarkInfo

local graveyards = {}
local function is_graveyard(id)
    return id == 15 or id == 4 or id == 13 or id == 14 or id == 8
end
local function gy_state(id)
    if id == 15 then        return 1    -- if gy_state(id) > 2 then .. conflict state ...
    elseif id == 13 then     return 2
    elseif id == 8 then        return 3    -- if gy_state(id) == 3 then --- untaken
    elseif id == 4 then        return 4    -- if gy_state(id) == 4 then --- alliance takes gy from horde
    elseif id == 14 then    return 5    -- if gy_state(id) == 5 then --- horde takes gy from alliance
    else return 0
    end
end
--[[
    15 Graveyard, held by Alliance
    04 Graveyard, assaulted by Alliance
    13 Graveyard, held by Horde
    14 Graveyard, assaulted by Horde
--]]

towers = {}
local function is_tower(id)
    return id == 10 or id == 12 or id == 11 or id == 9 or id == 6
end
local function tower_state(id)
    if id == 11 then        return 1    -- if tower_state(id) > 2 then .. conflict state ...
    elseif id == 10 then    return 2
    elseif id == 9 then        return 3    -- if tower_state(id) == 3 then --- alliance trys to destroy the tower
    elseif id == 12 then    return 4    -- if tower_state(id) == 4 then --- horde trys to destroy the tower
    elseif id == 6 then        return 5    -- if tower_state(id) == 5 then --- destroyed
    else return 0
    end
end
--[[
    10 Tower, held by Horde
    12 Tower, assaulted by Horde
    11 Tower, held by Alliance
    09 Tower, assaulted by Alliance
--]]

local bgzone = false
do
    local function AV_Initialize()
        if select(2, IsInInstance()) == "pvp" and GetRealZoneText() == L.ZoneName then
            bgzone = true
            for i=1, GetNumMapLandmarks(), 1 do
                local name, _, textureIndex = GetMapLandmarkInfo(i)
                if name and textureIndex then
                    if is_graveyard(textureIndex) then
                        graveyards[i] = textureIndex
                    elseif is_tower(textureIndex) then
                        towers[i] = textureIndex
                    end
                end
            end

        elseif bgzone then
            bgzone = false
        end
    end
    Alterac.OnInitialize = AV_Initialize
    Alterac.ZONE_CHANGED_NEW_AREA = AV_Initialize
end

local schedule_check

function Alterac:CHAT_MSG_BG_SYSTEM_NEUTRAL(arg1)
    if not bgzone then return end
    if arg1 == L.BgStart60 then
        startTimer:Start()
    elseif arg1 == L.BgStart30  then
        startTimer:Update(31, 62)
    end
    schedule_check(self)
end

local function check_for_updates()
    if not bgzone then return end
    for k,v in pairs(graveyards) do
        local name, _, textureIndex = GetMapLandmarkInfo(k)
        if name and textureIndex then
            if gy_state(v) <= 3 and gy_state(textureIndex) > 3 then
                -- gy is now in conflict, we have to start a bar :)
                gyTimer:Start(nil, name)

                if gy_state(textureIndex) == 4 then
                    gyTimer:SetColor(allyColor, name)
                else
                    gyTimer:SetColor(hordeColor, name)
                end

            elseif gy_state(textureIndex) <= 3 then
                -- gy is now longer under conflict, remove the bars
                gyTimer:Stop(name)
            end
            graveyards[k] = textureIndex
        end
    end
    for k,v in pairs(towers) do
        local name, _, textureIndex = GetMapLandmarkInfo(k)
        if name and textureIndex then
            if tower_state(v) <= 2 and tower_state(textureIndex) > 2 then
                -- Tower is now in conflict, we have to start a bar :)
                towerTimer:Start(nil, name)

                if tower_state(textureIndex) == 3 then
                    towerTimer:SetColor(allyColor, name)
                    towerTimer:UpdateIcon(hordeTowerIcon, name)
                else
                    towerTimer:SetColor(hordeColor, name)
                    towerTimer:UpdateIcon(allyTowerIcon, name)
                end

            elseif tower_state(textureIndex) <= 2 then
                -- Tower is now longer under conflict, remove the bars
                towerTimer:Stop(name)
            end
            towers[k] = textureIndex
        end
    end
end

function schedule_check(self)
    self:Schedule(1, check_for_updates)
end


Alterac.CHAT_MSG_MONSTER_YELL = schedule_check
Alterac.CHAT_MSG_BG_SYSTEM_ALLIANCE = schedule_check
Alterac.CHAT_MSG_BG_SYSTEM_HORDE = schedule_check

local quests
do
    local getQuestName
    do
        local tooltip = CreateFrame("GameTooltip", "DBM-PvP_Tooltip")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:AddFontStrings(tooltip:CreateFontString("$parentText", nil, "GameTooltipText"), tooltip:CreateFontString("$parentTextRight", nil, "GameTooltipText"))

        function getQuestName(id)
            tooltip:ClearLines()
            tooltip:SetHyperlink("quest:"..id)
            return getglobal(tooltip:GetName().."Text"):GetText()
        end
    end

    local function loadQuests()
        for i, v in pairs(quests) do
            if type(v[1]) == "table" then
                for i, v in ipairs(v) do
                    v[1] = getQuestName(v[1]) or v[1]
                end
            else
                v[1] = getQuestName(v[1]) or v[1]
            end
        end
    end

    quests = {
        [13442] = {
            {7386, 17423, 5},
            {6881, 17423},
        },
        [13236] = {
            {7385, 17306, 5},
            {6801, 17306},
        },
        [13257] = {6781, 17422, 20},
        [13176] = {6741, 17422, 20},
        [13577] = {7026, 17643},
        [13179] = {6825, 17326},
        [13438] = {6942, 17502},
        [13180] = {6826, 17327},
        [13181] = {6827, 17328},
        [13439] = {6941, 17503},
        [13437] = {6943, 17504},
        [13441] = {7002, 17642},
    }

    loadQuests() -- requests the quest information from the server
    Alterac:Schedule(5, loadQuests) -- information should be available now....load it
    Alterac:Schedule(15, loadQuests) -- sometimes this requires a lot more time, just to be sure!
end

local function isQuestAutoTurnInQuest(name)
    for i, v in pairs(quests) do
        if type(v[1]) == "table" then
            for i, v in ipairs(v) do
                if v[1] == name then return true end
            end
        else
            if v[1] == name then return true end
        end
    end
end

local function acceptQuestByName(name)
    for i = 1, select("#", GetGossipAvailableQuests()), 5 do
        if select(i, GetGossipAvailableQuests()) == name then
            SelectGossipAvailableQuest(math.ceil(i/5))
            break
        end
    end
end

local function checkItems(item, amount)
    local found = 0
    for bag = 0, NUM_BAG_SLOTS do
        for i = 1, GetContainerNumSlots(bag) do
            if tonumber((GetContainerItemLink(bag, i) or ""):match(":(%d+):") or 0) == item then
                found = found + select(2, GetContainerItemInfo(bag, i))
            end
        end
    end
    return found >= amount
end


function Alterac:GOSSIP_SHOW()
    if not bgzone or not self.Options.AutoTurnIn then return end
    local quest = quests[tonumber((UnitGUID("target") or ""):sub(9, 12), 16) or 0]
    if quest and type(quest[1]) == "table" then
        for i, v in ipairs(quest) do
            if checkItems(v[2], v[3] or 1) then
                acceptQuestByName(v[1])
                break
            end
        end
    elseif quest then
        if checkItems(quest[2], quest[3] or 1) then acceptQuestByName(quest[1]) end
    end
end

function Alterac:QUEST_PROGRESS()
    if bgzone and isQuestAutoTurnInQuest(GetTitleText()) then
        CompleteQuest()
    end
end

function Alterac:QUEST_COMPLETE()
    if bgzone and isQuestAutoTurnInQuest(GetTitleText()) then
        GetQuestReward(0)
    end
end
