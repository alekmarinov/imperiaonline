require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_SendSpyAction = Class
{
	type="SendSpyAction",
	URI_SPYING="/imperia/game/spy.php?sname=",
	URI_SEND_SPY="/imperia/game/spy.php?shpionirane=1&d_username=%s&province_number=%d&d_id=%d"
};

function _SendSpyAction:execute(spy)
	self:log_info("Sending spy to "..spy.name.."("..spy.province..")");
	local data=HttpBrowser():get(_SendSpyAction.URI_SPYING..spy.name);
	local pattern="spy%.php%?shpionirane=1&d_username=.-&province_number="..spy.province.."&d_id=(%d+)";
	local id;
	string.gsub(data, pattern, function(spyID)
		id=tonumber(spyID);
	end);
	HttpBrowser():browse(string.format(_SendSpyAction.URI_SEND_SPY, spy.name, spy.province, id));
end

function SendSpyAction()
	return _SendSpyAction:inherit(AbstractAction(), LoggingClass());
end
