require("imperiaonline.action.TransportUnloadAction");
require("imperiaonline.action.ReturnArmyAction");
require("imperiaonline.action.ArmyFortressAction");
require("imperiaonline.action.ArmyMovesAction");
require("imperiaonline.action.ConstructAction");
require("imperiaonline.action.InsertSpyAction");
require("imperiaonline.action.TransportAction");
require("imperiaonline.action.ProvinceAction");
require("imperiaonline.action.ActivateAction");
require("imperiaonline.action.SendSpyAction");
require("imperiaonline.action.KillSpyAction");
require("imperiaonline.action.RepairAction");
require("imperiaonline.action.AttackAction");
require("imperiaonline.action.TrainAction");
require("imperiaonline.action.TradeAction");
require("imperiaonline.action.BonusAction");
require("imperiaonline.action.WorkAction");

require("imperiaonline.action.TransportUnloadAction");
require("imperiaonline.action.TransportAction");
require("imperiaonline.action.ConstructAction");
require("imperiaonline.action.AbstractAction");
require("imperiaonline.action.ActivateAction");
require("imperiaonline.action.ProvinceAction");
require("imperiaonline.action.BonusAction");
require("imperiaonline.action.TradeAction");
require("imperiaonline.action.WorkAction");
_Action = Class
{
	type="Action",
};

function _Action:go(actionName, params)
	return _G[actionName.."Action"]():execute(params);
end

function Action()
	return _Action:clone();
end
