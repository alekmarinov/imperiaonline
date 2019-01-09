require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");
require("imperiaonline.logic.Items");

_HarvestTrainings=Class
{
	type="HarvestTrainings",
	URI_TRAININGS="/imperia/game/trainings.php?pr_nomer=",
	
	PRICES=
	{
		["Spearman"]={15, 6, 6, 0.1},
		["Archer"]={15, 6, 8, 0.1},
		["Swordsman"]={30, 12, 12, 0.2},
		["Light cavalryman"]={60, 24, 18, 0.4},
		["Battering ram"]={1500, 600, 12, 10},
		["Heavy spearman"]={25, 10, 8, 0.15},
		["Heavy archer"]={25, 10, 10, 0.15},
		["Heavy swordsman"]={50, 20, 16, 0.3},
		["Heavy cavalryman"]={100, 40, 24, 0.6},
		["Catapult"]={2500, 1000, 18, 15},
		["Phalanx"]={50, 20, 12, 0.2},
		["Elite archer"]={50, 20, 14, 0.3},
		["Guardian"]={100, 40, 24, 0.4},
		["Paladin"]={200, 80, 36, 0.8},
		["Trebuchet"]={5000, 2000, 24, 20}
	}
};

function _HarvestTrainings:download(province)
	self.data=HttpBrowser():get(_HarvestTrainings.URI_TRAININGS..province);
	--FileUtil():writeAll("trainings_"..province..".html", self.data);
end

function _HarvestTrainings:parse()
	self.trainings={};
	table.foreach(_Items.ARMIES, function(unitNameEn, unitNameBg)
		local patternYes=unitNameBg.."(.-)tr_id=(%d+)";
		local patternNo="cancel.php";

		string.gsub(self.data, patternYes, function(midText, trID)
			local count;
			string.gsub(midText, ">(%d+)<", function(_count)
				if not count then
					count=_count;
				end
			end);
			if not string.find(midText, patternNo, 1, true) then
				table.insert(self.trainings, {
					unitName=unitNameEn, count=count, ready=true, id=trID
				});
			end
		end);

		patternYes=unitNameBg.."(.-)cancel.php";
		patternNo="tr_id=";
		string.gsub(self.data, patternYes, function(midText)
			local count;
			string.gsub(midText, ">(%d+)<", function(_count)
				if not count then
					count=_count;
				end
			end);
			if not string.find(midText, patternNo, 1, true) then
				table.insert(self.trainings, {
					unitName=unitNameEn, count=count, ready=false
				});
			end
		end);
	end);
end

function _HarvestTrainings:getTrainings()
	return self.trainings;
end

function _HarvestTrainings:getTrainingUnits(unitName)
	local trainingUnits={};

	table.foreachi(self.trainings, function(_, trainInfo)
		if trainInfo.unitName == unitName then
			table.insert(trainingUnits, {count=trainInfo.count, ready=trainInfo.ready, id=trainInfo.id});
		end
	end);

	return trainingUnits;
end

function _HarvestTrainings:getTrainingUnitsNumber(unitName)
	local count=0;
	table.foreachi(self.trainings, function(_, trainInfo)
		if trainInfo.unitName == unitName then
			count=count+trainInfo.count;
		end
	end);
	return count;
end

function _HarvestTrainings:getUnitPrices(unitName, count)
	return {
		[_Items.WOOD]=_HarvestTrainings.PRICES[unitName][1]*(count or 1),
		[_Items.IRON]=_HarvestTrainings.PRICES[unitName][2]*(count or 1),
		[_Items.STONE]=0,
		[_Items.GOLD]=0
	};
end

function _HarvestTrainings:execute(province)
	self:log_debug("harvesting");
	self:download(province);
	self:parse();
end

function _HarvestTrainings:dump()
	self:log_debug("Current trainings");
	self:log_debug("------------");
	table.foreachi(self.trainings, function(_, trainInfo)
		self:log_info(trainInfo.unitName.." - "..trainInfo.count..", "..(trainInfo.ready and "yes" or "no")..", "..(trainInfo.id or 0));
	end);
end

function HarvestTrainings()
	_HarvestTrainings=_HarvestTrainings:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestTrainings;
end
