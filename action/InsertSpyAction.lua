require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_InsertSpyAction = Class
{
	type="InsertSpyAction",
	URI_INSERT_SPY="/imperia/game/spyrlist.php?inject=spy&spy_id="
};

function _InsertSpyAction:execute(spy)
	self:log_info("Insert spy to "..spy.name.."("..spy.province..")");
	HttpBrowser():browse(_InsertSpyAction.URI_INSERT_SPY..spy.id);
end

function InsertSpyAction()
	return _InsertSpyAction:inherit(AbstractAction(), LoggingClass());
end
