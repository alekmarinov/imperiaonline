require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestTrade=Class
{
	type="HarvestTrade",
	URI_TRADE="/imperia/game/trade.php?log=no",
	PRODUCTIVITY=
	{
		Wood=151,
		Iron=30,
		Stone=75
	}
};

function _HarvestTrade:download()
	self.data=HttpBrowser():get(_HarvestTrade.URI_TRADE);
	--FileUtil():writeAll("trade.html", self.data);
end

function _HarvestTrade:parse()
	string.gsub(self.data, "(%d+)%%%)</td></TR>", function(_c) self.commission=tonumber(_c); end);

	self.prices={};
	string.gsub(self.data, "=([%.%d]+) Злато.-=([%.%d]+) Злато.-=([%.%d]+) Злато", function(wood, iron, stone) 
		self.prices["Wood"]=wood;
		self.prices["Iron"]=iron;
		self.prices["Stone"]=stone;
	end, 1);
end

if TEST then
	function _HarvestTrade:download()
	end

	function _HarvestTrade:parse()
		self.prices={Wood=1, Iron=3, Stone=2};
		self.commission=50;
	end
end

function _HarvestTrade:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
	self.isExecuted=true;
end

function _HarvestTrade:sortProfitableResources(isReverse)
	if not self.isExecuted then self:execute(); end
	local resources={_Items.WOOD, _Items.IRON, _Items.STONE};
	table.sort(resources, function(a, b)
		local profitA=self.prices[a]*_HarvestTrade.PRODUCTIVITY[a];
		local profitB=self.prices[b]*_HarvestTrade.PRODUCTIVITY[b];

		if (isReverse and profitA<profitB) or (not isReverse and profitA>profitB) then
			return true;
		end
	end);
	table.insert(resources, 1, _Items.GOLD);
	return resources;
end

function _HarvestTrade:getCommission()
	if not self.isExecuted then self:execute(); end
	return self.commission;
end

-- Convert amount of gold to specified resource without commission included
function _HarvestTrade:convertGoldToResource(goldAmount, resourceName)
	if not self.isExecuted then self:execute(); end
	if resourceName == _Items.GOLD then
		return goldAmount;
	else
		return goldAmount/self.prices[resourceName];
	end
end

-- Convert amount of specified resource to gold without commission included
function _HarvestTrade:convertResourceToGold(resourceName, resourceAmount)
	if not self.isExecuted then self:execute(); end
	if resourceName == _Items.GOLD then
		return resourceAmount;
	else
		return resourceAmount*self.prices[resourceName];
	end
end

function _HarvestTrade:amountOfGoldIfSellResource(resourceName, resourceAmount)
	if not self.isExecuted then self:execute(); end
	if resourceName == _Items.GOLD then
		return resourceAmount;
	else
		return self:subCommission(resourceAmount*self.prices[resourceName]);
	
	end
end

function _HarvestTrade:convertResource(sourceResourceName, amount, targetResourceName)
	local gold=self:amountOfGoldIfSellResource(sourceResourceName, amount);
	local resourceAmount=self:convertGoldToResource(gold, targetResourceName);
	return self:subCommission(resourceAmount);
end

function _HarvestTrade:amountOfResourceToConvert(sourceResourceName, targetResourceName, amount)
	if sourceResourceName == _Items.GOLD then
		if targetResourceName == _Items.GOLD then
			return amount;
		else
			return amount*self.prices[targetResourceName]*(1+self.commission/100);
		end
	else
		if targetResourceName == _Items.GOLD then
			return amount/(self.prices[sourceResourceName]*(1-self.commission/100));
		else
			if sourceResourceName == targetResourceName then
				return amount;
			else
				return (amount*self.prices[targetResourceName]*(1+self.commission/100))/(self.prices[sourceResourceName]*(1-self.commission/100));
			end
		end
	end
end

function _HarvestTrade:amountOfResourceToBuyWithGold(resourceName, goldAmount)
	if resourceName == _Items.GOLD then
		return goldAmount;
	else
		return goldAmount/(self.prices[resourceName]*(1+self.commission/100));
	end
end

function _HarvestTrade:amountOfResourceIfTradeResource(sourceResourceName, amount, targetResourceName)
	if sourceResourceName == _Items.GOLD then
		if targetResourceName == _Items.GOLD then
			return amount;
		else
			return amount/(self.prices[targetResourceName]*(1+self.commission/100));
		end
	else
		if targetResourceName == _Items.GOLD then
			return amount*self.prices[sourceResourceName]*(1-self.commission/100);
		else
			return (amount*self.prices[sourceResourceName]*(1-self.commission/100))/(self.prices[targetResourceName]*(1+self.commission/100));
		end
	end
end

function _HarvestTrade:addCommission(amount)
	return amount*(1+self.commission/100);
end

function _HarvestTrade:subCommission(amount)
	return amount*(1-self.commission/100);
end

function _HarvestTrade:dump()
	if not self.isExecuted then self:execute(); end
	local resource=self:sortProfitableResources();
	self:log_debug("Resources:");
	table.foreachi(resource, function(_, resource)
		self:log_debug(resource.." (price="..self.prices[resource]..", profit "..self.prices[resource]*_HarvestTrade.PRODUCTIVITY[resource]..")");
	end);
	self:log_debug("Commission:"..self.commission);
end

function HarvestTrade()
	_HarvestTrade=_HarvestTrade:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestTrade;
end
