require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestFriendMove=Class
{
	type="HarvestFriendMove",
	URI_FRIEND_MOVE="/imperia/game/movelist.php?log=no",
};

function _HarvestFriendMove:download()
	self.data=HttpBrowser():get(_HarvestFriendMove.URI_FRIEND_MOVE);
	--FileUtil():writeAll("friendmove.html", self.data);
end

function _HarvestFriendMove:parse()
	self.friends={};
	self.victoryFriends={};
	local fromProvince, enemy, toProvince, time;
	local pattern="Провинция (%d+)</td><td align=\"center\" class=\"tip2\">(.-) %- %((%d+)%).-escape%('(.-)'%)\">.-CountTime%('timer_move%d+'%,(%d+)%);(.-)movelist.php%?back=(%d+)'>Връщане";
	local pattern2="Провинция (%d+)</td><td align=\"center\" class=\"tip2\">(.-) %- %((%d+)%).-escape%('(.-)'%)\">.-CountTime%('timer_move%d+'%,(%d+)%);";
	string.gsub(self.data, pattern, function(fromProvince, enemy, toProvince, armyText, time, remainingText, id)
		fromProvince, enemy, toProvince, time = fromProvince, enemy, toProvince, time;

		string.gsub(armyText, "Злато %- (%d+)", function(_gold)
			if tonumber(_gold)>0 then
				table.insert(self.victoryFriends, {enemy=enemy, province=tonumber(fromProvince), tprovince=tonumber(toProvince), time=tonumber(time), gold=tonumber(_gold)});
			end
		end);

		string.gsub(remainingText, pattern2, function(_fromProvince, _enemy, _toProvince, _armyText, _time)
			fromProvince, enemy, toProvince, time=_fromProvince, _enemy, _toProvince, _time;

			string.gsub(_armyText, "Злато %- (%d+)", function(_gold)
				if tonumber(_gold)>0 then
					table.insert(self.victoryFriends, {enemy=enemy, province=tonumber(fromProvince), tprovince=tonumber(toProvince), time=tonumber(time), gold=tonumber(_gold)});
				end
			end);
		end);

		table.insert(self.friends, {enemy=enemy, province=tonumber(fromProvince), tprovince=tonumber(toProvince), time=tonumber(time), id=id});

	end);
	local armyText="";
	string.gsub(self.data, pattern2, function(_fromProvince, _enemy, _toProvince, _armyText, _time)
		fromProvince, enemy, toProvince, time, armyText=_fromProvince, _enemy, _toProvince, _time, _armyText;
	end);

	string.gsub(armyText, "Злато %- (%d+)", function(_gold)
		if tonumber(_gold)>0 then
			table.insert(self.victoryFriends, {enemy=enemy, province=tonumber(fromProvince), tprovince=tonumber(toProvince), time=tonumber(time), gold=tonumber(_gold)});
		end
	end);
end

function _HarvestFriendMove:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
end

function _HarvestFriendMove:getFriends()
	return self.friends;
end

function _HarvestFriendMove:getVictoryFriends()
	return self.victoryFriends;
end

function _HarvestFriendMove:isAttacking(user, province)
	return table.foreachi(self.friends, function(_, friend)
		if friend.enemy == user and friend.tprovince == province then
			return true;
		end
	end);
end

function _HarvestFriendMove:dump()
	self:log_debug("friends:");
	table.foreachi(self.friends, function(_, friend)
		self:log_debug("We are attacking "..friend.enemy.." from province "..friend.province.." to province "..friend.tprovince);
	end);
end

function HarvestFriendMove()
	_HarvestFriendMove=_HarvestFriendMove:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestFriendMove;
end
