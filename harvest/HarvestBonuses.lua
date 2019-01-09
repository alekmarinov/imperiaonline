require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestBonuses=Class
{
	type="HarvestBonuses",
	URI_BONUS="/imperia/game/bonus.php?log=no",
	URI_BONUS_LINK="/imperia/game/votebonus.php?b_id=%d&users_id=%d"
};

function _HarvestBonuses:download()
	self.data=HttpBrowser():get(_HarvestBonuses.URI_BONUS);
	--FileUtil():writeAll("bonus.html", self.data);
end

function _HarvestBonuses:parse()
	self.bonusLinks={};
	string.gsub(self.data, "votebonus.php%?b_id=(%d+)%&users_id=(%d+)", function(bonusID, userID)
		table.insert(self.bonusLinks, string.format(_HarvestBonuses.URI_BONUS_LINK, tonumber(bonusID), tonumber(userID)));
	end);
end

function _HarvestBonuses:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
	self.isExecuted=true;
end

function _HarvestBonuses:getBonusLinks()
	return self.bonusLinks;
end

function _HarvestBonuses:dump()
	if not self.isExecuted then self:execute(); end
	table.foreachi(self.bonusLinks, function(_, bonusLink)
		self:log_debug("Bonus Link: "..bonusLink);
	end);
end

function HarvestBonuses()
	_HarvestBonuses=_HarvestBonuses:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestBonuses;
end
