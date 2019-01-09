require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.MilitaryManager");
require("imperiaonline.logic.Items");

_SeekTargetsLogic=Class
{
	type="SeekTargetsLogic",
	RUMORS_COUNT_MIN=5;
	RUMORS_COUNT_MAX=8;
};

function _SeekTargetsLogic:getUserList()
	HarvestUsers():execute();
	HttpBrowser():storeSleepTime(0);
	local users={};
	table.foreachi(HarvestUsers():getUsers(), function(_, user)
		if not MilitaryManager():isFriend(user.name, user.alience) then	
			-- not a friend, then our potential target
			HarvestRumors():execute(user);
			table.foreachi(HarvestRumors():getProvinces(), function(_, province)
				-- loop through all target provinces
				HarvestRumors():execute(user, province.no);
				if not HarvestRumors():hasArmy() then
					self:log_info("Listening rumors about "..user.name.."("..user.alience..") in province "..province.no);
					-- no army, is there some gold?
					local i;
					local count=_SeekTargetsLogic.RUMORS_COUNT_MIN+math.random(_SeekTargetsLogic.RUMORS_COUNT_MAX-_SeekTargetsLogic.RUMORS_COUNT_MIN)-1;
					local gold=HarvestRumors():getGold();
					for i=1,count do
						HarvestRumors():execute(user, province.no);
						gold=gold+HarvestRumors():getGold();
					end
					gold=math.floor(gold/(count+1));

					self:log_info("User "..user.name.." has "..gold.." amount of gold in province "..province.no);
					table.insert(users, {
						enemy=user.name, province=province, gold=gold
					});
				else
					self:log_info("User "..user.name.." has army in province "..province.no);
				end
			end);
		end
	end);
	HttpBrowser():restoreSleepTime();
	return users;
end

-- start logic
function _SeekTargetsLogic:execute()
	self:log_info("Seeking for new targets");
	local users=self:getUserList();
	table.sort(users, function(a, b)
		if a.gold>b.gold then
			return true;
		end
	end);

	if users[1] then
		local user=users[1];
		self:log_info("Got "..table.getn(users).." targets. "..user.name.." ("..user.province..") is the reachest with "..user.gold.." gold");
		MilitaryManager():addAttackTarget(user);
	end
end

-- constructor
function SeekTargetsLogic()
	if not _SeekTargetsLogic.initialized then
		_SeekTargetsLogic=_SeekTargetsLogic:inherit(LoggingClass());
		_SeekTargetsLogic.initialized=true;
	end
	return _SeekTargetsLogic;
end
