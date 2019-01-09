require("util.Class");

_Items=Class
{
	type="Items",

	RESOURCES=
	{
		["Wood"]="Дърво",
		["Iron"]="Желязо",
		["Stone"]="Камък",
		["Gold"]="Злато"
	},

	BUILDINGS=
	{
		["Farm"]="Ферма",
		["Lumbermill"]="Дърводелница",
		["Iron mine"]="Мина желязо",
		["Stone quarry"]="Каменна кариера",
		["Granary"]="Обществени хамбари",
		["Depot Station"]="Товарна Станция",
		["Infantry barracks"]="Казарма пехота",
		["Shooting Range"]="Казарма стрелци",
		["Cavalry barracks"]="Казарма Кавалерия",
		["Siege workshop"]="Обсадни оръжия",
		["Fortresses"]="Крепост"
	},
	
	RESEARCHES=
	{
		["Range attack"]="Атака – Стрелец",
		["Melee attack"]="Атака - Меле",
		["War horses"]="Бойни коне",
		["Armor"]="Брони",
		["University"]="Университет",
		["Centralization"]="Централизирана власт",
		["Bureaucracy"]="Бюрокрация",
		["Architecture"]="Архитектура",
		["Medicine"]="Медицина",
		["Trade"]="Търговия",
		["Tactics"]="Тактики",
		["Fortification"]="Фортификация",
		["Military Academy"]="Военна Академия",
		["Military Architecture"]="Военна Архитектура",
		["Military Medicine"]="Военна Медицина",
		["Spying"]="Шпионаж",
		["Border outposts"]="Гранични постове",
		["Cartography"]="Картография"
	},

	ARMY=
	{
		["Spearman"]="Копиеносец",
		["Archer"]="Стрелец",
		["Swordsman"]="Мечоносец",
		["Light cavalryman"]="Лек Конник",
		["Battering ram"]="Таран",
		["Heavy spearman"]="Тежък Копиеносец",
		["Heavy archer"]="Тежък Стрелец",
		["Heavy swordsman"]="Тежък Мечоносец",
		["Heavy cavalryman"]="Тежьк Конник",
		["Catapult"]="Катапулт",
		["Phalanx"]="Фаланга",
		["Elite archer"]="Елитен Стрелец",
		["Guardian"]="Гвардеец",
		["Paladin"]="Паладин",
		["Trebuchet"]="Требучет"
	},

	ARMIES=
	{
		["Spearman"]="Копиеносци",
		["Archer"]="Стрелци",
		["Swordsman"]="Мечоносци",
		["Light cavalryman"]="Лека конница",
		["Battering ram"]="Тарани",
		["Heavy spearman"]="Тежки копиеносци",
		["Heavy archer"]="Тежки стрелци",
		["Heavy swordsman"]="Тежки мечоносци",
		["Heavy cavalryman"]="Тежка конница",
		["Catapult"]="Катапулти",
		["Phalanx"]="Фаланги",
		["Elite archer"]="Елитни Стрелци",
		["Guardian"]="Гвардейци",
		["Paladin"]="Паладини",
		["Trebuchet"]="Требучети"
	},

	GARRISON="Garrison",

	WORKSHOPS={
		["Lumbermill"]="Дърводелница",
		["Iron mine"]="Мина желязо",
		["Stone quarry"]="Каменна кариера"
	},

	ITEM_TYPE=
	{
		"RESOURCES",
		"BUILDINGS",
		"RESEARCHES",
		"ARMY",
		"WORKSHOPS"
	},

	WOOD  = "Wood",
	IRON  = "Iron",
	STONE = "Stone",
	GOLD  = "Gold",

	TERRAIN_PLAINS="Plains",
	TERRAIN_PLAINS_FOREST="Plains with forests",
	TERRAIN_HILLS="Hills",
	TERRAIN_HILLS_FOREST="Hills with forests",
	TERRAIN_MOUNTAINS="Mountains",
	TERRAIN_MOUNTAINS_FOREST="Mountains with forests",
}

function _Items:getItemType(itemName)
	return table.foreachi(_Items.ITEM_TYPE, function (_, itemType)
		return table.foreach(_Items[itemType], function(_itemName, _)
			if _itemName == itemName then
				return itemType;
			end
		end);
	end);
end

function Items()
	return _Items;
end
