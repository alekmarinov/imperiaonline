require("luaprocess");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("imperiaonline.harvest.HarvestBonuses");
require("logger.LoggingClass");

_BonusAction = Class
{
	type="BonusAction"
};

function _BonusAction:execute()
	HarvestBonuses():execute();
	self:log_info("Click all bonus links");
	table.foreachi(HarvestBonuses():getBonusLinks(), function(_, bonusLink)
		self:log_info("Click "..bonusLink);
		HttpBrowser():browse(bonusLink);
		process.usleep(800+math.random(2000));
	end);
	self:log_info("Bonus links done");
end

function BonusAction()
	return _BonusAction:inherit(AbstractAction(), LoggingClass());
end
