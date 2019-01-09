require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("logger.LoggingClass");

_ReturnArmyAction = Class
{
	type="ReturnArmyAction",
	URI_RETURN_ARMY="/imperia/game/movelist.php?back="
};

function _ReturnArmyAction:execute(friend)
	HttpBrowser():browse(_ReturnArmyAction.URI_RETURN_ARMY..friend.id);
	self:log_info("Our army to "..friend.enemy.." is returning");
end

function ReturnArmyAction()
	return _ReturnArmyAction:inherit(AbstractAction(), LoggingClass());
end
