local _, addon = ...;

local DEBUFF_DEFAULT_VALUE = 30;

local PRIO_CLEANSE_DEBUFFS = {
	Banish = -100
};
PRIO_CLEANSE_DEBUFFS['Twisted Reflection'] = 100;
PRIO_CLEANSE_DEBUFFS['Soul Burn'] = 100;
PRIO_CLEANSE_DEBUFFS['Impending Doom'] = 100;
local PRIO_CLEANSE_TANK_DEBUFFS = {
	Chill = 100
};

addon.getCleanseScore = function(targetString)
	local highestDebuff = 0;
	-- find bad debuffs
	for i=1, 40 do 
		local debuffName, _, debuffCount, debuffType, debuffDuration = UnitDebuff(targetString, i); 

		if debuffName then 
			if ((debuffType == 'Magic') or (debuffType == 'Disease') or (debuffType == 'Poison')) then
				if (role == "MAINTANK") then
					highestDebuff = PRIO_CLEANSE_TANK_DEBUFFS[debuffName] or PRIO_CLEANSE_DEBUFFS[debuffName] or DEBUFF_DEFAULT_VALUE; 
				else
					highestDebuff = PRIO_CLEANSE_DEBUFFS[debuffName] or DEBUFF_DEFAULT_VALUE; 
				end
			end
		end
	end 

	return highestDebuff;
end

addon.getDispelMagicScore = function(targetString)
	local highestDebuff = 0;
	-- find bad debuffs
	for i=1, 40 do 
		local debuffName, _, debuffCount, debuffType, debuffDuration = UnitDebuff(targetString, i); 

		if debuffName then 
			if (debuffType == 'Magic') then
				if (role == "MAINTANK") then
					highestDebuff = PRIO_CLEANSE_TANK_DEBUFFS[debuffName] or PRIO_CLEANSE_DEBUFFS[debuffName] or DEBUFF_DEFAULT_VALUE; 
				else
					highestDebuff = PRIO_CLEANSE_DEBUFFS[debuffName] or DEBUFF_DEFAULT_VALUE; 
				end
			end
		end
	end 

	return highestDebuff;
end

addon.getCleanseDiseaseScore = function(targetString)
	local highestDebuff = 0;
	-- find bad debuffs
	for i=1, 40 do 
		local debuffName, _, debuffCount, debuffType, debuffDuration = UnitDebuff(targetString, i); 

		if debuffName then 
			if (debuffType == 'Disease') then
				if (role == "MAINTANK") then
					highestDebuff = PRIO_CLEANSE_TANK_DEBUFFS[debuffName] or PRIO_CLEANSE_DEBUFFS[debuffName] or DEBUFF_DEFAULT_VALUE; 
				else
					highestDebuff = PRIO_CLEANSE_DEBUFFS[debuffName] or DEBUFF_DEFAULT_VALUE; 
				end
			end
		end
	end 

	return highestDebuff;
end