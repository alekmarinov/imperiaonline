require("imperiaonline.action.AbstractAction");
require("imperiaonline.harvest.HarvestTransport");
require("logger.LoggingClass");

_TransportUnloadAction = Class
{
	type="TransportUnloadAction",
	URI_TRANSPORT_UNLOAD="/imperia/game/ready.php?tip=transport",
};

function _TransportUnloadAction:execute()
	if HarvestTransport():canUnload() then
		self:log_info("Unload cargo");
		if HttpBrowser():browse(_TransportUnloadAction.URI_TRANSPORT_UNLOAD) then
			return true;
		end
	end
end

function TransportUnloadAction()
	return _TransportUnloadAction:inherit(AbstractAction(), LoggingClass());
end
