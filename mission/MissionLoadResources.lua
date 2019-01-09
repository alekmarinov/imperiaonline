function MissionLoadResources()
	Action():go("TransportUnload");

	-- refresh iconomics information
	HarvestEconomy():execute();

	-- more than 1 provinces are necessary to transport
	if HarvestEconomy():getProvincesCount()>1 then

		-- clone province numbers
		local provinces=HarvestEconomy():getProvinceNumbersSortedByDepotSize();

		-- transport all to the 1st province from the list
		local transportInfo={tprovince=provinces[1]};
		table.foreachi(provinces, function(i, province)
			if i>1 then
				transportInfo.province=province;
				Action():go("Transport", transportInfo);
			end
		end);

		-- transport all from the 1st province to the 2nd
		Action():go("Transport", {province=provinces[1], tprovince=provinces[2]});
	end
end
