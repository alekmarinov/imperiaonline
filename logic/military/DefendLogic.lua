require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");

_DefendLogic=Class
{
	type="DefendLogic"
};

function _DefendLogic:killSpies()
	local spies=HarvestAntiSpy():getSpies();
	self:log_info("Check for enemy spies");
	if table.getn(spies)>0 then
		self:log_warn("** Enemy spies detected!");
		table.foreachi(spies, function(_, spy)
			local enemy=spy.enemy or "Unknown enemy";
			self:log_info("`"..enemy.."' is spying province "..spy.province.." with spy level "..spy.level);
		end);
		Action():go("KillSpy", spies);
	end
end

function _DefendLogic:moveAllArmies(province, tprovince)
	local hasArmiesInFortress, hasArmiesOnField;
	local outArmies={};
	HarvestArmy():execute();
	local armies=HarvestArmy():getProvinceArmies(province);
	table.foreach(armies, function(unitName, amounts)
		if unitName ~= _Items.GARRISON then
			if amounts[2]>0 then
				outArmies[unitName]=amounts[2];
				hasArmiesInFortress=true;
			end
			if amounts[1]>0 then
				hasArmiesOnField=true;
			end
		end
	end);

	if hasArmiesInFortress then
		Action():go("ArmyFortress", {province=province, outArmies=outArmies});
	end

	HarvestArmy():execute();
	armies=HarvestArmy():getProvinceArmies(province);
	local armyMoves={};
	local needMove=false;
	table.foreach(armies, function(unitName, amounts)
		if unitName ~= _Items.GARRISON then
			if amounts[1]>0 then
				armyMoves[unitName]=amounts[1];
				needMove=true;
			end
		end
	end);

	if needMove then
		Action():go("ArmyMoves", {province=province, tprovince=tprovince, armies=armyMoves});
	end
end

function _DefendLogic:transportResources(province, tprovince)
	-- transport all from province to tprovince
	Action():go("Transport", {province=province, tprovince=tprovince});
end

function _DefendLogic:execute()
	local targetProvinces={};
	local dangerProvincesMap={};

	-- Kill all spies
	self:killSpies();

	if HarvestAntiSpy():isUnderAttack() then
		-- We are under attack
		self:log_warn("*** WE ARE UNDER ATTACK ***");

		-- Let's see the enemy army
		HarvestEnemyMove():execute();

		table.foreachi(HarvestEnemyMove():getEnemies(), function(_, enemy)
			self:log_info(enemy.name.." is attacking our province #"..enemy.tprovince.." after "..DateUtil():formatTime(enemy.time).."h with "..StringUtil():tableToString(enemy.army));

			dangerProvincesMap[enemy.tprovince]=true;
			table.insert(targetProvinces, {province=enemy.tprovince, time=enemy.time});
		end);

		-- sort target provinces in increasing order according the time the enemy will come
		table.sort(targetProvinces, function(prA, prB)
			if prA.time>prB.time then
				return true;
			end
		end);

	end

	-- fix negative gold
	FixGoldLogic():execute();

	-- try to move the armies to safe province
	HarvestProvinces():execute();
	if not table.foreachi(HarvestProvinces():getStrongestProvinces(), function(_, safeProvince)
		if not dangerProvincesMap[safeProvince] then
			table.foreachi(targetProvinces, function(_, targetInfo)
				-- Move all armies and resources to the strongest and the most safe province
				self:moveAllArmies(targetInfo.province, safeProvince);

				-- transport all resource
				self:transportResources(targetInfo.province, safeProvince);
			end);
			return true;
		end
	end) then
		-- all provinces are under attack, move to the latest enemy armies
		table.foreachi(targetProvinces, function(_, targetInfo)
			if targetInfo.province ~= targetProvinces[1].province then
				-- Move all armies and resources to the strongest and latest enemy armies
				self:moveAllArmies(targetInfo.province, targetProvinces[1].province);

				-- transport all resource
				self:transportResources(targetInfo.province, targetProvinces[1].province);
			end
		end);
	end
end

function DefendLogic()
	if not _DefendLogic.initialized then
		_DefendLogic=_DefendLogic:inherit(LoggingClass());
		_DefendLogic.initialized=true;
	end
	return _DefendLogic;
end
