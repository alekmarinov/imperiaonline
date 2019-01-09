require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.military.SelectTargetLogic");

_AttackTargetLogic=Class
{
	type="AttackTargetLogic"
};

function _AttackTargetLogic:attackTarget(province, target)
	local army = HarvestArmy():getProvinceArmies(province);
	local outArmies={};
	local needOutArmies=false;
	table.foreach(army, function(unitName, amounts)
		if unitName ~= _Items.GARRISON then
			if amounts[2]>0 then
				needOutArmies=true;
				outArmies[unitName]=amounts[2];
			end
		end
	end);
	if needOutArmies then
		Action():go("ArmyFortress", {province=province, outArmies=outArmies});
	end
	if target.friendArmy then
		return Action():go("Attack", {province=province, tprovince=target.province, enemy=target.enemy, army=target.friendArmy});
	else
		-- no friend army defined, pick appropriate army configuration corresponding to the enemy's fortress
		local friendArmy=MilitaryManager():getArmyForFortress(army, target.Fortresses);
		if friendArmy then
			return Action():go("Attack", {province=province, tprovince=target.province, enemy=target.enemy, army=friendArmy});
		else
			self:log_info("Not enough army to attack "..target.enemy.." with fortress level "..target.Fortresses);
		end
	end
end

function _AttackTargetLogic:execute()
	HarvestProvinces():execute();
	local province=HarvestProvinces():getStrongestProvinces()[1];

	-- concentrate all armies in the most powerful province
	ConcentrateArmyLogic():execute(_ConcentrateArmyLogic.ARMY);

	-- refresh army information
	HarvestArmy():execute(province);

	-- provide enough gold to make spying possible 
	Action():go("Province", {province=province});

	local targets=SelectTargetLogic():execute(province);
	HarvestFriendMove():execute();
	if table.getn(targets) > 0 then -- something to attack?
		table.foreachi(targets, function(_, target)
			-- are we already attacking him?
			if not target.attacked and not HarvestFriendMove():isAttacking(target.enemy, target.province) then
				if self:attackTarget(province, target) then
					if target.time then
						target.attacked=true;
					end
				end
			end
		end);
	end
end

function AttackTargetLogic()
	if not _AttackTargetLogic.initialized then
		_AttackTargetLogic=_AttackTargetLogic:inherit(LoggingClass());
		_AttackTargetLogic.initialized=true;
	end
	return _AttackTargetLogic;
end
