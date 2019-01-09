require("imperiaonline.net.HttpBrowser");
require("imperiaonline.action.AbstractAction");
require("imperiaonline.harvest.HarvestEconomy");
require("imperiaonline.logic.Items");
require("logger.LoggingClass");

_ConstructAction = Class
{
	type="ConstructAction",
	URI_BUILD_CONSTRUCTION="/imperia/game/constructions.php?tip=c&build_id=",
	URI_BUILD_RESEARCH="/imperia/game/constructions.php?tip=r&build_id=",
	BUILDING_NO={
		["Farm"]=1,
		["Lumbermill"]=2,
		["Iron mine"]=3,
		["Stone quarry"]=4,
		["Granary"]=5,
		["Depot Station"]=6,
		["Infantry barracks"]=7,
		["Shooting Range"]=8,
		["Cavalry barracks"]=9,
		["Siege workshop"]=10,
		["Fortresses"]=12
	},
	RESEARCH_NO={
		["Range attack"]=13,
		["Melee attack"]=14,
		["War horses"]=15,
		["Armor"]=16,
		["University"]=17,
		["Centralization"]=18,
		["Bureaucracy"]=19,
		["Architecture"]=20,
		["Medicine"]=21,
		["Trade"]=22,
		["Tactics"]=23,
		["Fortification"]=24,
		["Military Academy"]=25,
		["Military Architecture"]=26,
		["Military Medicine"]=27,
		["Spying"]=28,
		["Border outposts"]=29,
		["Cartography"]=31
	}
};

function _ConstructAction:execute(param)
	local itemType=Items():getItemType(param.itemName);
	local isReadyToBuild;
	local buildUri;
	local nameToIdMap;

	if itemType == "BUILDINGS" then
		isReadyToBuild=HarvestEconomy():isProvinceReadyToBuild(param.province);
		buildUri=_ConstructAction.URI_BUILD_CONSTRUCTION;
		nameToIdMap=_ConstructAction.BUILDING_NO;
	elseif itemType == "RESEARCHES" then
		isReadyToBuild=HarvestEconomy():isResearchReadyToBuild();
		buildUri=_ConstructAction.URI_BUILD_RESEARCH;
		nameToIdMap=_ConstructAction.RESEARCH_NO;
	end

	if isReadyToBuild then
		Action():go("Province", param);
		HttpBrowser():browse(buildUri..nameToIdMap[param.itemName]);
		HarvestEconomy():execute();
	end

	if itemType == "BUILDINGS" and not HarvestEconomy():isProvinceReadyToBuild(param.province) then
		return true;
	elseif itemType == "RESEARCHES" and not HarvestEconomy():isResearchReadyToBuild() then
		return true;
	end

	if TEST then
		return true;
	end
end

function ConstructAction()
	return _ConstructAction:inherit(AbstractAction(), LoggingClass());
end
