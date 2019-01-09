require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_TradeAction = Class
{
	type="TradeAction",
	URI_TRADE_SELL="/imperia/game/trade.php?resurs=%s&broika=%d&submit=+%%CF%%F0%%EE%%E4%%E0%%E2%%E0%%ED%%E5+",
	URI_TRADE_BUY="/imperia/game/trade.php?resurs=%s&broika=%d&submit=+%%CA%%F3%%EF%%F3%%E2%%E0%%ED%%E5+",
	MIN_RESOURCE_AMOUNT=100,
	MAX_RESOURCE_AMOUNT=200000,
};

function _TradeAction:execute(param)
	Action():go("Province", {province=param.province});
	local resources=HarvestEconomy():getProvinceResources(param.province);
	if param.sell then
		table.foreach(param.sell, function(resourceName, amount)
			if resourceName~=_Items.GOLD and amount>0 then
				amount=math.ceil(amount);
				if amount<_TradeAction.MIN_RESOURCE_AMOUNT then 
					amount=_TradeAction.MIN_RESOURCE_AMOUNT; 
				else
					if resources[resourceName]>amount then amount=amount+1; end
				end
				local initialAmount=amount;
				while initialAmount>0 do
					amount=initialAmount;
					if amount>_TradeAction.MAX_RESOURCE_AMOUNT then amount=_TradeAction.MAX_RESOURCE_AMOUNT; end
					self:log_info("Sell "..amount.." "..resourceName);
					HttpBrowser():browse(string.format(_TradeAction.URI_TRADE_SELL, string.lower(resourceName), amount));
					initialAmount=initialAmount-amount;
				end
			end
		end);
	end

	if param.buy then
		table.foreach(param.buy, function(resourceName, amount)
			if resourceName~=_Items.GOLD and amount>0  then
				amount=math.ceil(amount);
				if amount<_TradeAction.MIN_RESOURCE_AMOUNT then amount=_TradeAction.MIN_RESOURCE_AMOUNT; end
				local initialAmount=amount;
				while initialAmount>0 do
					amount=initialAmount;
					if amount>_TradeAction.MAX_RESOURCE_AMOUNT then amount=_TradeAction.MAX_RESOURCE_AMOUNT; end
					self:log_info("Buy "..amount.." "..resourceName);
					HttpBrowser():browse(string.format(_TradeAction.URI_TRADE_BUY, string.lower(resourceName), amount));
					initialAmount=initialAmount-amount;
				end
			end
		end);
	end
end

if TEST then
	function _TradeAction:execute(param)
		if param.sell then
			table.foreach(param.sell, function(resourceName, amount)
				if resourceName~=_Items.GOLD then
					if amount<_TradeAction.MIN_RESOURCE_AMOUNT then amount=_TradeAction.MIN_RESOURCE_AMOUNT; end
					if amount>_TradeAction.MAX_RESOURCE_AMOUNT then amount=_TradeAction.MAX_RESOURCE_AMOUNT; end
					self:log_info("Sell "..amount.." "..resourceName);

					resourceName=string.upper(string.sub(resourceName, 1, 1))..string.sub(resourceName, 2);
					local goldCollected=HarvestTrade():amountOfGoldIfSellResource(resourceName, amount);
					local resources=HarvestEconomy().provinces[param.province].resources;
					resources[resourceName]=resources[resourceName]-amount;
					resources.Gold=resources.Gold+goldCollected;
				end
			end);
		end

		if param.buy then
			table.foreach(param.buy, function(resourceName, amount)
				if resourceName~=_Items.GOLD then
					if amount<_TradeAction.MIN_RESOURCE_AMOUNT then amount=_TradeAction.MIN_RESOURCE_AMOUNT; end
					if amount>_TradeAction.MAX_RESOURCE_AMOUNT then amount=_TradeAction.MAX_RESOURCE_AMOUNT; end
					self:log_info("Buy "..amount.." "..resourceName);
					
					resourceName=string.upper(string.sub(resourceName, 1, 1))..string.sub(resourceName, 2);
					local goldSpent=HarvestTrade():amountOfGoldToBuyResource(resourceName, amount);
					local resources=HarvestEconomy().provinces[param.province].resources;
					resources[resourceName]=resources[resourceName]+amount;
					resources.Gold=resources.Gold-goldSpent;
				end
			end);
		end
	end	
end

function TradeAction()
	return _TradeAction:inherit(AbstractAction(), LoggingClass());
end
