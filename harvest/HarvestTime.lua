require("util.FileUtil");
require("util.Date");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestTime=Class
{
	type="HarvestTime"
};

function _HarvestTime:download()
end

function _HarvestTime:parse()
	self.date=Date();
end

function _HarvestTime:execute(province)
	self:log_debug("harvesting");
	self:download(province);
	self:parse();
end

function _HarvestTime:getTime()
	self:execute();
	return self.date;
end

function _HarvestTime:dump()
	self:log_debug("Current Time:"..self.date:toString());
end

function HarvestTime()
	_HarvestTime=_HarvestTime:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestTime;
end
