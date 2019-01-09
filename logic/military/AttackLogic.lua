require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");

_AttackLogic=Class
{
	type="AttackLogic",
	SECS_BEFORE_RETURN=60*60+20*60, -- 1:20h before the enemy
	ACTIVE_TIME_BEFORE_RETURN=30*60
};

function _AttackLogic:returnArmy(friend)
	Action():go("ReturnArmy", friend);
end

function _AttackLogic:execute()
	HarvestProvinces():execute();
	local province=HarvestProvinces():getStrongestProvinces()[1];
	local now=HarvestTime():getTime();

	HarvestFriendMove():execute();

	local friends=HarvestFriendMove():getFriends();
	local victoryFriends=HarvestFriendMove():getVictoryFriends();

	if table.getn(HarvestFriendMove():getFriends())>0 then
		local enemyNames="";
		local friendNames="";

		table.foreachi(friends, function(_, friend)
			if MilitaryManager():isFriend(friend.enemy) then
				if string.len(friendNames)>0 then
					friendNames=friendNames..",";
				end
				friendNames=friendNames..friend.enemy.."("..friend.tprovince..")";
			else
				if string.len(enemyNames)>0 then
					enemyNames=enemyNames..",";
				end
				enemyNames=enemyNames..friend.enemy.."("..friend.tprovince..")";
			end
		end);

		if string.len(enemyNames)>0 then
			self:log_info("We are attacking enemies "..enemyNames);
		end

		if string.len(friendNames)>0 then
			self:log_info("We are attacking friends "..friendNames);
		end

		table.foreachi(friends, function(i, friend)
			if not MilitaryManager():isFriend(friend.enemy) then -- do not check if friendly targets

				-- check if there are conditions to be satisfied
				local target=MilitaryManager():getAttackTarget(friend.enemy, friend.tprovince);
				if target then
					-- we have such defined target
					local ok, result=SelectTargetLogic():investigateTarget(province, target);
					if not ok then
						if result == _SelectTargetLogic.INVESTIGATE_RESULT_DEFENSE_CHANGED 
						or result == _SelectTargetLogic.INVESTIGATE_RESULT_TARGET_ONLINE then
							-- return target
							self:returnArmy(friend);
							return false;
						end
					end
				end
				if friend.time<_AttackLogic.SECS_BEFORE_RETURN then
					self:log_info("Approaching "..friend.enemy.."("..friend.tprovince..")! "..DateUtil():formatTime(friend.time).."h until the strike");
					HarvestUser():execute(friend.enemy);
					local enemy=HarvestUser():getUser();
					local timeActiveReturn=now:clone();
					timeActiveReturn:subSeconds(_AttackLogic.ACTIVE_TIME_BEFORE_RETURN);
					if enemy.lastActive:compare(timeActiveReturn)>=0 then
						self:log_info("This sucker "..friend.enemy.." has logged in!!! Returning army...");
						self:returnArmy(friend);
					end
				end
			end
		end);
	end
	if table.getn(victoryFriends)>0 then
		self:log_info("Our glorious armies are returning from the battle with victory");
		local goldTotal=0;
		table.foreachi(victoryFriends, function(_, friend)
			self:log_info("From "..friend.enemy.." ("..friend.tprovince..") we are bringing "..friend.gold.." gold");
			goldTotal=goldTotal+friend.gold;
		end);
		if table.getn(victoryFriends)>1 then
			self:log_info("The total gold from all battles is "..goldTotal);
		end
	end
end

function AttackLogic()
	if not _AttackLogic.initialized then
		_AttackLogic=_AttackLogic:inherit(LoggingClass());
		_AttackLogic.initialized=true;
	end
	return _AttackLogic;
end
