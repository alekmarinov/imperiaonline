require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");
require("imperiaonline.logic.Items");

_HarvestRumors=Class
{
	type="HarvestRumors",
	URI_SPYING="/imperia/game/spy.php?sname=",
	URI_RUMORS="/imperia/game/spy.php?sluhtene=1&d_username=%s&province_number=%d&d_id=%d"
};

function _HarvestRumors:download(target, province)
	local data=HttpBrowser():get(_HarvestRumors.URI_SPYING..target.name);

	local pattern="> (%d+)  .- align='right'>(%d+)</td><td class='tip1' align='left'>(.-)</td>";
	self.provinces={};
	string.gsub(data, pattern, function (no, people, terrain)
		table.insert(self.provinces, {no=no, people=people, terrain=terrain});
	end);

	if province then
		local pattern="spy%.php%?shpionirane=1&d_username=.-&province_number="..province.."&d_id=(%d+)";
		local id;
		string.gsub(data, pattern, function(_id)
			id=tonumber(_id);
		end);

		self.data=HttpBrowser():get(string.format(_HarvestRumors.URI_RUMORS, target.name, province, id));
	else
		self.data=nil;
	end
end

function _HarvestRumors:parse()
	if self.data then
		local patternGold="Вражеската провинция разполага с богатство на стойност около (%d+) злато";
		local patternArmy="Вражеската провинция разполага с приблизително (%d+) обикновенни войници, с (%d+) тежки войници и с (%d+) елитни войници";
		string.gsub(self.data, patternGold, function(gold)
			self.gold=tonumber(gold);
		end);
		string.gsub(self.data, patternArmy, function(normal, heavy, elite)
			self.normal=tonumber(normal);
			self.heavy=tonumber(heavy);
			self.elite=tonumber(elite);
		end);
	end
end

function _HarvestRumors:execute(target, province)
	self:log_debug("harvesting");
	self:download(target, province);
	self:parse();
	self.isExecuted=true;
end

function _HarvestRumors:getGold()
	return self.gold;
end

function _HarvestRumors:getNormalArmy()
	return self.normal;
end

function _HarvestRumors:getHeavyArmy()
	return self.heavy;
end

function _HarvestRumors:getEliteArmy()
	return self.elite;
end

function _HarvestRumors:getProvinces()
	return self.provinces;
end

function _HarvestRumors:hasArmy()
	if self.elite == 0 and self.heavy == 0 and self.normal == 0 then
		return false;
	end
	return true;
end

function _HarvestRumors:dump()
end

function HarvestRumors()
	_HarvestRumors=_HarvestRumors:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestRumors;
end
