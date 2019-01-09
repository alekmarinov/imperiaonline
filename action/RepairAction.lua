require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_RepairAction = Class
{
	type="RepairAction",
	URI_REPAIR="/imperia/game/constructions.php?tip=c",
};

function _RepairAction:execute(params)
	self:log_info("Repair fortress in province "..params.province);
	Action():go("Province", params);
	local postdata="repair=%%CF%%EE%%EF%%F0%%E0%%E2%%FF%%ED%%E5+%%ED%%E0+%%EA%%F0%%E5%%EF%%EE%%F1%%F2%%E0";
	local result, code, headers, status=HttpBrowser():post(_RepairAction.URI_REPAIR, postdata, 
		HttpBrowser():getHeaders
		{
			["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/constructions.php?tip=c",
		}
	);
end

function RepairAction()
	return _RepairAction:inherit(AbstractAction(), LoggingClass());
end
