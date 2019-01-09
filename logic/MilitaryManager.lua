require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.Items");

_MilitaryManager=Class
{
	type="MilitaryManager"
};

function _MilitaryManager:loadConfigFile(configFile)
	if FileUtil():fileExists(configFile) then
		self:log_info("Load "..configFile);
		local friends={};
		local allies={};
		local cover="";
		local attackList={};
		local fortresses={};
		local inside=false;
		local target;
		for line in io.lines(configFile) do
			line = StringUtil():trim(line);
			if string.len(line)>0 and not StringUtil():starts(line, "--") then
				if not inside and StringUtil():starts(line, "cover in") then
					string.gsub(line, "cover in (.*)", function(coverIn)
						cover=StringUtil():trim(coverIn);
					end);
				elseif not inside and StringUtil():starts(line, "friendly users") then
					string.gsub(line, "friendly users (.*)", function(textFriends)
						textFriends=","..textFriends..",";
						string.gsub(textFriends, ",(.-),", function(friend)
							table.insert(friends, friend);
						end);
					end);
				elseif not inside and StringUtil():starts(line, "friendly allies") then
					string.gsub(line, "friendly allies (.*)", function(textAllies)
						textAllies=","..textAllies..",";
						string.gsub(textAllies, ",(.-),", function(ally)
							table.insert(allies, ally);
						end);
					end);
				elseif not inside and line == "{" then
					inside=true;
					target={
						friendArmy={},
						enemyArmy={},
						Fortresses=0,
						offline=0,
						gold=0
					};
				elseif inside and line == "}" then
					inside=false;
					if target then
						if target.enemy then
							-- concrete enemy  definition
							table.insert(attackList, target);
						else
							-- fortress definition
							fortresses[target.Fortresses]=fortresses[target.Fortresses] or {};
							table.insert(fortresses[target.Fortresses], target);
						end
					end
					target=nil;
				elseif inside then
					if StringUtil():starts(line, "enemy") then
						string.gsub(line, "enemy (.-) %((%d+)%)", function(enemy, province)
							target.enemy=enemy;
							target.province=tonumber(province);
						end);
					elseif StringUtil():starts(line, "time") then
						string.gsub(line, "time (.*)", function(txtTime)
							local h, m;
							string.gsub(txtTime, "(%d+)%:(%d+)", function(_h, _m)
								h, m = _h, _m;
							end);
							target.time={h=tonumber(h), m=tonumber(m)};
						end);
					elseif StringUtil():starts(line, "offline") then
						string.gsub(line, "offline (.*)", function(offline)
							target.offline=tonumber(offline);
						end);
					elseif StringUtil():starts(line, "gold") then
						string.gsub(line, "gold (%d+)", function(gold)
							target.gold=tonumber(gold);
						end);
					elseif StringUtil():starts(line, "Fortresses") then
						string.gsub(line, "Fortresses (%d+)", function(Fortresses)
							target.Fortresses=tonumber(Fortresses);
						end);
					else
						table.foreach(_Items.ARMY, function(unitName)
							if StringUtil():starts(line, ">"..unitName) then
								string.gsub(line, "(%d+)", function(amount)
									target.friendArmy[unitName]=tonumber(amount);
								end);
							elseif StringUtil():starts(line, "<"..unitName) then
								string.gsub(line, "(%d+) (%d+)", function(amountOut, amountIn)
									target.enemyArmy[unitName]={tonumber(amountOut), tonumber(amountIn)};
								end);
							end
						end);
					end
				end
			end
		end
		return true, attackList, friends, allies, cover, fortresses;
	else
		self:log_info("Cannot find file "..configFile);
		return {}, {}, "", nil;
	end
end

function _MilitaryManager:load()
	local ok;
	ok, self.attackList, self.friends, self.allies, self.cover, self.fortresses=self:loadConfigFile(self.fightConfigFile);
	if ok then
		local nFriends=table.getn(self.friends);
		local nTargets=table.getn(self.attackList);
		if nFriends>0 then
			self:log_info(nFriends.." loaded friend(s)");
		else
			self:log_info("No defined friends");
		end
		if nTargets>0 then
			self:log_info(nTargets.." loaded target(s)");
		else
			self:log_info("No defined targets");
	
		end
	else
		self:save();
	end
end

function _MilitaryManager:save()
	FileUtil():writeAll(self.fightConfigFile, 
[[--cover in USER
--friends USER,USER,...
-- Elite archer
-- Spearman
-- Trebuchet
-- Heavy cavalryman
-- Swordsman
-- Paladin
-- Heavy archer
-- Phalanx
-- Archer
-- Guardian
-- Light cavalryman
-- Battering ram
-- Heavy swordsman
-- Catapult
-- Heavy spearman
-- 
--{
-- 	>Spearman 0
-- 	>Heavy spearman 0
-- 	>Phalanx 0
-- 	>Archer 0
-- 	>Heavy archer 0
-- 	>Elite archer 0
-- 	>Swordsman 0
--	>Heavy swordsman 0
--	>Guardian 0
--	>Light cavalryman 0
--	>Heavy cavalryman 0
--	>Paladin 0
--	>Battering ram 0
--	>Catapult 0
--	>Trebuchet 0
--
--	Fortresses LEVEL
--	<Spearman 0 0
--	<Heavy spearman 0 0
--	<Phalanx 0 0
--	<Archer 0 0
--	<Heavy archer 0 0
--	<Elite archer 0 0
--	<Swordsman 0 0
--	<Heavy swordsman 0 0
--	<Guardian 0 0
--	<Light cavalryman 0 0
--	<Heavy cavalryman 0 0
--	<Paladin 0 0
--}
]]);
end

function _MilitaryManager:initialize(fightConfigFile)
	self.fightConfigFile=fightConfigFile;
	self:load();
end

function _MilitaryManager:finalize()
end

function _MilitaryManager:isFriend(username, ally)
	if table.foreachi(self.friends, function(_, friend)
		if friend == username then
			return true;
		end
	end) then
		return true;
	else
		-- check if a part of friendly ally
		if ally then
			return table.foreachi(self.allies, function(_, a)
				if ally == a then
					return true;
				end
			end);
		end
	end
end

function _MilitaryManager:getCoverUser()
	return self.cover;
end

function _MilitaryManager:getAttackList()
	return self.attackList;
end

function _MilitaryManager:getAttackTarget(user, province)
	return table.foreachi(self.attackList, function(_, target)
		if target.enemy==user and target.province==province then
			return target;
		end
	end);
end

function _MilitaryManager:addAttackTarget(target)
	-- add the target if we don't have already this target
	if not table.foreachi(self.attackList, function(_, _target)
		if _target.enemy == target.enemy and _target.province == target.province then
			return true;
		end
	end) then
		table.insert(self.attackList, target);
	end
end

function _MilitaryManager:getArmyForFortress(ourArmy, fortress)
	if self.fortresses[fortress] then
		return table.foreachi(self.fortresses[fortress], function(_, target)
			if not table.foreach(target.friendArmy, function(unitName, amount)
				if ourArmy[unitName]<amount then
					return true;
				end
			end) then
				-- there is enough army to attack the specified fortress
				local army={};
				-- clone the defined army
				table.foreach(target.friendArmy, function(unitName, amount)
					army[unitName]=amount;
				end);
				return army;
			end
		end);
	end
end

function MilitaryManager()
	if not _MilitaryManager.initialized then
		_MilitaryManager=_MilitaryManager:inherit(LoggingClass());
		_MilitaryManager.initialized=true;
	end
	return _MilitaryManager;
end
