require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");
require("imperiaonline.logic.Items");

_HarvestSpyInfo=Class
{
	type="HarvestSpyInfo",
	URI_ASK_SPY="/imperia/game/spyrlist.php?spy_id=",
};

function _HarvestSpyInfo:download(spy)
	self.data=HttpBrowser():get(_HarvestSpyInfo.URI_ASK_SPY..spy.id);
	FileUtil():writeAll("spy.html", self.data);
end

function _HarvestSpyInfo:parse()
	local patternResources="  		  				(%d+)";
	local patternPeople="		  		  		(%d+)";
	local patternFortress="(%d+) %(ниво%)";

	local resources={};
	string.gsub(self.data, patternResources, function(amount)
		table.insert(resources, tonumber(amount));
	end);

	self.resources={
		Wood=resources[1],
		Iron=resources[2],
		Stone=resources[3],
		Gold=resources[4]
	};

	string.gsub(self.data, patternPeople, function(amount)
		self.people=tonumber(amount);
	end);

	string.gsub(self.data, patternFortress, function(level)
		self.fortress=tonumber(level);
	end);

	local patternArmy="</TD><TD class=\"tip2\" align=\"right\">(%d+)</TD><TD class=\"tip2\"  align=\"right\">(%d+)</TD>";
	self.army={};
	self.data=string.gsub(self.data, "%<br%>", " ");
	table.foreach(_Items.ARMY, function(unitEn, unitBg)
		string.gsub(self.data, unitBg..patternArmy, function(amountOut, amountIn)
			self.army[unitEn]={tonumber(amountOut), tonumber(amountIn)};
		end);
	end);
end

function _HarvestSpyInfo:execute(spy)
	self:log_debug("harvesting");
	self:download(spy);
	self:parse();
end

function _HarvestSpyInfo:getResources()
	return self.resources;
end

function _HarvestSpyInfo:getFortressLevel()
	return self.fortress;
end

function _HarvestSpyInfo:getArmy()
	return self.army;
end

function _HarvestSpyInfo:dump()
end

function HarvestSpyInfo()
	_HarvestSpyInfo=_HarvestSpyInfo:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestSpyInfo;
end
