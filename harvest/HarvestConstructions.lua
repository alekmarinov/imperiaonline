require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.Items");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestConstructions=Class
{
	type="HarvestConstructions",
	URI_CONSTRUCTIONS="/imperia/game/constructions.php?tip=c&pr_nomer=",
	MARK_FORTRESS_BROKEN="Поправяне на крепоста"
};

function _HarvestConstructions:download(province)
	self.province=province;
	self.data=HttpBrowser():get(_HarvestConstructions.URI_CONSTRUCTIONS..province);
	--FileUtil():writeAll("constructions_"..province..".html", self.data);
end

function _HarvestConstructions:parse()
	self.buildingPrices={};
	self.repairResources={
		[_Items.WOOD]=0,
		[_Items.IRON]=0,
		[_Items.STONE]=0,
		[_Items.GOLD]=0
	};
	table.foreach(_Items.BUILDINGS, function(buildingEn, buildingBg)
		string.gsub(self.data, buildingBg..".-Дърво %- (%d+)<BR>Желязо %- (%d+)<BR>Камък %- (%d+)<BR>Злато %- (%d+)", function(wood, iron, stone, gold)
			self.buildingPrices[buildingEn]={
				Wood=tonumber(wood),
				Iron=tonumber(iron),
				Stone=tonumber(stone),
				Gold=tonumber(gold)
			};
		end);
	end);

	if string.find(self.data, _HarvestConstructions.MARK_FORTRESS_BROKEN, 1, true) then
		string.gsub(self.data, "(%d+) камък", function(stoneAmount)
			self.repairResources[_Items.STONE]=stoneAmount+1;
		end);
		self:log_debug("Detected broken fortress in province "..self.province);
		self.brokenFortress=true;
	else
		self.brokenFortress=false;
	end
end

if TEST then
	function _HarvestConstructions:download(provinceNo)
	end

	function _HarvestConstructions:parse()
		self.buildingPrices={
			["Farm"]={Wood=0, Iron=0, Stone=0, Gold=1000}
		};
	end
end

function _HarvestConstructions:execute(provinceNo)
	self:log_debug("harvesting constructions in province "..provinceNo);
	self:download(provinceNo);
	self:parse();
	return true;
end

function _HarvestConstructions:isBrokenFortress(provinceNo)
	if self:execute(provinceNo) then
		if self.brokenFortress then
			return true, self.repairResources;
		end
	end
end

function _HarvestConstructions:getBuildingPrices(provinceNo, constructionName)
	if self:execute(provinceNo) then
		return self.buildingPrices[constructionName];
	end
end

function _HarvestConstructions:dump()
	table.foreach(self.buildingPrices, function(buildingName, prices)
		self:log_debug(buildingName, prices.wood.." wood, "..prices.iron.." iron, "..prices.stone.." stone, "..prices.gold.." gold");
	end);
end

function HarvestConstructions()
	_HarvestConstructions=_HarvestConstructions:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestConstructions;
end
