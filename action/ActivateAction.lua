require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_ActivateAction = Class
{
	type="ActivateAction",
	URI_ACTIVATE="/imperia/game/allconstructions.php?auto=1"
};

function _ActivateAction:execute()
	self:log_debug("Check if building or research ready");
	HarvestEconomy():execute();
	if HarvestEconomy():isBuildingOrResearchReady() then
		self:log_info("Activate building and researches");
		HttpBrowser():browse(_ActivateAction.URI_ACTIVATE);
		table.foreachi(HarvestEconomy():getBuildingProgress(), function(_, buildProgressInfo)
			if type(buildProgressInfo.time) == "boolean" then
				self:log_info("Pr. #"..buildProgressInfo.province.." "..buildProgressInfo.buildingName.." activated.");
			end			
		end);
		table.foreachi(HarvestEconomy():getResearchProgress(), function(_, researchProgressInfo)
			if type(researchProgressInfo.time) == "boolean" then
				self:log_info(researchProgressInfo.researchName.." activated.");
			end
		end);
		HarvestEconomy():execute();
	end
end

function ActivateAction()
	return _ActivateAction:inherit(AbstractAction(), LoggingClass());
end
