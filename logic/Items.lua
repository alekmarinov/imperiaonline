require("util.Class");

_Items=Class
{
	type="Items",

	RESOURCES=
	{
		["Wood"]="�����",
		["Iron"]="������",
		["Stone"]="�����",
		["Gold"]="�����"
	},

	BUILDINGS=
	{
		["Farm"]="�����",
		["Lumbermill"]="������������",
		["Iron mine"]="���� ������",
		["Stone quarry"]="������� �������",
		["Granary"]="���������� �������",
		["Depot Station"]="������� �������",
		["Infantry barracks"]="������� ������",
		["Shooting Range"]="������� �������",
		["Cavalry barracks"]="������� ���������",
		["Siege workshop"]="������� ������",
		["Fortresses"]="�������"
	},
	
	RESEARCHES=
	{
		["Range attack"]="����� � �������",
		["Melee attack"]="����� - ����",
		["War horses"]="����� ����",
		["Armor"]="�����",
		["University"]="�����������",
		["Centralization"]="�������������� �����",
		["Bureaucracy"]="����������",
		["Architecture"]="�����������",
		["Medicine"]="��������",
		["Trade"]="��������",
		["Tactics"]="�������",
		["Fortification"]="������������",
		["Military Academy"]="������ ��������",
		["Military Architecture"]="������ �����������",
		["Military Medicine"]="������ ��������",
		["Spying"]="�������",
		["Border outposts"]="�������� �������",
		["Cartography"]="�����������"
	},

	ARMY=
	{
		["Spearman"]="����������",
		["Archer"]="�������",
		["Swordsman"]="���������",
		["Light cavalryman"]="��� ������",
		["Battering ram"]="�����",
		["Heavy spearman"]="����� ����������",
		["Heavy archer"]="����� �������",
		["Heavy swordsman"]="����� ���������",
		["Heavy cavalryman"]="����� ������",
		["Catapult"]="��������",
		["Phalanx"]="�������",
		["Elite archer"]="������ �������",
		["Guardian"]="��������",
		["Paladin"]="�������",
		["Trebuchet"]="��������"
	},

	ARMIES=
	{
		["Spearman"]="����������",
		["Archer"]="�������",
		["Swordsman"]="���������",
		["Light cavalryman"]="���� �������",
		["Battering ram"]="������",
		["Heavy spearman"]="����� ����������",
		["Heavy archer"]="����� �������",
		["Heavy swordsman"]="����� ���������",
		["Heavy cavalryman"]="����� �������",
		["Catapult"]="���������",
		["Phalanx"]="�������",
		["Elite archer"]="������ �������",
		["Guardian"]="���������",
		["Paladin"]="��������",
		["Trebuchet"]="���������"
	},

	GARRISON="Garrison",

	WORKSHOPS={
		["Lumbermill"]="������������",
		["Iron mine"]="���� ������",
		["Stone quarry"]="������� �������"
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
