require("util.FileUtil");
require("util.DateUtil");
require("util.StringUtil");
require("logger.LoggingClass");
require("imperiaonline.net.HttpBrowser");
require("imperiaonline.harvest.AbstractHarvest");
require("imperiaonline.logic.Items");

_HarvestProvinces=Class
{
	type="HarvestProvinces",
	URI_PROVINCES="/imperia/game/pmap.php?map=local&log=no",

	TERRAIN={
		["Равнинен"]="Plains",
		["Равнинно-горист"]="Plains with forests",
		["Планински"]="Hills",
		["Планинско-горист"]="Hills with forests",
		["Хълмист"]="Mountains",
		["Хълмисто-горист"]="Mountains with forests",
	},

-- Cavalry attack
-- Archers attack
-- Defense
-- Fortress
-- Population growth
-- Wood production
-- Iron Production
-- Stone production
-- Efficiency
	TERRAIN_BONUS={
		["Plains"]={20, 0, 0, -20, 50, 0, 0, 0},
		["Plains with forests"]={-10, -20, 10, -20, 20, 25, 0, 0},
		["Hills"]={-20, 20, 20, 20, -30, 0, 20, 20},
		["Hills with forests"]={0, 0, 25, 20, -40, 25, 20, 20},
		["Mountains"]={0, 10, 10, 10, 0, 0, 0, 0},
		["Mountains with forests"]={-10, -10, 15, 10, 0, 25, 0, 0}
	}
};

function _HarvestProvinces:download(province)
	self.data=HttpBrowser():get(_HarvestProvinces.URI_PROVINCES);
	--FileUtil():writeAll("provinces.html", self.data);
end

function _HarvestProvinces:parse()
	self.provinces={};
	local pattern=">(%S+)<BR><BR>.-href='showprovince.php%?u_id=%d+&p_nomer=(%d+)";
	string.gsub(self.data, pattern, function(terrain, province)
		self.provinces[tonumber(province)]=_HarvestProvinces.TERRAIN[terrain];
	end);
end

function _HarvestProvinces:execute()
	self:log_debug("harvesting");
	self:download();
	self:parse();
	self.isExecuted=true;
end

function _HarvestProvinces:getProvinceTerrain(prNo)
	return self.provinces[prNo];
end

function _HarvestProvinces:getTerrainBonuses(terrain)
	return _HarvestProvinces.TERRAIN_BONUS[terrain];
end

function _HarvestProvinces:isProvinceSurrounded(prNo)
	local provinceNumbers=HarvestEconomy():getProvinceNumbers();
	local function hasProvince(pr)
		return table.foreachi(provinceNumbers, function(_, _pr)
			if pr == _pr then
				return true;
			end
		end);
	end

	return hasProvince(prNo+1) and hasProvince(prNo-1) and hasProvince(prNo+5) and hasProvince(prNo-5);
end

function _HarvestProvinces:getStrongestProvinces()
	local provinces=HarvestEconomy():getProvinceNumbers();
	local terrainStrength={
		[_Items.TERRAIN_PLAINS]=1,
		[_Items.TERRAIN_PLAINS_FOREST]=2,
		[_Items.TERRAIN_MOUNTAINS_FOREST]=3,
		[_Items.TERRAIN_MOUNTAINS]=4,
		[_Items.TERRAIN_HILLS_FOREST]=5,
		[_Items.TERRAIN_HILLS]=6,
	};

	table.sort(provinces, function(prA, prB)
		local ratingA=terrainStrength[self:getProvinceTerrain(prA)];
		local ratingB=terrainStrength[self:getProvinceTerrain(prA)];

		if self:isProvinceSurrounded(prA) then
			ratingA=ratingA*100;
		end

		if self:isProvinceSurrounded(prB) then
			ratingB=ratingB*100;
		end

		ratingA=ratingA+10*HarvestEconomy():getProvinceBuildings(prA).Fortresses;
		ratingB=ratingB+10*HarvestEconomy():getProvinceBuildings(prB).Fortresses;

		-- FIXME: add population count in the comparison
		if ratingA>ratingB then
			return true;
		end
	end);

	return provinces;
end

function _HarvestProvinces:dump()
	if not self.isExecuted then self:execute(); end
	table.foreach(self.provinces, function(province, terrain)
		print(province, terrain);
	end);
end

function HarvestProvinces()
	_HarvestProvinces=_HarvestProvinces:inherit(AbstractHarvest(), LoggingClass());
	return _HarvestProvinces;
end
