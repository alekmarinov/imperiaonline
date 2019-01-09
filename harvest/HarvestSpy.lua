require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestSpy=Class
{
	type="HarvestSpy",
	URI_SPY="/imperia/game/spyrlist.php?log=no",
};

function _HarvestSpy:download()
	self.data=HttpBrowser():get(_HarvestSpy.URI_SPY);
	--FileUtil():writeAll("spy.html", self.data);
end

function _HarvestSpy:parse()
	self.readySpies={};
	self.insertedSpies={};

	local pattern="<TR  bgcolor=\"#A3947D\" height=\"30\"><td align=\"center\" class=\"tip1\">(.-)</td><td align=\"center\" class=\"tip2\">No%.(%d+)</td><td align=\"center\" class=\"tip2\">%d+ ниво</td>(.-)spy_id=(%d+)'";
	string.gsub(self.data, pattern, function(name, province, text, spyID)
		if string.find(text, "Внедряване", 1, true) then
			table.insert(self.readySpies, {name=name, province=tonumber(province), id=tonumber(spyID)});
		else
			table.insert(self.insertedSpies, {name=name, province=tonumber(province), id=tonumber(spyID)});
		end
	end);
end

function _HarvestSpy:execute()
	self:log_debug("harvesting");
	self:download(province);
	self:parse();
end

function _HarvestSpy:getInsertedSpies(name, province)
	local insertedSpies={};
	table.foreachi(self.insertedSpies, function(_, spy)
		if spy.name == name and spy.province == province then
			table.insert(insertedSpies, spy);
		end
	end);
	return insertedSpies;
end

function _HarvestSpy:getReadySpies(name, province)
	local readySpies={};
	table.foreachi(self.readySpies, function(_, spy)
		if spy.name == name and spy.province == province then
			table.insert(readySpies, spy);
		end
	end);
	return readySpies;
end

function _HarvestSpy:dump()
end

function HarvestSpy()
	_HarvestSpy=_HarvestSpy:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestSpy;
end
