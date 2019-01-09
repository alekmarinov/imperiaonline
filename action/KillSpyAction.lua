require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_KillSpyAction = Class
{
	type="KillSpyAction",
	URI_SPY="/imperia/game/kspy.php?log=no",
	URI_KILLSPY="/imperia/game/kspy.php?spy_id="
};

function _KillSpyAction:execute(spies)
	HttpBrowser():browse(_KillSpyAction.URI_SPY);
	table.foreachi(spies, function(_, spy)
		HttpBrowser():browse(_KillSpyAction.URI_KILLSPY..spy.id);
		self:log_info("Spy in province #"..spy.province.." of "..(spy.enemy or "unknown").." is already dead");
	end);
end

function KillSpyAction()
	return _KillSpyAction:inherit(AbstractAction(), LoggingClass());
end
