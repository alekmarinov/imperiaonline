require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_ArmyMovesAction = Class
{
	type="ArmyMovesAction",
	URI_ARMY_MOVE="/imperia/game/movearmy.php?log=no",
	URI_ARMY_MOVE_POST="/imperia/game/movearmy.php"
};

function _ArmyMovesAction:execute(param)
	Action():go("Province", param);

	HttpBrowser():browse(_ArmyMovesAction.URI_ARMY_MOVE);
	local postdata="";
	local hasArmies=false;
	local msgArmies="";
	table.foreach(param.armies, function(unitName, amount)
		if amount>0 then
			postdata=postdata.."M_".._TrainAction.CODES[unitName].."="..amount.."&";
			if string.len(msgArmies)>0 then
				msgArmies=msgArmies..",";
			end
			msgArmies=msgArmies..amount.." "..unitName;
			hasArmies=true;
		end
	end);
	if hasArmies then
		self:log_info("Move armies from #"..param.province.." to #"..param.tprovince.." {"..msgArmies.."}");
		postdata=postdata.."nomer="..param.tprovince.."&move=%%CF%%F0%%E5%%EC%%E5%%F1%%F2%%E2%%E0%%ED%%E5";
		local result, code, headers, status=HttpBrowser():post(
			_ArmyMovesAction.URI_ARMY_MOVE_POST, 
			postdata,
			HttpBrowser():getHeaders
			{
				["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/movearmy.php?log=no",
			}
		);
	end
end

function ArmyMovesAction()
	return _ArmyMovesAction:inherit(AbstractAction(), LoggingClass());
end
