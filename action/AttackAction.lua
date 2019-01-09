require("luaprocess");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_AttackAction = Class
{
	type="AttackAction",
	URI_ATTACK="/imperia/game/atakuvane.php"
};

function _AttackAction:execute(params)
	HarvestArmy():execute();
	local army = HarvestArmy():getProvinceArmies(params.province);

	-- check if there are enough armies in the province's field
	if not table.foreach(params.army, function(unitName, amount)
		if army[unitName][1]<amount then
			return true;
		end
	end) then
		self:log_info("**** ATTACK "..params.enemy.."("..params.tprovince..")!");
		Action():go("Province", params);

		-- ok, the required army is enough, do the attack
		local s="";
		table.foreach(params.army, function(unitName, amount)
			s=s.."M_".._TrainAction.CODES[unitName].."="..amount.."&";
		end);

		local postdata=s.."ime="..params.enemy.."&nomer="..params.tprovince.."&move=%D0%E0%E7%E3%F0%E0%E1%E2%E0%ED%E5";
		local result, code, headers, status=HttpBrowser():post(_AttackAction.URI_ATTACK, postdata, 
			HttpBrowser():getHeaders
			{
				["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/atakuvane.php?log=no",
			}
		);

		return true;
	else
		self:log_warn("Not enough army to attack");
	end
end

function AttackAction()
	return _AttackAction:inherit(AbstractAction(), LoggingClass());
end
