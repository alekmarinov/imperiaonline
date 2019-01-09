require ("util.Class");

_AbstractAction = Class
{
	type="AbstractAction"
};

function _AbstractAction:execute()
	self:abstract("execute");
end

function AbstractAction()
	return _AbstractAction:clone();
end

