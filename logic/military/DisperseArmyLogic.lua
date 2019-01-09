require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");

_DisperseArmyLogic=Class
{
	type="DisperseArmyLogic"
};

function _DisperseArmyLogic:execute()

	self:log_info("Hide all armies in fortresses to save more gold");

	HarvestArmy():execute();
	HarvestProvinces():execute();

	-- sort unit names by price without the siege weapons
	local unitNames={};
	table.foreach(_Items.ARMIES, function(unitName, _)
		if unitName ~= "Battering ram" and unitName ~= "Catapult" and unitName ~= "Trebuchet" then
			table.insert(unitNames, unitName);
		end
	end);
	table.sort(unitNames, function(unitA, unitB)
		if HarvestTrainings():getUnitPrices(unitA).Wood>HarvestTrainings():getUnitPrices(unitB).Wood then
			return true;
		end
	end);

	local provinces=HarvestProvinces():getStrongestProvinces();
	table.foreachi(provinces, function(i, province)
		local outArmies={};
		local hasArmies=false;
		local hasArmiesOnField=false;
		local armies=HarvestArmy():getProvinceArmies(province);
		-- is there armies on the field?
		table.foreach(armies, function(unitName, amounts)
			if unitName ~= _Items.GARRISON then
				if amounts[2]>0 then
					outArmies[unitName]=amounts[2];
					hasArmies=true;
				end
				if amounts[1]>0 then
					hasArmiesOnField=true;
				end
			end
		end);
		if hasArmiesOnField then
			if hasArmies then
				-- get out all armies from the fortress
				Action():go("ArmyFortress", {province=province, outArmies=outArmies});
			end

			HarvestArmy():execute();
			armies=HarvestArmy():getProvinceArmies(province);

			local freeSpace=armies[_Items.GARRISON][2];
			local inArmies={};
			local armyMoves={};
			local hasToMove=false;
			hasArmies=false;
			table.foreachi(unitNames, function(_, unitName)
				if armies[unitName] and armies[unitName][1]>0 then
					local inAmount=math.min(armies[unitName][1], freeSpace);
					freeSpace=freeSpace-inAmount;
					inArmies[unitName]=inAmount;
					hasArmies=true;
					if (armies[unitName][1]-inAmount)>0 then
						-- not all units are moved into the fortress
						armyMoves[unitName]=armies[unitName][1]-inAmount;
						hasToMove=true;
					end
				end
			end);
			if hasArmies then
				-- Put the most expensive armies in the fortress
				Action():go("ArmyFortress", {province=province, inArmies=inArmies});
			end

			if hasToMove and table.getn(provinces)>1 then
				if i<table.getn(provinces) then
					-- move the remaining armies to the next province
					Action():go("ArmyMoves", {province=province, tprovince=provinces[i+1], armies=armyMoves});
				else
					-- move the remaining armies to the first province
					Action():go("ArmyMoves", {province=province, tprovince=provinces[1], armies=armyMoves});
				end
			end
		end -- if armies on the field
	end);
end

function DisperseArmyLogic()
	if not _DisperseArmyLogic.initialized then
		_DisperseArmyLogic=_DisperseArmyLogic:inherit(LoggingClass());
		_DisperseArmyLogic.initialized=true;
	end
	return _DisperseArmyLogic;
end
