--[[
	Author: perryfraser@gmail.com
--]]

local function has_value (tab, val)
	for index, value in ipairs(tab) do
			-- We grab the first index of our sub-table instead
			if value[1] == val then
					return true
			end
	end

	return false
end

-- Addon Global Variables (shared between files but not addons). addon var name can be renamed
local AddOnName, addon = ...;
local swingTimer = 0.00001;
local currentSwingTime = 2;

local LIGHT_SIZE = 4;

local FLASH_TIME = 2;
local LIGHT_TIME = 3;
local BLESSING_VALUE = 20;
local DEBUFF_DEFAULT_VALUE = 30;
local RESOLVE_THRESHOLD = 4;
local COMBAT_FOLLOW_SCALAR = 0.5;

local LIGHT_ROWS = 100;
local LIGHT_RAID_INDEX_COUNT = 15;
local LIGHT_RAID_ACTION_COUNT = 3;

local SUB_LIGHT_ACTION_INDEXES = {
	Sequence = 0,
	Lifetap = 4,
	Drink = 5,
	Follow = 6,
	Jump = 7,
	Nothing = -1
};

local LIGHT_COUNT = 
	LIGHT_RAID_INDEX_COUNT +
	LIGHT_RAID_ACTION_COUNT;

local SUB_LIGHT_PLAYER_INDEX = 1;
local SUB_LIGHT_PARTY_INDEX = 2;
local SUB_LIGHT_RAID_INDEX = 7;
local SEQUENCE_VALUE = 29;

-- there is a macro that sets this to 1 then 2, etc.
local jumpAdjustor = 0;
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # test if this works with offline people

addon.version = "1.0.0"
addon.name = "Light Status"
addon.debug = false;
addon.initd = false;

addon.playerBean = {};
addon.friendBean = {};
addon.followBean = {targetName = "Cherrypear", followScore = 0};

addon.nextAction = {};

addon.lights = {};

addon.nextCastTarget = -1;
addon.nextCastAbility = -1;

addon.updateLightStatus = function(index, r, g, b)
	if (addon.lights[index] ~= nil) then
		local color = r + g * 2 + b * 4;

		if (addon.lights[index].previousColor ~= color) then
			if (color == 1) then
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\red");
			elseif (color == 2) then
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\green");
			elseif (color == 3) then
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\yellow");
			elseif (color == 4) then
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\blue");
			elseif (color == 5) then
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\magenta");
			elseif (color == 6) then
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\teal");
			elseif (color == 7) then
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\white");
			else
				addon.lights[index].texture:SetTexture("Interface\\AddOns\\HealLightStatus\\black");
			end
			addon.lights[index].previousColor = color;

			-- print("color updated: " .. tostring(index) .. " to " .. tostring(color));
		end
	end
end
addon.updateUI = function()
	if (addon.lights[0] ~= nil) then
		-- print('')
	end
end

-- onUpdateHandler
addon.onUpdateHandler = function(self, elapsed)
	if (not addon.initd) then 
		return;
	end

	if (UnitIsDeadOrGhost("player")) then
		for i=1, LIGHT_RAID_INDEX_COUNT do
			addon.updateLightStatus(i, 0, 0, 0);
		end
	
		for i=1, LIGHT_RAID_ACTION_COUNT do
			local adjustedI = LIGHT_RAID_INDEX_COUNT + i;
			addon.updateLightStatus(adjustedI, 0, 0, 0);
		end
		addon.updateUI();

		return;
	end

	-- general update;

	local nextActionBean = addon.getActionBean();

	if (nextActionBean) then
		addon.nextCastTarget = nextActionBean.target;
		addon.nextCastAbility = nextActionBean.action;
		
		local target = addon.getIndexFromTargetString(addon.nextCastTarget);

		-- update the visuals
		-- first 14 lights are for players
		-- the next 6 lights are for the actions of:

		-- Light
		-- Flash
		-- Blessing
		-- Cleanse
		-- Drink
		-- Follow
		-- Jump
		-- Nothing
		local actionSubIndex = SUB_LIGHT_ACTION_INDEXES[addon.nextCastAbility];

		local targetSubIndex = -1;

		if (target) then
			if (target.type == "player") then
				targetSubIndex = SUB_LIGHT_PLAYER_INDEX;
			elseif (target.type == "party") then
				targetSubIndex = SUB_LIGHT_PARTY_INDEX + target.index;
			elseif (target.type == "raid") then
				targetSubIndex = SUB_LIGHT_RAID_INDEX + target.index;
			end
		end

		for i=1, LIGHT_RAID_INDEX_COUNT do
			local subIndexStart = ((i - 1) * 3) + 1;

			local r = ((targetSubIndex - 0) == subIndexStart and 1) or 0;
			local g = ((targetSubIndex - 1) == subIndexStart and 1) or 0;
			local b = ((targetSubIndex - 2) == subIndexStart and 1) or 0;

			addon.updateLightStatus(i, r, g, b);
		end
	

		for i=1, LIGHT_RAID_ACTION_COUNT do
			local adjustedI = LIGHT_RAID_INDEX_COUNT + i;
			local subIndexStart = ((i - 1) * 3);

			local r = ((actionSubIndex - 0) == subIndexStart and 1) or 0;
			local g = ((actionSubIndex - 1) == subIndexStart and 1) or 0;
			local b = ((actionSubIndex - 2) == subIndexStart and 1) or 0;

			addon.updateLightStatus(adjustedI, r, g, b);
		end
	end
	addon.updateUI();
end

addon.onCombatLogUnfiltered = function(combat_info)
end

addon.updatePlayer = function()
	local isInCombat = UnitAffectingCombat("player");
	local speed = GetUnitSpeed("player");
	local castingSpell = CastingInfo();
	local mana = UnitPower("player");
	local manaMax = UnitPowerMax("player");

	local isDrinking = false;
	for i=1, 40 do
		local buffName = UnitBuff("player", i);

		if (buffName == "Drink") then
			isDrinking = true;

			break;
		end
	end

	addon.playerBean["isDrinking"] = isDrinking;
	addon.playerBean["isMoving"] = speed ~= 0;
	addon.playerBean["isInCombat"] = isInCombat;
	addon.playerBean["castingSpell"] = castingSpell;
	addon.playerBean["mana"] = mana / manaMax;
end

addon.getActionBean = function()
	addon.updatePlayer();

	for raidIndex = 1, 40 do
		-- update the raid members
		local friendValue = addon.updateFriendAtRaidIndex(raidIndex);

		if (friendValue and (friendValue["name"] == addon.followBean.targetName)) then
			addon.followBean.target = friendValue["targetString"];
		end
	end

	local focusFriendValue = addon.updateFriendAtRaidIndex(FOCUS_INDEX);
	if (focusFriendValue and (focusFriendValue["name"] == addon.followBean.targetName)) then
		addon.followBean.target = focusFriendValue["targetString"];
	end

	addon.updateFollow();

	if (not addon.playerBean["castingSpell"]) then
		local highestAction = "Nothing";
		local highestActionValue = RESOLVE_THRESHOLD;
		local highestActionTarget = "";
		
		local tapValue = ((1 - addon.playerBean["mana"]) * 100) - 10;
		local combatTapValue = ((1 - addon.playerBean["mana"]) * 100) - 70;
		-- print(tostring(drinkValue))

		highestAction = "Lifetap";
		highestActionValue = (addon.playerBean["isInCombat"] and combatTapValue) or tapValue;

		if (addon.followBean.followScore > highestActionValue) then
			highestAction = "Follow";
			highestActionValue = addon.followBean.followScore;
			highestActionTarget = addon.followBean.target;
		end

		-- print(tostring(addon.followBean["isInCombat"]) .. " : " .. tostring(SEQUENCE_VALUE > highestActionValue));
		if (addon.followBean["isInCombat"] and (SEQUENCE_VALUE > highestActionValue)) then
			highestAction = "Sequence";
			highestActionValue = SEQUENCE_VALUE;
		end

		if (highestActionValue <= RESOLVE_THRESHOLD) then
			highestAction = "Nothing";
			highestActionValue = 0;
		end

		if (highestAction == "Nothing" and addon.playerBean.isMoving and (highestActionValue <= RESOLVE_THRESHOLD) and ((GetTime() % (8 - jumpAdjustor)) < 0.5)) then
			jumpAdjustor = math.random() * 4;
			-- jump sometimes
			highestAction = "Jump";
		end

		-- print(tostring(highestAction) .. ": " .. highestActionTarget .. " = " .. highestActionValue);

		return {
			target = highestActionTarget,
			action = highestAction
		}
	end
end

addon.getIndexFromTargetString = function(targetString)
	for raidIndex = 1, 40 do
		local testString = "raid" .. tostring(raidIndex);

		if (targetString == testString) then
			return {
				type = "raid",
				index = raidIndex
			};
		end
	end

	for partyIndex = 1, 4 do
		local testString = "party" .. tostring(partyIndex);

		if (targetString == testString) then
			return {
				type = "party",
				index = partyIndex
			};
		end
	end

	if (targetString == "player") then return { type = "player" } end
	return nil;
end

addon.getTargetStringFromIndex = function(index)
	local name, rank, subgroup, _, class, _, zone, online, isDead, role = GetRaidRosterInfo(index);

	for raidIndex = 1, 40 do
		local testString = "raid" .. tostring(raidIndex);
		local nameTest = GetUnitName(testString);

		if (nameTest == name) then
			return testString;
		end
	end

	for partyIndex = 1, 4 do
		local testString = "party" .. tostring(partyIndex);
		local nameTest = GetUnitName("party" .. tostring(partyIndex))

		if (nameTest == name) then
			return testString;
		end
	end

	local playerName = GetUnitName("player");
	if (playerName == name) then return "player"; end
	return "";
end

addon.setObjectToNoValue = function(guid)
	local object = addon.friendBean[guid];

	if (object) then
		object.lightScore = 0;
		object.flashScore = 0;
		object.cleanseScore = 0;
		object.blessingScore = 0;
		object.resScore = 0;
	end
end

addon.updateFollow = function() 
	-- logic. never let the target player go outside of follow range
	if (UnitIsDeadOrGhost(addon.followBean.target)) then
		return;
	end
	if (addon.followBean.targetName) then
		local inTen = CheckInteractDistance(addon.followBean.target, 2); -- 10 yard range
		local inThirty = CheckInteractDistance(addon.followBean.target, 4); -- 30 yard range
		local inTwenty = IsSpellInRange("Fear", addon.followBean.target) == 1;

		if (inThirty and not inTen) then
			addon.followBean.followScore = 30;
		else
			addon.followBean.followScore = 0;
		end

		-- check if it's in combat
		-- print(tostring(addon.followBean.isInCombat))
		addon.followBean.isInCombat = UnitAffectingCombat(addon.followBean.target);
	end
end

addon.updateFriendAtRaidIndex = function(raidIndex)
	local name, rank, subgroup, _, class, _, zone, online, isDead, role = GetRaidRosterInfo(raidIndex);
	local targetString = addon.getTargetStringFromIndex(raidIndex);
	local guid = UnitGUID(targetString);

	local object = addon.friendBean[guid] or {};

	if (guid == nil or name == nil) then
		return;
	end

	addon.setObjectToNoValue(guid);

	object.targetString = targetString;
	object.name = name; 
	object.class = class;

	-- check zone
	addon.friendBean[guid] = object;

	return object;
end

-- addon.init
addon.init = function()
	for i=1,LIGHT_COUNT do
		local ai = i - 1;
		local x = math.floor(ai / LIGHT_ROWS);
		local y = (ai % LIGHT_ROWS * LIGHT_SIZE);

		addon.lights[i] = CreateFrame("frame", nil, UIParent); 
		addon.lights[i]:SetFrameStrata("TOOLTIP");

		addon.lights[i]:SetWidth(LIGHT_SIZE);
		addon.lights[i]:SetHeight(LIGHT_SIZE);
		addon.lights[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", y, y);
		addon.lights[i].texture = addon.lights[i]:CreateTexture(nil, "BACKGROUND");
		addon.lights[i].texture:SetAllPoints(true);
		addon.lights[i]:SetClampedToScreen(true);
		addon.updateLightStatus(i, 1, 0, 0);
	end
	
	addon.playerGuid = UnitGUID("player");
	addon.initd = true;

	-- write all the macros
	EditMacro("Sequence", "Sequence", "", 
"#showtooltip\n/tar " .. addon.followBean.targetName .. "\n/petattack targettarget\n/castsequence [@targettarget] reset=targettarget,combat Immolate, Shadow Bolt, Shadow Bolt, Shadow Bolt, Shadow Bolt, Shadow Bolt, Shadow Bolt, Shadow Bolt");
	EditMacro("Follow", "Follow", "135946", 
"/tar " .. addon.followBean.targetName .. "\n/follow");

end

-- This should be done last so everything is available to it
addon.eventFrame = CreateFrame("frame", nil, UIParent, nil, 0);
addon.eventFrame:RegisterEvent("ADDON_LOADED");
addon.eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
addon.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
addon.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
addon.eventFrame:SetScript("OnEvent", 
	function(self, event, ...)
		PlayerFrame:SetFrameStrata("BACKGROUND");
		if (event == "ADDON_LOADED") then
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local combat_info = {CombatLogGetCurrentEventInfo()}
			addon.onCombatLogUnfiltered(combat_info)
		elseif event == "CHAT_MSG_WHISPER" then
			local text, playerName = ...;

			if ((not addon.initd) and (string.match(playerName, "pear") or string.match(playerName, "Pear"))) then
				local name, server = string.match(playerName, "(.+)-(.+)");
				addon.followBean.targetName = text;
				addon.init();
			end
		end
	end
);
addon.eventFrame:SetScript("OnUpdate", addon.onUpdateHandler);
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #