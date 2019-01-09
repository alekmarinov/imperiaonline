require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");
require("imperiaonline.logic.Items");

_HarvestArmy=Class
{
	type="HarvestArmy",
	URI_ARMY="/imperia/game/allarmy.php?log=no"
};

function _HarvestArmy:download()
	self.data=HttpBrowser():get(_HarvestArmy.URI_ARMY);
	--FileUtil():writeAll("army.html", self.data);
end

function _HarvestArmy:parse()
	self.armies={};
	local pattern="Войски в провинция No%.(%d+)(.-)свободни места";
	string.gsub(self.data, pattern, function(province, textArmy)
		province=tonumber(province);
		self.armies[province]={};
		table.foreach(_Items.ARMIES, function(unitNameEn, unitNameBg)
			if unitNameEn == "Battering ram" or unitNameEn == "Catapult" or unitNameEn == "Trebuchet" then
				string.gsub(textArmy, "%>"..unitNameBg.."%<.-%>(%d+)%<", function(fieldArmy)
					self.armies[province][unitNameEn]={tonumber(fieldArmy), 0};
				end);
			else
				string.gsub(textArmy, "%>"..unitNameBg.."%<.-%>(%d+)%<.-%>(%d+)", function(fieldArmy, fortressArmy)
					self.armies[province][unitNameEn]={tonumber(fieldArmy), tonumber(fortressArmy)};
				end);
			end
		end);

		string.gsub(textArmy, "Гарнизон.-(%d+)%(максимален%)</TD><TD class=\"tip2\"  align=\"right\">(%d+)", function(maxAvailable, freeAvailable)
			self.armies[province][_Items.GARRISON]={tonumber(maxAvailable), tonumber(freeAvailable)};
		end);
	end);
end

function _HarvestArmy:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
	self.isExecuted=true;
end

function _HarvestArmy:getProvinceArmies(province)
	if self.armies[province] then
		return self.armies[province];
	else
		self:log_error("HarvestArmy:getProvinceArmies -> Province #"..(province or nil).." is invalid");
	end
end

function _HarvestArmy:dump()
	if not self.isExecuted then self:execute(); end
	table.foreach(self.armies, function(province, army)
		self:log_info("Armies in province #"..province);
		table.foreach(army, function(unitName, amounts)
			self:log_info(unitName.." "..amounts[1].." "..amounts[2]);
		end);
	end);
end

function HarvestArmy()
	_HarvestArmy=_HarvestArmy:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestArmy;
end
