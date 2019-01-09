function MissionWork()
	table.foreachi(HarvestEconomy():getProvinceNumbers(), function(_, province)
		Action():go("Work", {province=province});
	end);
end
