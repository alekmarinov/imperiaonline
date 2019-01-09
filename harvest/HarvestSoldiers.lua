require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestSoldiers=Class
{
	type="HarvestSoldiers",
	URI_TRAIN_SOLDIERS="/imperia/game/soldiers.php?pr_nomer=",
	CODES={
		P1="Spearman",
		S1="Archer",
		M1="Swordsman",
		K1="Light cavalryman",
		C1="Battering ram",
		P2="Heavy Spearman",
		S2="Heavy Archer",
		M2="Heavy Swordsman",
		K2="Heavy cavalryman",
		C2="Catapult",
		P3="Phalanx",
		S3="Elite archer",
		M3="Guardian",
		K3="Paladin",
		C3="Trebuchet"
	}
};

function _HarvestSoldiers:download(province)
	self.data=HttpBrowser():get(_HarvestSoldiers.URI_TRAIN_SOLDIERS..province);
	--FileUtil():writeAll("soldiers_"..province..".html", self.data);
end

function _HarvestSoldiers:parse()
	self.trainingSpaces={};
	table.foreach(_HarvestSoldiers.CODES, function(code, unitName)
		local pattern="soldiers.php%?vid="..code.."\">Свободни места %- (%d+) &nbsp;&nbsp;&nbsp;Общо места %- (%d+) <BR>Свободни випуски %- (%d+)&nbsp;&nbsp;&nbsp;Общо випуски %- (%d+) <BR>";
		string.gsub(self.data, pattern, function(spaceFree, spaceTotal, groupsFree, groupsTotal)
			self.trainingSpaces[unitName]={
				spaceFree=tonumber(spaceFree), spaceTotal=tonumber(spaceTotal), groupsFree=tonumber(groupsFree), groupsTotal=tonumber(groupsTotal)
			}
		end);
	end);
end

function _HarvestSoldiers:execute(province)
	self:log_debug("harvesting");
	self:download(province);
	self:parse();
end

function _HarvestSoldiers:getFreeSpace(unitName)
	return self.trainingSpaces[unitName] and self.trainingSpaces[unitName].spaceFree or 0;
end

function _HarvestSoldiers:getFreeGroups(unitName)
	return self.trainingSpaces[unitName] and self.trainingSpaces[unitName].groupsFree or 0;
end

function _HarvestSoldiers:dump()
	self:log_debug("Free training spaces");
	self:log_debug("------------");
	table.foreach(self.trainingSpaces, function(unitName, spaces)
		self:log_info(unitName.." - "..spaces.spaceFree..", "..spaces.spaceTotal..", "..spaces.groupsFree..", "..spaces.groupsTotal);
	end);
end

function HarvestSoldiers()
	_HarvestSoldiers=_HarvestSoldiers:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestSoldiers;
end
