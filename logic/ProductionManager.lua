require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.logic.Items");

_ProductionManager=Class
{
	type="ProductionManager"
};

function _ProductionManager:loadConfigFile(configFile)
	if FileUtil():fileExists(configFile) then
		self:log_info("Load "..configFile);
		local tasks={};
		for line in io.lines(configFile) do
			line = StringUtil():trim(line);
			if string.len(line)>0 and not StringUtil():starts(line, "--") then
				string.gsub(line, "(%d+) (.+)", function(province, itemName)
					local count;
					string.gsub(itemName, "(.-)(%d+)", function (unitName, _count)
						itemName=StringUtil():trim(unitName);
						count=tonumber(_count);
					end);

					table.insert(tasks, {
						province=tonumber(province),
						itemName=itemName,
						count=count
					});
				end);
			end
		end
		return tasks;
	else
		self:log_info("Cannot find file "..configFile);
		return {};
	end
end

function _ProductionManager:load()
	self.buildTasks=self:loadConfigFile(self.buildConfigFile);
	local nTasks=table.getn(self.buildTasks);
	if nTasks>0 then
		self:log_info(nTasks.." tasks loaded");
	else
		self:log_info("No defined tasks");
	end

	-- calculate province order
	self.provinceOrder={};
	table.foreachi(self.buildTasks, function(_, buildInfo)
		if not table.foreachi(self.provinceOrder, function(_, province)
			if province == buildInfo.province then
				return true;
			end
		end) then
			table.insert(self.provinceOrder, buildInfo.province);
		end
	end);
end

function _ProductionManager:save()
	local file=io.open(self.buildConfigFile, "w");
	
	file:write("-- Building names:\n");
	file:write("------------------\n");
	table.foreach(_Items.BUILDINGS, function(itemName, _)
		file:write("-- "..itemName.."\n");
	end);

	file:write("\n-- Research names:\n");
	file:write("------------------\n");
	table.foreach(_Items.RESEARCHES, function(itemName, _)
		file:write("-- "..itemName.."\n");
	end);

	file:write("\n-- Army names:\n");
	file:write("------------------\n");
	table.foreach(_Items.ARMY, function(itemName, _)
		file:write("-- "..itemName.."\n");
	end);

	file:write("\n-- Add you constructions below in format <province_number><space><item name>\n");
	file:write("----------------------------------------------------------------------------\n");

	local provinceBuildings={};
	table.foreachi(self.buildTasks, function(taskID, buildInfo)
		if buildInfo then
			provinceBuildings[buildInfo.province]=provinceBuildings[buildInfo.province] or {};
			table.insert(provinceBuildings[buildInfo.province], buildInfo);
		end
	end);

	-- save buildings
	table.foreachi(self.provinceOrder, function(_, province)
		if provinceBuildings[province] then
			file:write("\n-- Province #"..province.."\n");
			table.foreachi(provinceBuildings[province], function(_, buildInfo)
				local name=buildInfo.itemName;
				if buildInfo.count then
					name=name.." "..buildInfo.count;
				end
				file:write(province.." "..name.."\n");
			end);
		end
	end);

	file:close();
end

function _ProductionManager:initialize(buildConfigFile)
	self.buildConfigFile=buildConfigFile;
	self.activeTasks={};
	self:load();
	self:save();
	self.nTask=1;
end

function _ProductionManager:finalize()
	self:save();
end

function _ProductionManager:getTaskByID(taskID)
	return self.buildTasks[taskID];
end

function _ProductionManager:completeTask(taskID)
	self.buildTasks[taskID]=nil;
	self:disactivateTask(taskID);
	self:save();
end

function _ProductionManager:getFirstTaskID()
	self.currentTaskID=0;
	return self:getNextTaskID();
end

function _ProductionManager:getNextTaskID()
	return table.foreachi(self.buildTasks, function(iTask, buildInfo)
		if iTask>self.currentTaskID then
			if buildInfo then
				self.currentTaskID=iTask;
				return iTask;
			end
		end
	end);
end

function _ProductionManager:getTasksCount()
	return table.getn(self.buildTasks);
end

function _ProductionManager:activateTask(taskID)
	self.activeTasks[taskID]=true;
end

function _ProductionManager:disactivateTask(taskID)
	self.activeTasks[taskID]=false;
end

function _ProductionManager:getActiveTasks()
	return self.activeTasks;
end

function ProductionManager()
	if not _ProductionManager.initialized then
		_ProductionManager=_ProductionManager:inherit(LoggingClass());
		_ProductionManager.initialized=true;
		_ProductionManager.activeTasks={};
	end
	return _ProductionManager;
end
