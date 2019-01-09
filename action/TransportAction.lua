require("imperiaonline.action.AbstractAction");
--require("imperiaonline.action.Action");
require("imperiaonline.harvest.HarvestEconomy");
require("imperiaonline.harvest.HarvestTransport");
require("logger.LoggingClass");

_TransportAction = Class
{
	type="TransportAction",
	URI_TRANSPORT_POST="/imperia/game/transport.php",
};

function _TransportAction:getCargoCapacity(province)
	local depotLevel=tonumber(HarvestEconomy():getProvinceBuildings(province)["Depot Station"]);
	function levelToCargo(level)
		if level == 0 then
			return 0;
		else
			return 2000+levelToCargo(level-1)*1.5;
		end
	end
	return levelToCargo(depotLevel);
end

function _TransportAction:fitCapacity(param, capacity)
	local total=param.Wood+param.Iron+param.Stone+param.Gold;
	if total>capacity then
		if total-param.Wood <= capacity then
			param.Wood=capacity-(param.Iron+param.Stone+param.Gold);
		else
			total=total-param.Wood;
			param.Wood=0;
			if total-param.Stone <= capacity then
				param.Stone=capacity-(param.Iron+param.Gold);
			else
				total=total-param.Stone;
				param.Stone=0;
				if total-param.Iron <= capacity then
					param.Iron=capacity-param.Gold;
				else
					total=total-param.Iron;
					param.Iron=0;
					if total > capacity then
						param.Gold=capacity;
					end
				end
			end
		end
	end
	return param;
end

function _TransportAction:execute(param)
	local province=param.province;
	-- switch to target province
	Action():go("Province", param);
	
	HarvestTransport():execute();

	-- transport if the source depot is not occuppied
	if HarvestTransport():depotAvailable(province) then
		if not (param.Wood or param.Iron or param.Stone or param.Gold) then
			-- transport all
			table.foreach(HarvestEconomy():getProvinceResources(province), function(resourceName, amount)
				param[resourceName]=amount;
			end);
		end
		param.Wood=param.Wood and math.ceil(param.Wood ) or 0;
		param.Iron=param.Iron and math.ceil(param.Iron ) or 0;
		param.Stone=param.Stone and math.ceil(param.Stone ) or 0;
		param.Gold=param.Gold and math.ceil(param.Gold ) or 0;
		if param.Gold>=0 then
			if param.Wood>0 or param.Iron>0 or param.Stone>0 or param.Gold>0 then
				local capacity=self:getCargoCapacity(province);
				param=self:fitCapacity(param, capacity);
				self:log_info("Transport "..StringUtil():tableToString(param, {"province", "tprovince", "Wood", "Iron", "Stone", "Gold"}));
				local postdata="kapacitet=+"..capacity.."&tname="..HttpSession():getUsername().."&tnomer="..param.tprovince.."&twood="..(param.Wood or 0).."&tiron="..(param.Iron or 0).."&tstone="..(param.Stone or 0).."&tgold="..(param.Gold or 0).."&submit=%%C8%%E7%%EF%%F0%%E0%%F9%%E0%%ED%%E5";

				-- perform transporting from province `province' to province `param.tprovince'
				local result, code, headers, status=HttpBrowser():post(_TransportAction.URI_TRANSPORT_POST, postdata, 
					HttpBrowser():getHeaders
					{
						["Referer"]="http://www.imperiaonline.org/imperia/game/new.php",
					}
				);

				-- additional check if transporting operation is successfully executed
				HarvestTransport():execute();
				return table.foreachi(HarvestTransport():getTransports(), function(_, transportInfo)
					if tonumber(province)==transportInfo.fromProv and tonumber(param.tprovince)==transportInfo.toProv then
						return true;
					end
				end);
			end
		end
	end
end

function TransportAction()
	return _TransportAction:inherit(AbstractAction(), LoggingClass());
end
