require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestEnemyMove=Class
{
	type="HarvestEnemyMove",
	URI_ENEMY_MOVE="/imperia/game/vraglist.php?log=no",
};

function _HarvestEnemyMove:download()
	self.data=HttpBrowser():get(_HarvestEnemyMove.URI_ENEMY_MOVE);
	--FileUtil():writeAll("enemymove.html", self.data);
end

function _HarvestEnemyMove:parse()
	self.enemies={};
	local pattern="Провинция (%d+)</td><td align=\"center\" class=\"tip2\">(.-) %- %((%d+)%).-escape%('(.-)'%)\">.-CountTime%('timer_move%d+'%,(%d+)%);";
	string.gsub(self.data, pattern, function(fromProvince, enemy, toProvince, textArmy, time)
		local army={};
		table.foreach(_Items.ARMIES, function(unitEn, unitBg)
			string.gsub(textArmy, unitBg.." %- (%d+)", function(count)
				army[unitEn]=count;
			end);
		end);
		table.insert(self.enemies, {name=enemy, province=tonumber(fromProvince), tprovince=tonumber(toProvince), army=army, time=tonumber(time)});
	end);
end

function _HarvestEnemyMove:execute(province)
	self:log_debug("harvesting");
	self:download(province);
	self:parse();
end

function _HarvestEnemyMove:getEnemies()
	return self.enemies;
end

function _HarvestEnemyMove:dump()
	self:log_debug("enemies:");
	table.foreachi(self.enemies, function(_, enemy)
		self:log_debug(enemy.name.." is attacking from province "..enemy.province.." to province "..enemy.tprovince.." with army "..StringUtil():tableToString(enemy.army));
	end);
end

function HarvestEnemyMove()
	_HarvestEnemyMove=_HarvestEnemyMove:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestEnemyMove;
end
