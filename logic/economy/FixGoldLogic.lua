require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");

_FixGoldLogic=Class
{
	type="FixGoldLogic"
};

function _FixGoldLogic:execute(province, amount)
	HarvestEconomy():execute();
	HarvestTrade():execute();

	local provinceNumbers=HarvestEconomy():getProvinceNumbers();
	-- search for negative gold in each province 
	local unloadOnce;
	table.foreachi(provinceNumbers, function(_, prNo)
		if not province or province == prNo then
			local goldAmount=HarvestEconomy():getProvinceResources(prNo)["Gold"];
			if amount or goldAmount<0 then
				goldAmount=amount or (-goldAmount*2);
				if not unloadOnce then
					Action():go("TransportUnload");
					unloadOnce=true;
				end
				local sellResources={};
				-- calculate amount of resources needed to cover the deficiency
				table.foreachi(HarvestTrade():sortProfitableResources(), function(_, resourceName)
					if resourceName ~= _Items.GOLD then
						local resourceRequired=HarvestTrade():amountOfResourceToConvert(resourceName, _Items.GOLD, goldAmount);
						local resourceAmount=HarvestEconomy():getProvinceResources(prNo)[resourceName];
						if resourceAmount>=resourceRequired then
							-- have enough resource
							sellResources[resourceName]=resourceRequired;
							return true;
						else
							sellResources[resourceName]=resourceAmount;
							local amountConverted=HarvestTrade():amountOfResourceIfTradeResource(resourceName, resourceAmount, _Items.GOLD);
							goldAmount=goldAmount-amountConverted;
						end
					end
				end);

				-- sell resources
				self:log_info("Fixing gold balance in province "..prNo);
				Action():go("Trade", {province=prNo, sell=sellResources});
			end
		end
	end);
end

function FixGoldLogic()
	if not _FixGoldLogic.initialized then
		_FixGoldLogic=_FixGoldLogic:inherit(LoggingClass());
		_FixGoldLogic.initialized=true;
	end
	return _FixGoldLogic;
end
