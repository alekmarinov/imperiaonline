require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestWorkers=Class
{
	type="HarvestWorkers",
	URI_WORKERS="/imperia/game/workers.php?pr_nomer=",

	RESOURCE_TO_WORKSHOP={
		Wood="Lumbermill",
		Iron="Iron mine",
		Stone="Stone quarry"
	}
};

function _HarvestWorkers:download(province)
	self.data=HttpBrowser():get(_HarvestWorkers.URI_WORKERS..province);
	--FileUtil():writeAll("workers_"..province..".html", self.data);
end

function _HarvestWorkers:parse()
	-- parse occupied people
	self.workshops={};
	table.foreach(_Items.WORKSHOPS, function(workshopEn, workshopBg)
		local pattern=workshopBg.."</à></td><td align=\"center\" class=\"tip1\">(%d+)</td><td align=\"center\" class=\"tip1\">(%d+)</td><td align=\"center\" class=\"tip1\">(%d+)</td><td class=\"tip1\" align=\"center\">(%d+)";
		string.gsub(self.data, pattern, function(level, limit, occupied, production)
			self.workshops[workshopEn]={level=tonumber(level), limit=tonumber(limit), occupied=tonumber(occupied), production=tonumber(production)};
		end);
	end);

	-- parse free workers
	self.workshopFreeWorkers={};
	table.foreach(_Items.WORKSHOPS, function(workshopEn, workshopBg)
		string.gsub(self.data, workshopBg..".-value=(%d+)", function(workers)
			self.workshopFreeWorkers[workshopEn]=tonumber(workers);
		end);
	end);
end

function _HarvestWorkers:execute(province)
	self:log_debug("harvesting");
	self:download(province);
	self:parse();
end

function _HarvestWorkers:getWorkshopFreeWorkers()
	return self.workshopFreeWorkers;
end

function _HarvestWorkers:getWorkshops()
	return self.workshops;
end

function _HarvestWorkers:dump()
	self:log_debug("Free workers");
	self:log_debug("------------");
	table.foreach(self.workshopFreeWorkers, function(buildingName, workers)
		self:log_debug(buildingName.." - "..workers);
	end);
end

function HarvestWorkers()
	_HarvestWorkers=_HarvestWorkers:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestWorkers;
end
