require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");

_HarvestEconomy=Class
{
	type="HarvestEconomy",
	URI_ALLCONSTRUCTIONS="/imperia/game/allconstructions.php?log=no",
	Resources={
		"Wood", "Iron", "Stone", "Gold"
	},
	Buildings={
		"Farm", "Lumbermill", "Iron mine", "Stone quarry", "Granary", "Depot Station",
		"Infantry barracks", "Shooting Range", "Cavalry barracks", "Siege workshop", "Fortresses"
	},
	Researches={
		"Range attack", "Melee attack", "War horses", "Armor", "University", "Centralization", 
		"Bureaucracy", "Architecture", "Medicine", "Trade", "Tactics", "Fortification", 
		"Military Academy", "Military Architecture", "Military Medicine", "Spying", 
		"Border outposts", "Cartography"
	}
};

function _HarvestEconomy:download()
	self.data=HttpBrowser():get(_HarvestEconomy.URI_ALLCONSTRUCTIONS);
	--FileUtil():writeAll("all_constructions.html", self.data);
end

function _HarvestEconomy:parse()
	local dataBuildings, dataResearches;
	local PATTERN1=[[return escape\(\.\-\)</table>\.\-<table\(\.\-\)</table>\.\-<table\(\.\-\)</table>]];
	string.gsub(self.data, self:escREX(PATTERN1), function(d1, d2, d3) dataBuildings=d2; dataResearches=d3; end);

	local PATTERN2=[[escape('\.\- - \(\%%d\+\)<BR>\.\- - \(\%%d\+\)<BR>\.\- - \(\%%d\+\)<BR>\.\- - \(\%%d\+\)\.\-pr_nomer=\(\%%\d\+\)]];

	self.provinces={};
	self.provinceNumbers={};
	local nprovinces=0;
	string.gsub(dataBuildings, "escape(.-)pr_nomer=(%d+)", function(data, pr) 
		pr=tonumber(pr);
		self.provinces[pr]={};
		local ri=1;
		string.gsub(data, " %- ([%d%-]+)", function(count)
			self.provinces[pr].resources=self.provinces[pr].resources or {};
			self.provinces[pr].resources[_HarvestEconomy.Resources[ri]]=tonumber(count);
			ri=ri+1;
		end);
		nprovinces=nprovinces+1; 
		table.insert(self.provinceNumbers, pr);
	end);

	local buildingLevels={};
	local buildingStatuses={};
	string.gsub(dataBuildings, ">(%d+)([%s<].-)</TD>", function(n, timer)
		if StringUtil():starts(timer, "<font") then
			local h, m;
			string.gsub(timer, "(%d+):(%d+)", function (_h, _m) h=_h; m=_m; end);
			if not h then
				table.insert(buildingStatuses, true);
			else
				table.insert(buildingStatuses, tonumber(h)*60+tonumber(m));
			end
		else
			table.insert(buildingStatuses, false);
		end
		table.insert(buildingLevels, tonumber(n)); 
	end);

	self.buildingProgress={};
	table.foreachi(_HarvestEconomy.Buildings, function(bi, buildingName)
		for i=1,nprovinces do
			local idx=i+(bi-1)*nprovinces;
			self.provinces[self.provinceNumbers[i]].buildings=self.provinces[self.provinceNumbers[i]].buildings or {};
			self.provinces[self.provinceNumbers[i]].buildings[buildingName]=buildingLevels[idx];
			if buildingStatuses[idx] then
				table.insert(self.buildingProgress, {
					province=self.provinceNumbers[i],
					buildingName=buildingName,
					time=buildingStatuses[idx]
				});
			end
		end
	end);

	local researchLevels={};
	local researchStatuses={};
	string.gsub(dataResearches, ">(%d+)([%s<]?.-)</TD>", function(n, timer) 
		if StringUtil():starts(timer, "<font") then
			local h, m;
			string.gsub(timer, "(%d+):(%d+)", function (_h, _m) h=_h; m=_m; end);
			if not h then
				table.insert(researchStatuses, true);
			else
				table.insert(researchStatuses, tonumber(h)*60+tonumber(m));
			end
		else
			table.insert(researchStatuses, false);
		end
		table.insert(researchLevels, n); 
	end);
	self.researchProgress={};
	table.foreachi(_HarvestEconomy.Researches, function(ri, researchName)
		self.researches=self.researches or {};
		self.researches[researchName]=researchLevels[ri];
		if researchStatuses[ri] then
			table.insert(self.researchProgress, {
				researchName=researchName,
				time=researchStatuses[ri]
			});
		end
	end);
end

function _HarvestEconomy:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
	self.isExecuted=true;
end

function _HarvestEconomy:getProvinces()
	if not self.isExecuted then self:execute(); end
	return self.provinces;
end

function _HarvestEconomy:getProvincesCount()
	if not self.isExecuted then self:execute(); end
	return table.getn(self.provinces);
end

function _HarvestEconomy:getProvinceNumbers()
	if not self.isExecuted then self:execute(); end
	local provinces={}; -- clone province numbers
	table.foreachi(self.provinceNumbers, function(_, province)
		table.insert(provinces, province);
	end);
	return provinces;
end

function _HarvestEconomy:getProvinceNumbersSortedByDepotSize()
	if not self.isExecuted then self:execute(); end

	-- clone province numbers
	local provinceNumbers={};
	table.foreach(self.provinceNumbers, function(_, prNo)
		table.insert(provinceNumbers, prNo);
	end);

	-- sort province numbers by depot size
	table.sort(provinceNumbers, function(a, b)
		if self:getProvinceInfo(a).buildings["Depot Station"]>HarvestEconomy():getProvinceInfo(b).buildings["Depot Station"] then
			return true;
		end
	end);

	return provinceNumbers;
end


function _HarvestEconomy:getProvinceInfo(province)
	if not self.isExecuted then self:execute(); end
	return self.provinces[tonumber(province)];
end

function _HarvestEconomy:getProvinceResources(province)
	if not self.isExecuted then self:execute(); end
	return self.provinces[tonumber(province)].resources;
end

function _HarvestEconomy:getAllImperialResources()
	local provinceNumbers=self:getProvinceNumbers();
	local allResources={Wood=0, Iron=0, Stone=0, Gold=0};
	table.foreachi(provinceNumbers, function(_, prNo)
		local resources=self:getProvinceResources(prNo);
		table.foreachi(_HarvestEconomy.Resources, function(_, resourceName)
			allResources[resourceName]=allResources[resourceName]+resources[resourceName];
		end);
	end);
	return allResources;
end

function _HarvestEconomy:getProvinceBuildings(province)
	if not self.isExecuted then self:execute(); end
	return self:getProvinceInfo(tonumber(province)).buildings;
end

function _HarvestEconomy:getResearches()
	if not self.isExecuted then self:execute(); end
	return self.researches;
end

function _HarvestEconomy:getBuildingProgress()
	if not self.isExecuted then self:execute(); end
	return self.buildingProgress;
end

function _HarvestEconomy:getResearchProgress()
	if not self.isExecuted then self:execute(); end
	return self.researchProgress;
end

function _HarvestEconomy:isBuildingOrResearchReady()
	if not self.isExecuted then self:execute(); end
	if table.foreachi(self.buildingProgress, function(_, buildProgressInfo)
		if type(buildProgressInfo.time)=="boolean" then
			return true;
		end
	end) or 
	table.foreachi(self.researchProgress, function(_, researchProgressInfo)
		if type(researchProgressInfo.time)=="boolean" then
			return true;
		end
	end) then
		return true;
	end
end

function _HarvestEconomy:isProvinceReadyToBuild(provinceNo)
	if not self.isExecuted then self:execute(); end
	return not table.foreachi(self.buildingProgress, function(_, buildProgressInfo)
		if buildProgressInfo.province==provinceNo then
			return true;
		end
	end);
end

function _HarvestEconomy:isResearchReadyToBuild()
	if not self.isExecuted then self:execute(); end
	if table.getn(self.researchProgress) == 0 then
		return true;
	end
end

function _HarvestEconomy:dump()
	if not self.isExecuted then self:execute(); end
	local offset=35;
	table.foreach(self.provinces, function(pr, province)
		self:log_debug("\n\nPr. #"..pr);
		self:log_debug("---------------");
		table.foreachi(_HarvestEconomy.Resources, function(_, rname)
			io.write(rname.." "..self.provinces[pr].resources[rname].." "); 
		end);
		self:log_debug();
		table.foreachi(_HarvestEconomy.Buildings, function(_, bname)
			self:log_debug(bname.." "..string.rep("_", offset-string.len(bname))..self.provinces[pr].buildings[bname]);
		end);
	end);
	self:log_debug("\n\nResearches");
	self:log_debug("---------------");
	table.foreachi(_HarvestEconomy.Researches, function(_, rname)
		self:log_debug(rname.." "..string.rep("_", offset-string.len(rname))..self.researches[rname]);
	end);

	self:log_debug();
	table.foreachi(self.buildingProgress, function(_, buildProgressInfo)
		local progressInfo="Ready.";
		if type(buildProgressInfo.time) == "number" then
			progressInfo=DateUtil():minToHour(buildProgressInfo.time);
		end
		self:log_debug("Pr. #"..buildProgressInfo.province.." "..buildProgressInfo.buildingName.." "..progressInfo);
		
	end);
	table.foreachi(self.researchProgress, function(_, researchProgressInfo)
		local progressInfo="Ready.";
		if type(researchProgressInfo.time) == "number" then
			progressInfo=DateUtil():minToHour(researchProgressInfo.time);
		end
		self:log_debug(researchProgressInfo.researchName.." "..progressInfo);
	end);
end

function HarvestEconomy()
	_HarvestEconomy=_HarvestEconomy:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestEconomy;
end
