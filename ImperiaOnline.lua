-- Set to true to enable test mode
TEST=false;

-- load required modules

require("imperiaonline.UserInfo");

-- harvesters
require("imperiaonline.harvest.HarvestConstructions");
require("imperiaonline.harvest.HarvestFriendMove");
require("imperiaonline.harvest.HarvestEnemyMove");
require("imperiaonline.harvest.HarvestTransport");
require("imperiaonline.harvest.HarvestTrainings");
require("imperiaonline.harvest.HarvestProvinces");
require("imperiaonline.harvest.HarvestResearch");
require("imperiaonline.harvest.HarvestSoldiers");
require("imperiaonline.harvest.HarvestEconomy");
require("imperiaonline.harvest.HarvestBonuses");
require("imperiaonline.harvest.HarvestWorkers");
require("imperiaonline.harvest.HarvestAntiSpy");
require("imperiaonline.harvest.HarvestSpyInfo");
require("imperiaonline.harvest.HarvestRumors");
require("imperiaonline.harvest.HarvestTrade");
require("imperiaonline.harvest.HarvestUsers");
require("imperiaonline.harvest.HarvestArmy");
require("imperiaonline.harvest.HarvestUser");
require("imperiaonline.harvest.HarvestTime");
require("imperiaonline.harvest.HarvestSpy");

-- network utilities
require("imperiaonline.net.HttpSession");
require("imperiaonline.net.HttpBrowser");

-- actions
require("imperiaonline.action.TransportUnloadAction");
require("imperiaonline.action.ReturnArmyAction");
require("imperiaonline.action.ArmyFortressAction");
require("imperiaonline.action.ArmyMovesAction");
require("imperiaonline.action.ConstructAction");
require("imperiaonline.action.InsertSpyAction");
require("imperiaonline.action.TransportAction");
require("imperiaonline.action.ProvinceAction");
require("imperiaonline.action.ActivateAction");
require("imperiaonline.action.SendSpyAction");
require("imperiaonline.action.KillSpyAction");
require("imperiaonline.action.RepairAction");
require("imperiaonline.action.AttackAction");
require("imperiaonline.action.TrainAction");
require("imperiaonline.action.TradeAction");
require("imperiaonline.action.BonusAction");
require("imperiaonline.action.WorkAction");
require("imperiaonline.action.Action");

-- missions
require("imperiaonline.mission.MissionActivateBuildings");
require("imperiaonline.mission.MissionLoadResources");
require("imperiaonline.mission.MissionPositiveGold");
require("imperiaonline.mission.MissionConstruct");
require("imperiaonline.mission.MissionMilitary");
require("imperiaonline.mission.MissionBonus");
require("imperiaonline.mission.MissionWork");
require("imperiaonline.config.missions");

-- logic
require("imperiaonline.logic.military.ConcentrateArmyLogic");
require("imperiaonline.logic.military.SelectTargetLogic");
require("imperiaonline.logic.military.DisperseArmyLogic");
require("imperiaonline.logic.military.AttackTargetLogic");
require("imperiaonline.logic.military.SeekTargetsLogic");
require("imperiaonline.logic.economy.FixGoldLogic");
require("imperiaonline.logic.military.DefendLogic");
require("imperiaonline.logic.military.AttackLogic");
require("imperiaonline.logic.economy.BuildLogic");
require("imperiaonline.logic.economy.BuildUtils");
require("imperiaonline.logic.ProductionManager");
require("imperiaonline.logic.MilitaryManager");
require("imperiaonline.logic.Items");

-- common utilities
require("logger.LoggingClass");
require("util.DateUtil");
require("util.Date");
require("luaprocess");
require("luaia");

-- The main imperial class
_ImperiaOnline=Class
{
	type="ImperiaOnline",
	VERSION_HI=1,
	VERSION_LO=7,

	MAX_ACTIVE_TIME=16*60*60,   -- 16 h active time
	SLEEP_TIME=6*60*60,         -- 7 h sleep interval
	BANNED_TIME=10*60*60,       -- 10 h banned interval

	TIME_BEFORE_SLEEP1=20*60,   -- time before end for phase 1
	TIME_BEFORE_SLEEP2=10*60,   -- time after phase 1 for phase 2
};

-- executes mission
function execute_mission(name, params) 
	_G["Mission"..name](params);
end

function _ImperiaOnline:addWait(secs, isSleep)

	while secs>0 do
		secs=secs-1;
		self.secsElapsed=self.secsElapsed+1;
		io.write("Elapsed Time: "..DateUtil():formatTime(self.secsElapsed).." h          \r"); io.flush();
		if isSleep then
			process.sleep(1);
		end
	end
end

function _ImperiaOnline:executeMission(missionName, missionInfo, params, isExceptionRelogin)
	if missionInfo then
		self:log_info("Execute mission "..missionName..". Next execution after "..DateUtil():minToHour(math.floor(missionInfo.current_seconds/60)).." h");
	end

	xpcall(function() 
		execute_mission(missionName, params);
	end,
	function(msg) -- exceptions handler
		self:log_error("Exception occurred while executing mission "..missionName);
		self:log_error(formatmsg(debug.traceback(msg)));

		if isExceptionRelogin then
			-- relogin
			HttpSession():recreate();
			local code=self:detectNumber("code.gif");
			if not HttpSession():relogin(code) then
				if HttpSession():isBanned() then
					print("We are probably banned! Waiting "..DateUtil():formatTime(_ImperiaOnline.BANNED_TIME));
					self:wait(_ImperiaOnline.BANNED_TIME);
				end
			end
		end
	end);
end

function _ImperiaOnline:initialize()
	-- initialize production
	local productionFileName=HttpSession():getUsername().."-build.txt";
	ProductionManager():initialize(productionFileName);
	-- initialize military
	local militaryFileName=HttpSession():getUsername().."-fight.txt";
	MilitaryManager():initialize(militaryFileName);
end

-- program entry point
function _ImperiaOnline:main(...)
	-- process program arguments
	local params={};
	local arg = {...}
	table.foreachi(arg, function(_, a)
		string.gsub(a, "(%S+)=(%S+)", function(name, value)
			params[string.lower(name)]=value;
		end);
	end);

	-- initialize local variables
	local username, password, code, realm;                                              -- login info
	local maxActiveTime=(params.online and tonumber(params.online)*60*60 or 
		_ImperiaOnline.MAX_ACTIVE_TIME);                                            -- MAX_ACTIVE_TIME default active time
	local sleepTime=params.sleep and tonumber(params.sleep) or 0;
	sleepTime=math.floor(sleepTime*60*60);

	-- create new session
	local session=HttpSession();

	-- ask for user login information
	io.write("Welcome to Imperia Online Bot ".._ImperiaOnline.VERSION_HI..".".._ImperiaOnline.VERSION_LO.."\nYou will be asked for password ");
	io.write("Then the bot will be executed and it will be running for about "..DateUtil():minToHour(maxActiveTime/60).." h after sleeping "
	..DateUtil():formatTime(sleepTime).." h before first login\n");
	io.write("You can setup the bot to build constructions in file <username>-build.txt. ");
	io.write("Valid options are sleep=<hours> which means sleep before login and online=<hours> meaning the time to be active after login");
	io.write("\nDon't worry about exceptions! ");
	io.write("Exceptions may happen most probably because the imperiaonline server is down, the internet is temporary unavailable or your account is busy. ");
	io.write("In such situation just restart the bot.");
	io.write("\nHave a nice day while playing Imperia Online ;-)\n");
	print();

	-- Hardcoded login information
	username, realm=UserInfo();
	username, realm="sivushka", 2;

	if username then
		print("Hello "..username.."! Please type your password and the code below");
	end
	if not realm then io.write("   realm:");  realm=io.read(); end

	local isSleeping=false;
	local attempts=3;
	while true do
		if not username then io.write("username:"); username=io.read(); end
		if not isSleeping then io.write("password:"); password=io.read(); end

		-- refresh the session
		session:create(realm);

		-- detect image number
		code=self:detectNumber("code.gif");

		-- sleep for a while if requested
		if sleepTime>0 then
			self.secsElapsed=0;
			print("Sleeping "..DateUtil():formatTime(sleepTime).." h before login");
			self:addWait(sleepTime, true);
			sleepTime=0;
			isSleeping=true;
		end

		-- try 3 times to login
		if not isSleeping or (isSleeping and attempts>0) then
			if session:login(username, password, code) then
				break;
			else
				print("Access denied");
			end
			attempts=attempts-1;
		else
			-- unable to login while sleep
			print("Sorry! Unable to login after sleep! Going to sleep "..DateUtil():formatTime(_ImperiaOnline.SLEEP_TIME).." h");
			self:addWait(_ImperiaOnline.SLEEP_TIME, true);
		end
	end

	self:initialize();

	-- reset elapsed seconds since the program start
	self.secsElapsed=0;                 

	-- ...and let's the war begin!
	while true do
		local requiredSecsForExecution=os.time();

		-- loop through all missions and exectute which are ready for executions
		table.foreach(missions, function(missionName, missionInfo)
			missionInfo.current_seconds=missionInfo.current_seconds or 0;
			if missionInfo.current_seconds<=0 then
				-- execute mission
				missionInfo.current_seconds=(missionInfo.interval_mins+math.random(2*missionInfo.random_offset_mins)-missionInfo.random_offset_mins)*60;

				if params[string.lower(missionName)] and params[string.lower(missionName)] == "off" then
					self:log_info("Mission "..missionName.." turned off by option");
				else
					self:executeMission(missionName, missionInfo, params, true);
				end
			else
				missionInfo.current_seconds=missionInfo.current_seconds-1;
			end
		end);

		-- calculates elapsed time for all mission executions
		requiredSecsForExecution=os.time()-requiredSecsForExecution;

		-- sleep a second
		self:addWait(1, true);

		-- accumulate elapsed time
		self:addWait(requiredSecsForExecution, false);

		-- check if time for sleep
		if maxActiveTime>_ImperiaOnline.TIME_BEFORE_SLEEP1 and 
			self.secsElapsed>=maxActiveTime-_ImperiaOnline.TIME_BEFORE_SLEEP1 then

			self:log_info("Preparing for sleep phase 1");
			self:executeMission("BeforeSleep", nil, params, false);

			self:addWait(_ImperiaOnline.TIME_BEFORE_SLEEP2, true);
			self:log_info("Preparing for sleep last phase 2");
			self:executeMission("BeforeSleep", nil, params, false);
			self:addWait(maxActiveTime-self.secsElapsed, true);
		end

		-- check if time over
		if self.secsElapsed>=maxActiveTime then
			-- Game Over
			self:log_info("The game is over");
			ProductionManager():finalize();

			local now=Date();
			local sleepMinutes=60-(now:getMinute()+1);
			sleepMinutes=sleepMinutes*60+_ImperiaOnline.SLEEP_TIME;

			self:log_info("We are going to sleep for "..DateUtil():formatTime(sleepMinutes));

			-- reset elapsed time
			self.secsElapsed=0;

			-- set active time to max active time
			maxActiveTime=_ImperiaOnline.MAX_ACTIVE_TIME;

			-- Go to sleep
			self:addWait(sleepMinutes, true);

			-- Waking up
			self:log_info("Waking up and ready to work for "..DateUtil():formatTime(maxActiveTime));

			-- relogin
			session:create(realm);
			code=self:detectNumber("code.gif");
			if not session:login(username, password, code) then
				if session:isBanned() then
					print("We are probably banned! Waiting "..DateUtil():formatTime(_ImperiaOnline.BANNED_TIME));
					self:wait(_ImperiaOnline.BANNED_TIME);
				end
			end

			-- reset missions active times
			table.foreach(missions, function(missionName, missionInfo)
				missionInfo.current_seconds=0;
			end);

			-- re-initialization
			self:initialize();
		end
	end
end

function _ImperiaOnline:detectNumber(imgFile)

	local function F(x, y)
		return math.mod(x, y);
	end

	local function isPixel(pixel)
		if pixel>0 then
			return true;
		end
	end

	local digitsMap={[99 ]=1,[162]=2,[241]=3,[412]=4,[171]=5,[191]=6,[117]=7,[243]=8,[255]=9,[210]=0};

	local number="";

	local image=ia.image_load(imgFile);

	image=image:convert_gray(ia.UINT_8);
	image:binarize_level(10);
	image:inverse();
	local w,h=image:get_metrics();

	local letterStart=false;
	local letterNum=0;
	local letterCount=0;
	local i, j;
	local startX=0;
	local first=true;
	local hasPixel=false;
	local count=0;
	for i=0,w-1 do
		if not first then
			if hasPixel then
				if not letterStart then
					startX=i;
					letterStart=true;
					letterNum=letterNum+1;
					letterCount=0;
				end
			else
				if letterStart then
					letterStart=false;
					if not digitsMap[letterCount] then
						print(letterCount.." is missing in file "..imgFile.." ("..letterNum..")");
					else
						number=number..digitsMap[letterCount];
					end			
				end
			end
		else
			first=false;
		end

		count=0;
		hasPixel=false;
		for j=0,h-1 do
			local pixel=image:get_pixel(i, j);
			if isPixel(pixel) then
				hasPixel=true;
				count=count+F(i-startX, j);
			end
		end
		
		letterCount=letterCount+count;
	end

	self:log_info("Code `"..number.."' recognized");
	return number;
end

-- singleton constructor
function ImperiaOnline()
	_ImperiaOnline=_ImperiaOnline:inherit(LoggingClass());
	return _ImperiaOnline;
end
