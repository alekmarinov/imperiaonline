require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestTransport=Class
{
	type="HarvestTransport",
	URI_TRANSPORT="/imperia/game/transport.php?log=no"
};

function _HarvestTransport:download()
	self.data=HttpBrowser():get(_HarvestTransport.URI_TRANSPORT);
	--FileUtil():writeAll("transport.html", self.data);
end

function _HarvestTransport:parse()
	self.transports={};
	string.gsub(self.data, "No%.(%d+).-No%.(%d+)", function (fromProvNo, toProvNo)
		table.insert(self.transports, {tonumber(fromProvNo), tonumber(toProvNo)});
	end);
end

function _HarvestTransport:canUnload()
	if not self.isExecuted then self:execute(); end
	if string.find(self.data, "ready.php?tip=transport", 1, 1) then
		return true;
	end
end

function _HarvestTransport:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
	self.isExecuted=true;
end


function _HarvestTransport:getTransports()
	if not self.isExecuted then self:execute(); end
	return self.transports;
end

function _HarvestTransport:isTransportFromProvince(province)
	return table.foreachi(self:getTransports(), function(_, transportInfo)
		if transportInfo[1] == province then
			return true;
		end
	end);
end

function _HarvestTransport:isTransportToProvince(province)
	return table.foreachi(self:getTransports(), function(_, transportInfo)
		if transportInfo[2] == province then
			return true;
		end
	end);
end

function _HarvestTransport:transportInProgress()
	if table.getn(self:getTransports())>0 then
		return true;
	end
end

-- Guess if transporting is initiated by LoadResources mission
function _HarvestTransport:isTransportLoadResources()
	local transports=self:getTransports();
	local toProvinces={};
	table.foreachi(transports, function(_, transportInfo)
		local toProvince=transportInfo[2];
		toProvinces[toProvince]=(toProvinces[toProvince] or 0) + 1;
	end);

	local provincesAmount=0;
	local differentProvinces=0;
	table.foreach(toProvinces, function(prNo, amount)
		provincesAmount=provincesAmount+amount;
		differentProvinces=differentProvinces+1;
	end);

	if provincesAmount == HarvestEconomy():getProvincesCount() and differentProvinces == 2 then
		return true;
	end
end

function _HarvestTransport:depotAvailable(province)
	if not self.isExecuted then self:execute(); end
	return not table.foreachi(self:getTransports(), function(_, transportInfo)
		return tonumber(transportInfo.province)==tonumber(province);
	end);
end

function _HarvestTransport:dump()
	if not self.isExecuted then self:execute(); end
	table.foreachi(self.transports, function(_, transportInfo)
		self:log_debug("Transport from province "..transportInfo.fromProv.." to province "..transportInfo.toProv);
	end);
end

function HarvestTransport()
	_HarvestTransport=_HarvestTransport:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestTransport;
end
