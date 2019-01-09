require("util.Date");
require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestUsers=Class
{
	type="HarvestUsers",
	URI_SEARCH_USERS="/imperia/game/stats_players.php?range=1&SORT=DISTANCE",
};

function _HarvestUsers:download(username)
	self.data=HttpBrowser():get(_HarvestUsers.URI_SEARCH_USERS);
end

function _HarvestUsers:parse()
	self.users={};
	local pattern="return escape%('(.-)'%).-stats_players%.php%?d_id=(%d+)&d_logoname=(.-)&start=.-</font></a> </td><td class=\"tip1\" align=\"left\"><a class=\"dark\" href=\"stats_suiuzi%.php%?d_id=(%d+)\">(.-) </a></td><td class='tip1'   align='right'>(%d+)</td><td class='tip1'  align='right'>(%d+)";
	string.gsub(self.data, pattern, function (statText, uid, uname, aid, aname, distance, score)
		local date=Date();
		string.gsub(statText, "Последна активност %- (%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)<BR>", function(year, month, day, hour, minute, second)
			date:setCustomDate(year.." "..month.." "..day.." "..hour.." "..minute.." "..second.." 0");
		end);
		table.insert(self.users, 
		{
			lastActive=date,
			alienceID=tonumber(aid), 
			alience=aname, 
			distance=tonumber(distance), 
			score=tonumber(score), 
			honor=tonumber(honor),
			name=uname
		});
	end);
end

function _HarvestUsers:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
end

function _HarvestUsers:getUsers()
	return self.users;
end

function _HarvestUsers:dump()
end

function HarvestUsers()
	_HarvestUsers=_HarvestUsers:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestUsers;
end
