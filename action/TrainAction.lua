require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("imperiaonline.harvest.HarvestWorkers");
require("logger.LoggingClass");

_TrainAction = Class
{
	type="TrainAction",
	URI_TRAIN_POST="/imperia/game/soldiers.php?vid=",
	CODES=
	{
		["Spearman"]="P1",
		["Archer"]="S1",
		["Swordsman"]="M1",
		["Light cavalryman"]="K1",
		["Battering ram"]="C1",
		["Heavy spearman"]="P2",
		["Heavy archer"]="S2",
		["Heavy swordsman"]="M2",
		["Heavy cavalryman"]="K2",
		["Catapult"]="C2",
		["Phalanx"]="P3",
		["Elite archer"]="S3",
		["Guardian"]="M3",
		["Paladin"]="K3",
		["Trebuchet"]="C3"
	}
};

function _TrainAction:execute(param)
	local count=0;
	HarvestSoldiers():execute(param.province);

	local freeSpace=HarvestSoldiers():getFreeSpace(param.itemName);
	local freeGroups=HarvestSoldiers():getFreeGroups(param.itemName);

	if freeGroups>0 then
		if freeSpace>0 then

			count=math.min(param.count, freeSpace);
			HarvestTrainings():execute(param.province);
			local unitsBeforeTrain=HarvestTrainings():getTrainingUnitsNumber(param.itemName);

			-- get out enough people from the workshops to become soldiers
			Action():go("Work", {province=param.province, out=param.count});

			self:log_info("Pr. #"..param.province..": train "..count.." of "..param.count.." "..param.itemName.."s");
			local postdata="broika="..count.."&in=%%CD%%E0%%E5%%EC%%E0%%ED%%E5";
			local id=_TrainAction.CODES[param.itemName];
			local result, code, headers, status=HttpBrowser():post(_TrainAction.URI_TRAIN_POST..id, postdata, 
				HttpBrowser():getHeaders
				{
					["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/soldiers.php?status=training",
				}
			);

			HarvestTrainings():execute(param.province);
			local unitsAfterTrain=HarvestTrainings():getTrainingUnitsNumber(param.itemName);

			if unitsAfterTrain>unitsBeforeTrain then
				self:log_info("Training "..count.." "..param.itemName.." in province "..param.province.." successfully started");
			end
			return count;
		else
			self:log_warn("No space in barracks to train "..param.itemName.." in province "..param.province);
		end

	else
		self:log_warn("Not enough free groups to train "..param.itemName.." in province "..param.province);
	end
end

function TrainAction()
	return _TrainAction:inherit(AbstractAction(), LoggingClass());
end
