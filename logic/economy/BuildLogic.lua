require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.ProductionManager");
require("imperiaonline.logic.economy.BuildUtils");
require("imperiaonline.harvest.HarvestTransport");

_BuildLogic=Class
{
	type="BuildLogic",
	TRANSPORTING=true,
	NO_TRANSPORTING=true,
};

function _BuildLogic:buildConstruction(taskID)
	local construction=ProductionManager():getTaskByID(taskID);
	if construction then
		if Action():go("Construct", construction) then

			-- building successfully started
			self:log_info("buildConstruction: Building "..construction.itemName.." in province "
				..construction.province.." successfully started");

			return true;
		end
	end
end

function _BuildLogic:buildResearch(taskID)
	return self:buildConstruction(taskID);
end

function _BuildLogic:buildItem(taskID)
	local item=ProductionManager():getTaskByID(taskID);
	if item then
		local status;
		local itemIype=Items():getItemType(item.itemName);
		if itemIype == "BUILDINGS" then
			status=self:buildConstruction(taskID);
		elseif itemIype == "RESEARCHES" then
			status=self:buildResearch(taskID);
		elseif itemIype == "ARMY" then
			status=self:buildArmy(taskID);
		else
			error("Invalid item type "..(itemIype or "nil"));
		end
		
		if status then
			-- mark the task completed
			ProductionManager():completeTask(taskID);
		end
	end
end

function _BuildLogic:buildArmy(taskID, mobilized)
	local item=ProductionManager():getTaskByID(taskID);
	HarvestSoldiers():execute(item.province);
	local freeSpace=HarvestSoldiers():getFreeSpace(item.itemName);
	local amountTrained=Action():go("Train", item);
	if amountTrained and amountTrained>0 then
		if amountTrained<item.count then
			-- update the amount of trained units
			item.count=amountTrained;
			ProductionManager():save();
			return false;
		else
			return true;
		end
	else
		-- unable to train units
	end
end

-- return a list of occuppied provinces with tasks
function _BuildLogic:getOccuppiedProvincesWithTasks()
	local provinces={};
	local isRepairing=false;
	table.foreach(self.repairingFortress, function(prNo, repairing)
		if repairing then
			provinces[prNo]=true;
			isRepairing=true;
		end
	end);

	if isRepairing then
		return provinces;
	end

	table.foreach(ProductionManager():getActiveTasks(), function(taskID, isTaskActive)
		local item=ProductionManager():getTaskByID(taskID);
		if item and isTaskActive then
			provinces[item.province]=true;
		end
	end);
	return provinces;
end

-- return true if a given taskID can be build
function _BuildLogic:canBuild(taskID)
	local item=ProductionManager():getTaskByID(taskID);
	if item then
		local itemIype=Items():getItemType(item.itemName);
		local province=item.province;
		if HarvestTransport():isTransportLoadResources() 
			or not table.foreachi(HarvestTransport():getTransports(), function(_, transportInfo)
				if transportInfo[2] == province then
					return true;
				end
		end) then
			if itemIype == "BUILDINGS" and HarvestEconomy():isProvinceReadyToBuild(province) then
				return true;
			elseif itemIype == "RESEARCHES" and HarvestEconomy():isResearchReadyToBuild(province) then
				return true;
			elseif itemIype == "ARMY" then
				-- FIXME: Check if there is enough space in the barracks
				return true;
			end
		end
	end
end

-- return the required resources by a given taskID
function _BuildLogic:getRequiredResources(taskID)
	HarvestEconomy():execute();
	local item=ProductionManager():getTaskByID(taskID);
	if item then
		local province=item.province;
		local itemIype=Items():getItemType(item.itemName);
		if itemIype == "BUILDINGS" then
			local resources=HarvestConstructions():getBuildingPrices(province, item.itemName);
			if resources then
				table.foreach(resources, function(name, amount)
					if resources[name]>0 and resources[name]<200 then
						resources[name]=200;
					end
				end);
				return resources;
			end
		elseif itemIype == "RESEARCHES" then
			return HarvestResearch():getResearchPrices(item.itemName);
		elseif itemIype == "ARMY" then
			return HarvestTrainings():getUnitPrices(item.itemName, item.count);
		else
			self:log_warn("Invalid item type "..(itemIype or "nil"));
		end
	else
		self:log_warn("getRequiredResources -> Invalid requested taskID="..taskID);
	end
end

-- request resources from a given province. 
-- the province returns 0 resources if currently under transport
function _BuildLogic:requestResourceFromProvince(province, provinceResources, resourceName, amountRequired, isTransportation)
	if isTransportation then
		HarvestTransport():execute();
		if HarvestTransport():isTransportFromProvince(province) then
			self:log_info("Province "..province.." is occuppied with transport");
			return 0;
		end
		
		if self:getOccuppiedProvincesWithTasks()[province] then
			self:log_info("Province "..province.." is occuppied with tasks");
			return 0;
		end
	end
	return math.min(provinceResources[resourceName], amountRequired);
end

function _BuildLogic:requestResourcesFromAllProvincesIfTrade(targetProvince, requiredResources)
	local provinceNumbers=HarvestEconomy():getProvinceNumbersSortedByDepotSize();
	local targetProvinceIndex;
	local newRequiredResources={};
	local resourcesByProvince={};

	-- remove target province from the list with all provinces
	table.foreachi(provinceNumbers, function(i, prNo) if prNo == targetProvince then targetProvinceIndex=i; end end);
	table.remove(provinceNumbers, targetProvinceIndex);

	-- get all available resources in the province
	local availableResources=HarvestEconomy():getProvinceResources(targetProvince);

	-- substract the available resources from required resources
	-- and collect the remaining resources in the target province
	local remainingResources={};
	table.foreach(requiredResources, function(resourceName, resourceAmount) 
		if availableResources[resourceName] then
			newRequiredResources[resourceName]=resourceAmount-availableResources[resourceName];
			if newRequiredResources[resourceName]<0 then newRequiredResources[resourceName]=0; end
			remainingResources[resourceName]=availableResources[resourceName]-(resourceAmount-newRequiredResources[resourceName]);
			if remainingResources[resourceName]<0 then remainingResources[resourceName]=0; end
		end
	end);

	-- get all available resources in all remaining provincess
	local allProvinceResources={};
	table.foreachi(provinceNumbers, function(_, prNo)
		local provinceResources=HarvestEconomy():getProvinceResources(prNo);
		allProvinceResources[prNo]={};
		table.foreach(_Items.RESOURCES, function(resourceName)
			allProvinceResources[prNo][resourceName]=provinceResources[resourceName] or 0;
		end);
	end);

	-- request exact resources without trading from the remaining provinces
	table.foreachi(provinceNumbers, function(_, prNo) resourcesByProvince[prNo]={}; end);
	table.foreach(_Items.RESOURCES, function(resourceName)
		table.foreachi(provinceNumbers, function(_, prNo)
			local resourceAvailable=self:requestResourceFromProvince(prNo, allProvinceResources[prNo], resourceName, newRequiredResources[resourceName], _BuildUtils.TRANSPORTING);
			resourcesByProvince[prNo][resourceName]=resourceAvailable;

			-- substract the province resource
			allProvinceResources[prNo][resourceName]=allProvinceResources[prNo][resourceName]-resourceAvailable;

			-- substract what we get from the requirements
			newRequiredResources[resourceName]=newRequiredResources[resourceName]-resourceAvailable;
		end);
	end);

	-- trade the remaining resources in the target province
	table.foreachi(HarvestTrade():sortProfitableResources(), function(_, tradeResource)
		table.foreach(_Items.RESOURCES, function(resourceName)
			-- calculate the amount available resource to trade 
			local amountToConvert=HarvestTrade():amountOfResourceToConvert(tradeResource, resourceName, newRequiredResources[resourceName]);
			local resourceAvailable=self:requestResourceFromProvince(targetProvince, remainingResources, tradeResource, amountToConvert, _BuildUtils.NO_TRANSPORTING);

			-- substract the collected resource from the requirements
			local resourceCollected=HarvestTrade():amountOfResourceIfTradeResource(tradeResource, resourceAvailable, resourceName);
			newRequiredResources[resourceName]=newRequiredResources[resourceName]-resourceCollected;
		end);
	end);

	-- request resources with trading from the remaining provinces

	-- collect all resources in order of their profit
	table.foreachi(HarvestTrade():sortProfitableResources(), function(_, tradeResource)
		table.foreachi(provinceNumbers, function(_, prNo)
			table.foreach(_Items.RESOURCES, function(resourceName)
				local requiredResourceAmount=newRequiredResources[resourceName];
				if requiredResourceAmount>0 then
					local amountToConvert=HarvestTrade():amountOfResourceToConvert(tradeResource, resourceName, requiredResourceAmount);
					local resourceAvailable=self:requestResourceFromProvince(prNo, allProvinceResources[prNo], tradeResource, amountToConvert, _BuildUtils.TRANSPORTING);
					if resourceAvailable>0 then
						resourcesByProvince[prNo][tradeResource]=resourcesByProvince[prNo][tradeResource]+resourceAvailable;

						-- substract the province resource which is traded
						allProvinceResources[prNo][tradeResource]=allProvinceResources[prNo][tradeResource]-resourceAvailable;

						-- substract the collected resource from the requirements
						local resourceCollected=HarvestTrade():amountOfResourceIfTradeResource(tradeResource, resourceAvailable, resourceName);
						newRequiredResources[resourceName]=newRequiredResources[resourceName]-resourceCollected;
					end
				end
			end);
		end);
	end);

	-- calculate the collected resources
	local newAvailableResources={};
	table.foreach(_Items.RESOURCES, function(resourceName) newAvailableResources[resourceName]=0; end);

	table.foreachi(provinceNumbers, function(_, prNo)
		table.foreach(_Items.RESOURCES, function(resourceName)
			newAvailableResources[resourceName]=newAvailableResources[resourceName]+resourcesByProvince[prNo][resourceName];
		end);
	end);
	table.foreach(_Items.RESOURCES, function(resourceName)
		newAvailableResources[resourceName]=newAvailableResources[resourceName]+availableResources[resourceName];
	end);

	local ok, sellResourses, buyResources=BuildUtils():hasEnoughResourcesIfTrade(requiredResources, newAvailableResources);
	if ok then
		local needTransporting=table.foreach(resourcesByProvince, function(prNo, resources)
			return table.foreach(resources, function(resourceName, amount)
				if amount>0 then
					return true;
				end
			end);
		end);

		local localSell, localBuy;
		ok, localSell, localBuy = BuildUtils():hasEnoughResourcesIfTrade(requiredResources, availableResources);
		if ok then
			sellResourses, buyResources = localSell, localBuy;
			needTransporting=false;
		end

		table.foreach(_Items.RESOURCES, function(resourceName)
			sellResourses[resourceName]=math.ceil(sellResourses[resourceName] or 0);
			buyResources[resourceName]=math.ceil(buyResources[resourceName] or 0);
		end);

		return true, needTransporting and resourcesByProvince or nil, sellResourses, buyResources;
	else
		local provinces="";
		table.foreach(resourcesByProvince, function(prNo)
			if table.foreach(resourcesByProvince[prNo], function(resourceName, resourceAmount)
				if resourceAmount>0 then
					return true;
				end
			end) then
				if string.len(provinces)>0 then
					provinces=provinces..",";
				end
				provinces=provinces..prNo; 
			end
		end);
		self:log_info("Not enough resources collected by provinces {"..provinces.."}");
	end
end

function _BuildLogic:attemptToBuild(province, requiredResources, buildCallback, ...)
	HarvestEconomy():execute();
	local canBuild, resourcesToTransport, sellResourses, buyResources = self:requestResourcesFromAllProvincesIfTrade(province, requiredResources);
	if canBuild then
		self:log_info("Build operation started in #"..province.." requiring "..StringUtil():tableToString(requiredResources, HarvestTrade():sortProfitableResources()));
		-- can build the item
		if resourcesToTransport then
			self:log_info("Build possible with transportation");
			-- transport resources from the other provinces
			table.foreach(resourcesToTransport, function(sourceProvince, resources)
				resources.province=sourceProvince;
				resources.tprovince=province;
				Action():go("Transport", resources);
			end);
		else
			self:log_info("Build possible with trade: "..
				"sell="..StringUtil():tableToString(sellResourses, HarvestTrade():sortProfitableResources())..","..
				"buy="..StringUtil():tableToString(buyResources, HarvestTrade():sortProfitableResources()));

			-- trade resources
			Action():go("Trade", {province=province, sell=sellResourses, buy=buyResources});
			HarvestEconomy():execute();
			if BuildUtils():hasEnoughResources(requiredResources, HarvestEconomy():getProvinceResources(province)) then
				self:log_info("There are enough resources to build after trade");
				-- there are enough resouces so build the item
				buildCallback(arg);
			else
				self:log_warn("Not enough resources to build after trade");
			end
		end
		return true;
	end
end

function _BuildLogic:attemptToBuildTask(taskID)
	-- lets try build an item
	local item=ProductionManager():getTaskByID(taskID);
	if not item then
		-- taskID has been expired
		self:log_info(taskID.." has been expired");
		return ;
	end
	local province=item.province;
	local buildName=item.itemName;
	if item.count then
		buildName=item.count.." "..buildName;
	end
	self:log_info("Attempt to build "..buildName.." in province "..province);
	local itemIype=Items():getItemType(item.itemName);
	local requiredResources=self:getRequiredResources(taskID);
	ProductionManager():activateTask(taskID);
	return self:attemptToBuild(province, requiredResources, function() self:buildItem(taskID); end);
end

function _BuildLogic:buildAny()
	local anyTaskStarted=false;
	local whatHappend;

	-- activate ready building and researches
	Action():go("Activate");

	-- balance the gold
	self:log_info("Fix negative golds in provinces");
	execute_mission("PositiveGold");

	-- load build tasks
	ProductionManager():load();

	-- unload cargo if available in transports
	HarvestTransport():execute();
	Action():go("TransportUnload");
	HarvestTransport():execute();

	if HarvestTransport():transportInProgress() then
		if not HarvestTransport():isTransportLoadResources() then
			-- if transporting in progress then mark the build operation successful
			anyTaskStarted=true;
			whatHappend="Transport with building purpose is now in progress";
		end
	else
		-- if not transport unmark all transport waiting provinces
	end

	-- repair broken fortresses
	local isBrokenFortress=false;
	table.foreachi(HarvestEconomy():getProvinceNumbers(), function(_, prNo)
		local brokenFortress, repairResources=HarvestConstructions():isBrokenFortress(prNo);
		if brokenFortress then
			self.repairingFortress[prNo]=true;
			self:log_warn("Warning! Broken fortress in province #"..prNo);
			self:attemptToBuild(prNo, repairResources, function() 
				Action():go("Repair", {province=prNo});
				-- recheck if fortress repaired
				brokenFortress, repairResources=HarvestConstructions():isBrokenFortress(prNo);
				if not brokenFortress then
					self:log_info("Fortress successfully repaired");
					self.repairingFortress[prNo]=false;
				else
					self:log_info("Failed to repair fortress");
				end
			end);
			isBrokenFortress=true;
			anyTaskStarted=true;
			whatHappend="Repairing fortress is in progress";
		else
			self.repairingFortress[prNo]=false;
		end
	end);

	if not isBrokenFortress then
		table.foreach(ProductionManager():getActiveTasks(), function(taskID, isToBuild)
			if isToBuild and self:canBuild(taskID) then
				self:log_info("Try task#"..taskID.." from the list");
				if self:attemptToBuildTask(taskID) then
					anyTaskStarted=true;
					whatHappend="Some buildings are in progress";
				end
			end
		end);

		-- loop over all possible tasks to build
		local taskID=ProductionManager():getFirstTaskID();
		while taskID do
			-- attempt to build task
			local item=ProductionManager():getTaskByID(taskID);
			if item and self:canBuild(taskID) and not self:getOccuppiedProvincesWithTasks()[item.province] then
				if self:attemptToBuildTask(taskID) then
					anyTaskStarted=true;
					whatHappend="Some buildings are in progress";
				end
			end
			taskID=ProductionManager():getNextTaskID();
		end
		if anyTaskStarted then
			self:log_info(whatHappend);
		else
			self:log_info("Unable to build anything");
		end
	end
	return anyTaskStarted;
end

function BuildLogic()
	if not _BuildLogic.initialized then
		_BuildLogic=_BuildLogic:inherit(LoggingClass());
		_BuildLogic.initialized=true;
		_BuildLogic.repairingFortress={};
	end
	return _BuildLogic;
end
