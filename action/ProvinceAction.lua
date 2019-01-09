require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_ProvinceAction = Class
{
	type="ProvinceAction",
	URI_PROVINCE="/imperia/game/new.php?pr_nomer="
};

function _ProvinceAction:execute(param)
	self:log_debug("Go to #"..param.province);
	HttpBrowser():browse(_ProvinceAction.URI_PROVINCE..param.province);
end

function ProvinceAction()
	return _ProvinceAction:inherit(AbstractAction(), LoggingClass());
end
