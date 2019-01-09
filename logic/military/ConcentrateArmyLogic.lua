require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.economy.FixGoldLogic");

_ConcentrateArmyLogic=Class
{
	type="ConcentrateArmyLogic",
	ARMY=true,
	RESOURCE=true
};

function _ConcentrateArmyLogic:execute(isArmies, isResources)

	local whatText="";
	if isArmies and isResources then
		whatText="armies and resources";
	elseif isArmies then
		whatText="armies";
	elseif isResources then
		whatText="resources";
	else
		-- do nothing
		return ;
	end

	FixGoldLogic():execute();

	self:log_info("Concentrate all "..whatText.." to the most powerfull fortress");

	-- concentrate all armies
	HarvestProvinces():execute();
	local provinces=HarvestProvinces():getStrongestProvinces();
	if isArmies then
		HarvestArmy():execute();
		table.foreachi(provinces, function(i, province)
			if i>1 then
				local armies=HarvestArmy():getProvinceArmies(province);
				local outArmies={};
				table.foreach(armies, function(unitName, amounts)
					if unitName ~= _Items.GARRISON then
						outArmies[unitName]=amounts[2];
					end
				end);

				Action():go("ArmyFortress", {province=province, outArmies=outArmies});
				HarvestArmy():execute();
				armies=HarvestArmy():getProvinceArmies(province);

				local armyMoves={};
				table.foreach(armies, function(unitName, amounts)
					if unitName ~= _Items.GARRISON then
						armyMoves[unitName]=amounts[1];
					end
				end);

				Action():go("ArmyMoves", {province=province, tprovince=provinces[1], armies=armyMoves});
			end
		end);
	end

	-- concentrate all resources
	if isResources then
		Action():go("TransportUnload");

		-- refresh iconomics information
		HarvestEconomy():execute();

		table.foreachi(provinces, function(i, province)
			if i>1 then
				-- transport all resources to the most striong province
				Action():go("Transport", {province=province, tprovince=provinces[1]});
			end
		end);
	end
end

function ConcentrateArmyLogic()
	if not _ConcentrateArmyLogic.initialized then
		_ConcentrateArmyLogic=_ConcentrateArmyLogic:inherit(LoggingClass());
		_ConcentrateArmyLogic.initialized=true;
	end
	return _ConcentrateArmyLogic;
end
