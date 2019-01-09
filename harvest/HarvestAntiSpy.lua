require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestAntiSpy=Class
{
	type="HarvestAntiSpy",
	URI_ANTI_SPY="/imperia/game/kspy.php?log=no",
};

function _HarvestAntiSpy:download()
	self.data=HttpBrowser():get(_HarvestAntiSpy.URI_ANTI_SPY);
	--FileUtil():writeAll("kspy.html", self.data);
end

function _HarvestAntiSpy:parse()
	self.spies={};
	local pattern="class=\"tip1\">(.-)</td><td align=\"center\" class=\"tip2\">No%.(%d+)</td><td align=\"center\" class=\"tip2\">(%d+) ниво.-Заловяване\"  onclick=\"location%.href='kspy.php%?spy_id=(%d+)";
	local noInfo="Липсва информация";
	string.gsub(self.data, pattern, function(enemy, province, level, spyID)
		if enemy == noInfo then
			enemy=nil;
		end
		table.insert(self.spies, {enemy=enemy, province=province, level=level, id=spyID});
	end);
	if string.find(self.data, "НАПАДАТ ВИ", 1, true) then
		self.underAttack=true;
	else
		self.underAttack=false;
	end
end

function _HarvestAntiSpy:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
end

function _HarvestAntiSpy:getSpies()
	self:execute();
	return self.spies;
end

function _HarvestAntiSpy:isUnderAttack()
	self:execute();
	return self.underAttack;
end

function _HarvestAntiSpy:dump()
	self:log_debug("Spy information:");
	table.foreachi(self.spies, function(_, spy)
		local enemy=spy.enemy or "Unknown enemy";
		self:log_info("`"..enemy.."' is spying province "..spy.province.." with spy level "..spy.level);
	end);
end

function HarvestAntiSpy()
	_HarvestAntiSpy=_HarvestAntiSpy:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestAntiSpy;
end
