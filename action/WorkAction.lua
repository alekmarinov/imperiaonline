require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("imperiaonline.harvest.HarvestWorkers");
require("logger.LoggingClass");

_WorkAction = Class
{
	type="WorkAction",
	URI_WORK_POST="/imperia/game/workers.php?tip=",
	WORKSHOP_ORDER=
	{
		"Lumbermill",
		"Iron mine",
		"Stone quarry"
	},
	WORKSHOP_NO=
	{
		["Lumbermill"]   = 2,
		["Iron mine"]    = 3,
		["Stone quarry"] = 4
	}
};

function _WorkAction:execute(param)
	Action():go("Province", param);

	if param.out then
		-- get out specified people out of the workshop
		local outAmount=param.out; -- amount of people to get out
		HarvestWorkers():execute(param.province);
		return table.foreachi(HarvestTrade():sortProfitableResources(true), function(workshopName, workshopName)
			workshopName=_HarvestWorkers.RESOURCE_TO_WORKSHOP[workshopName];
			if workshopName then
				HarvestWorkers():execute(param.province);
				local amountOccupied=HarvestWorkers():getWorkshops()[workshopName].occupied;
				if amountOccupied>0 then
					local available=math.min(outAmount, amountOccupied);
					outAmount=outAmount-available;
					self:log_info("Pr. #"..param.province..": get out "..outAmount.." people from "..workshopName);
					local postdata="broika="..outAmount.."&out=%%CE%%F1%%E2%%EE%%E1%%EE%%E6%%E4%%E0%%E2%%E0%%ED%%E5";
					local id=_WorkAction.WORKSHOP_NO[workshopName];
					local result, code, headers, status=HttpBrowser():post(_WorkAction.URI_WORK_POST..id, postdata, 
						HttpBrowser():getHeaders
						{
							["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/workers.php?log=no",
						}
					);
				end
				if outAmount == 0 then
					return true;
				end
			end
		end);
	else
		-- set all people to work
		table.foreachi(HarvestTrade():sortProfitableResources(), function(_, workshopName)
			workshopName=_HarvestWorkers.RESOURCE_TO_WORKSHOP[workshopName];
			if workshopName then
				HarvestWorkers():execute(param.province);
				local amountWorkers=HarvestWorkers():getWorkshopFreeWorkers()[workshopName] or 0;
				if amountWorkers>0 then
					self:log_info("Pr. #"..param.province..": move "..amountWorkers.." people in "..workshopName);
					local postdata="broika="..amountWorkers.."&in=%%CD%%E0%%E5%%EC%%E0%%ED%%E5";
					local id=_WorkAction.WORKSHOP_NO[workshopName];
					local result, code, headers, status=HttpBrowser():post(_WorkAction.URI_WORK_POST..id, postdata, 
						HttpBrowser():getHeaders
						{
							["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/workers.php?log=no",
						}
					);
				end
			end
		end);
	end

end

function WorkAction()
	return _WorkAction:inherit(AbstractAction(), LoggingClass());
end
