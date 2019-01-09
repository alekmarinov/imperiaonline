require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_ArmyFortressAction = Class
{
	type="ArmyFortressAction",
	URI_ARMY_LOCATION="/imperia/game/razpolojenienavoiskata.php?vidvoiska=",
};

function _ArmyFortressAction:execute(param)
	Action():go("Province", param);

	if param.inArmies then
		table.foreach(param.inArmies, function(unitName, amount)
			if amount>0 then
				self:log_info("Put "..amount.." "..unitName.." in fortress #"..param.province);
				local postdata="broika="..amount.."&in=%%C2%%EA%%E0%%F0%%E2%%E0%%ED%%E5";
				local result, code, headers, status=HttpBrowser():post(
					_ArmyFortressAction.URI_ARMY_LOCATION.._TrainAction.CODES[unitName], 
					postdata,
					HttpBrowser():getHeaders
					{
						["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/razpolojenienavoiskata.php?log=no",
					}
				);
			end
		end);
	end

	if param.outArmies then
		table.foreach(param.outArmies, function(unitName, amount)
			if amount>0 then
				self:log_info("Get "..amount.." "..unitName.." out of fortress #"..param.province);
				local postdata="out=%%C8%%E7%%EA%%E0%%F0%%E2%%E0%%ED%%E5&broika="..amount;
				local result, code, headers, status=HttpBrowser():post(
					_ArmyFortressAction.URI_ARMY_LOCATION.._TrainAction.CODES[unitName], 
					postdata,
					HttpBrowser():getHeaders
					{
						["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/razpolojenienavoiskata.php?log=no",
					}
				);
			end
		end);
	end

end

function ArmyFortressAction()
	return _ArmyFortressAction:inherit(AbstractAction(), LoggingClass());
end
