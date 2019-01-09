require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.harvest.HarvestEconomy");
require("imperiaonline.harvest.HarvestTrade");
require("imperiaonline.logic.Items");

_BuildUtils=Class
{
	type="BuildUtils"
};

-- return true if the availableResources covers all requiredResources
function _BuildUtils:hasEnoughResources(requiredResources, availableResources)
	return not table.foreach(_Items.RESOURCES, function(resourceName, _)
		if tonumber(requiredResources[resourceName])>tonumber(availableResources[resourceName]) then
			self:log_info("not enough "..resourceName..". Required "..requiredResources[resourceName].." but available "..availableResources[resourceName]);
			return true;
		end
	end);
end

function _BuildUtils:hasEnoughResourcesIfTrade(requiredResources, availableResources)
	local newRequiredResources={};
	local sellResources={};
	local buyResources={};

	-- clone table
	table.foreach(requiredResources, function(k, v) newRequiredResources[k]=v; end);

	-- collect the remaining resources
	local remainingResources={};
	table.foreach(_Items.RESOURCES, function(resourceName)
		remainingResources[resourceName]=availableResources[resourceName]-newRequiredResources[resourceName];
		if remainingResources[resourceName]<0 then remainingResources[resourceName]=0; end

		newRequiredResources[resourceName]=newRequiredResources[resourceName]-availableResources[resourceName];
		if newRequiredResources[resourceName]<0 then newRequiredResources[resourceName]=0; end
	end);

	-- trade remaining resources
	table.foreachi(HarvestTrade():sortProfitableResources(), function(_, tradeResource)
		if remainingResources[tradeResource]>0 then
			table.foreach(_Items.RESOURCES, function(resourceName)
				if newRequiredResources[resourceName]>0 then
					-- convert required resource to trade resource
					local resourceRequired=HarvestTrade():amountOfResourceToConvert(tradeResource, resourceName, newRequiredResources[resourceName]);

					local resourceAvailable=math.min(resourceRequired, remainingResources[tradeResource]);
					sellResources[tradeResource]=(sellResources[tradeResource] or 0)+resourceAvailable;
					remainingResources[tradeResource]=remainingResources[tradeResource]-resourceAvailable;

					-- calculate amount of gold collected if trade available resource
					local resourceCollected=HarvestTrade():amountOfResourceIfTradeResource(tradeResource, resourceAvailable, resourceName);
					
					newRequiredResources[resourceName]=newRequiredResources[resourceName]-resourceCollected;
					buyResources[resourceName]=(buyResources[resourceName] or 0)+resourceCollected;
				end
			end);
		end
	end);

	if not table.foreach(newRequiredResources, function(resourceName, amount)
		if amount>1 then -- HACK! Requires more than 1 than 0 resources
			amount=math.ceil(amount);
			self:log_info("Not enough "..resourceName..". Required "..amount.." more");
			return true;
		end
	end) then
		return true, sellResources, buyResources;
	end
end

function BuildUtils()
	if not _BuildUtils.initialized then
		_BuildUtils=_BuildUtils:inherit(LoggingClass());
		_BuildUtils.initialized=true;
	end
	return _BuildUtils;
end
