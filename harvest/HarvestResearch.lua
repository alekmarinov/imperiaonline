require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.Items");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestResearch=Class
{
	type="HarvestResearch",
	URI_RESEARCH="/imperia/game/constructions.php?tip=r&log=no",
	URI_CONSTRUCTIONS="/imperia/game/constructions.php?tip=c&pr_nomer="
};

function _HarvestResearch:download(provinceNo)
	HttpBrowser():get(_HarvestConstructions.URI_CONSTRUCTIONS..(provinceNo or "8"));
	self.data=HttpBrowser():get(_HarvestResearch.URI_RESEARCH);
	--FileUtil():writeAll("research.html", self.data);
end

function _HarvestResearch:parse()
	self.researchPrices={};
	self.brokenFortress=true;
	table.foreach(_Items.RESEARCHES, function(researchEn, researchBg)
		researchBg=string.gsub(researchBg, "-", "%%-");
		string.gsub(self.data, ">"..researchBg..".-Дърво %- (%d+)<BR>Желязо %- (%d+)<BR>Камък %- (%d+)<BR>Злато %- (%d+)", function(wood, iron, stone, gold)
			self.brokenFortress=false;
			self.researchPrices[researchEn]={
				Wood=tonumber(wood),
				Iron=tonumber(iron),
				Stone=tonumber(stone),
				Gold=tonumber(gold)
			};
		end);
		if not self.researchPrices[researchEn] then
			self:log_warn("Unable to harvest the price of "..researchEn);
		end
	end);
	if self.brokenFortress then
		self:log_debug("Fortress broken in province "..provinceNo);
	end
end

if TEST then
	function _HarvestResearch:download(provinceNo)
	end

	function _HarvestResearch:parse()
		self.researchPrices={
			Bureaucracy={Wood=30000, Iron=80000, Stone=100000, Gold=200000}
		};
	end
end

function _HarvestResearch:execute(provinceNo)
	self:log_debug("harvesting researches"..(provinceNo and (" in province "..provinceNo) or ""));
	if HarvestEconomy():isResearchReadyToBuild(provinceNo) then
		self:download(provinceNo);
		self:parse();
		return true;
	end
end

function _HarvestResearch:getResearchPrices(researchName)
	if self:execute() then
		return self.researchPrices[researchName];
	end
end

function _HarvestResearch:dump()
	self:execute(8);
	table.foreach(self.researchPrices, function(researchName, prices)
		self:log_info(researchName.." "..prices.Wood.." wood, "..prices.Iron.." iron, "..prices.Stone.." stone, "..prices.Gold.." gold");
	end);
end

function HarvestResearch()
	_HarvestResearch=_HarvestResearch:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestResearch;
end
