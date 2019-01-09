require("util.Date");
require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestUser=Class
{
	type="HarvestUser",
	URI_SEARCH_USER="/imperia/game/stats_players.php?start=0",
};

function _HarvestUser:download(username)
	local postdata="sname="..username;
	local result, code, headers, status=HttpBrowser():post(_HarvestUser.URI_SEARCH_USER, postdata, 
		HttpBrowser():getHeaders
		{
			["Referer"]="http://"..HttpBrowser():getHost().."/imperia/game/stats_players.php?range=1&SORT=DISTANCE",
		}
	);
	self.data=result;
end

function _HarvestUser:parse(username)
	self.user=nil;

	username=string.gsub(username, "%%", "%%%%");
	username=string.gsub(username, "%+", "%%+");
	username=string.gsub(username, "-", "%%-");
	username=string.gsub(username, "%.", "%%.");
	username=string.gsub(username, "%(", "%%(");
	username=string.gsub(username, "%)", "%%)");
	username=string.gsub(username, "%*", "%%*");

	local pattern="this%.T_WIDTH=230;return escape%('(.-)'%)\">.-stats_players.php%?d_id=%d+%&d_logoname="..username.."%&start=.-stats_suiuzi%.php%?d_id=(%d+)\">(.-) </a></td><td class='tip1'   align='right'>(%d+)</td><td class='tip1'  align='right'>(%d+)</td><td class='tip1'  align='right'>(%-?%d+)</td>";
	string.gsub(self.data, pattern, function(statText, alienceID, alience, distance, score, honor)
		local date=Date();
		string.gsub(statText, "Последна активност %- (%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)<BR>", function(year, month, day, hour, minute, second)
			date:setCustomDate(year.." "..month.." "..day.." "..hour.." "..minute.." "..second.." 0");
		end);
		self.user={
			lastActive=date,
			alienceID=tonumber(alienceID), 
			alience=alience, 
			distance=tonumber(distance), 
			score=tonumber(score), 
			honor=tonumber(honor)
		};
	end);
end

function _HarvestUser:execute(username)
	self:log_debug("harvesting");
	self:download(username);
	self:parse(username);
end

function _HarvestUser:getUser()
	return self.user;
end

function _HarvestUser:dump()
end

function HarvestUser()
	_HarvestUser=_HarvestUser:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestUser;
end
