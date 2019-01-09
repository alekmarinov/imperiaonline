require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.MilitaryManager");
require("imperiaonline.logic.Items");

_SelectTargetLogic=Class
{
	type="SelectTargetLogic",
	NOMINAL_RESOURCE_COEF={
		Wood=0.5,
		Iron=2.5,
		Stone=1,
		Gold=1
	},

	INVESTIGATE_RESULT_OUT_OF_SCORES="Out of scores",
	INVESTIGATE_RESULT_NO_INFORMATION="No information",
	INVESTIGATE_RESULT_DEFENSE_CHANGED="Defense configuration changed",
	INVESTIGATE_RESULT_GOLD_NOT_SATISFIED="Not enough gold in the province",
	INVESTIGATE_RESULT_TARGET_ONLINE="The target is online",
};

-- return all our army
function _SelectTargetLogic:getOurArmy()
	local army={};
	HarvestArmy():execute();
	HarvestEconomy():execute();
	table.foreachi(HarvestEconomy():getProvinceNumbers(), function(_, province)
		table.foreach(HarvestArmy():getProvinceArmies(province), function(unitName, amounts)
			if unitName ~= _Items.GARRISON then
				army[unitName]=(army[unitName] or 0) + (amounts[1] or 0) + (amounts[2] or 0);
			end
		end);
	end);
	return army;
end

-- return true if army1 covers army2
function _SelectTargetLogic:compareArmies(army1, army2)
	return not table.foreach(_Items.ARMY, function(unitName)
		if (army1[unitName] or 0)<(army2[unitName] or 0) then
			self:log_info(unitName.." "..(army1[unitName] or 0).." are less than expected "..(army2[unitName] or 0));
			return true;
		end
	end);
end

function _SelectTargetLogic:resourceToGold(resources)
	local gold=0;
	table.foreach(resources, function(resourceName, amount)
		gold=gold+amount*_SelectTargetLogic.NOMINAL_RESOURCE_COEF[resourceName];
	end);
	return gold;
end

-- return the target if satisfies the attack conditions by the target
function _SelectTargetLogic:investigateTarget(province, target)
	self:log_info("Investigating target "..target.enemy.."("..target.province..")");
	local now=HarvestTime():getTime();

	HarvestUser():execute(target.enemy);
	local enemy=HarvestUser():getUser();

	HarvestUser():execute(HttpSession():getUsername());
	local me=HarvestUser():getUser();

	-- check if enemy scores are in our range
	if enemy.score*2<me.score or enemy.score>me.score*2 then
		self:log_info("Enemy "..target.enemy.." is out of range of our scores. We have "..me.score.." scores but he have "..enemy.score);
		return false, _SelectTargetLogic.INVESTIGATE_RESULT_OUT_OF_SCORES;
	else	
		local timeOffline=now:clone();
		timeOffline:subSeconds(math.floor(60*60*target.offline));
		if enemy.lastActive:compare(timeOffline)<0 then
			-- the enemy is offline, check the remaining conditions
			if target.time and (target.time.h == now:getHour() and target.time.m >= now:getMinute()) then
				return true, 9999999;
			end

			HarvestSpy():execute();
			local insertedSpy=HarvestSpy():getInsertedSpies(target.enemy, target.province)[1];
			if not insertedSpy then
				-- no inserted spies, check if there is ready for insertion
				local readySpies=HarvestSpy():getReadySpies(target.enemy, target.province);
				while table.getn(readySpies)>0 do
					-- insert spy
					Action():go("InsertSpy", readySpies[1]);
					HarvestSpy():execute();
					insertedSpies=HarvestSpy():getInsertedSpies(target.enemy, target.province);
					if table.getn(insertedSpies) > 0 then
						-- ok, we inserted one
						insertedSpy=insertedSpies[1];
						break;
					end
					readySpies=HarvestSpy():getReadySpies(target.enemy, target.province);
				end
			end
			if not insertedSpy then
				-- send 3 spies to target
				self:log_info("Send spy to "..target.enemy.."("..target.province..")");
				target.name=target.enemy;
				FixGoldLogic():execute(province, 3*500);
				Action():go("SendSpy", target);
				Action():go("SendSpy", target);
				Action():go("SendSpy", target);
				return false, _SelectTargetLogic.INVESTIGATE_RESULT_NO_INFORMATION;
			else
				self:log_info("Check spy information for "..target.enemy.."("..target.province..")");
				HarvestSpyInfo():execute(insertedSpy);

				if not target.friendArmy then
					-- not specified friend army, need to pick appropriate army from the fortress list
					return true, self:resourceToGold(HarvestSpyInfo():getResources());
				else
					-- check fortress condition
					if HarvestSpyInfo():getFortressLevel()>target.Fortresses then
						self:log_info("Condition fortresses not satisfied. Got "..HarvestSpyInfo():getFortressLevel()..", expected "..target.Fortresses);
						return false, _SelectTargetLogic.INVESTIGATE_RESULT_DEFENSE_CHANGED;
					else
						-- check gold condition
						local gold=self:resourceToGold(HarvestSpyInfo():getResources());
						if gold<target.gold then
							self:log_info("Condition gold not satisfied. Got "..gold..", expected "..target.gold);
							return false, _SelectTargetLogic.INVESTIGATE_RESULT_GOLD_NOT_SATISFIED;
						else
							-- check army condition
							if not table.foreachi(HarvestSpyInfo():getArmy(), function(unitName, amounts)
								local i;
								for i=1,2 do
									amounts[i]=amounts[i] or 0;
									target.enemyArmy[unitName][i]=target.enemyArmy[unitName][i] or 0;
									if amounts[i]>target.enemyArmy[unitName][i] then
										-- unsatisfied army condition
										self:log_info("Condition army not satisfied. Got "..amounts[i].." "..unitName..", expected "..target.enemyArmy[unitName][i]);
										return true;
									end
								end
							end) then
								-- all conditions are satisfied
								self:log_info("The target is ok");
								return true, gold;
							else
								return false, _SelectTargetLogic.INVESTIGATE_RESULT_DEFENSE_CHANGED;
							end
						end
					end
				end
			end
		else
			self:log_info("The target is online");
			return false, _SelectTargetLogic.INVESTIGATE_RESULT_TARGET_ONLINE;
		end
	end
	return false, _SelectTargetLogic.INVESTIGATE_RESULT_NO_INFORMATION;
end

-- start logic
function _SelectTargetLogic:execute(province)
	local goodTargets={};
	local ourArmy=self:getOurArmy();
	table.foreachi(MilitaryManager():getAttackList(), function(_, target)
		if self:compareArmies(ourArmy, target.friendArmy) then
			local isOk, goldAmount=self:investigateTarget(province, target);
			if isOk then
				table.insert(goodTargets, {target, goldAmount});
			end
		else
			self:log_info("Not enough army to attack "..target.enemy.."("..target.province..")");
		end
	end);
	table.sort(goodTargets, function(tA, tB)
		if tA[2]>tB[2] then
			return true;
		end
	end);

	local resultTargets={};
	table.foreachi(goodTargets, function(_, targetInfo)
		table.insert(resultTargets, targetInfo[1]);
	end);
	return resultTargets;
end	

-- constructor
function SelectTargetLogic()
	if not _SelectTargetLogic.initialized then
		_SelectTargetLogic=_SelectTargetLogic:inherit(LoggingClass());
		_SelectTargetLogic.initialized=true;
	end
	return _SelectTargetLogic;
end
