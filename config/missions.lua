-- Add your missions here
missions={
	-- Load resources to transports
	--LoadResources={
	--	interval_mins=30, -- time interval to start the mission
	--	random_offset_mins=10 -- interval precision deviation
	--},

	-- Make the gold positive
	--PositiveGold={
	--	interval_mins=10, -- time interval to start the mission
	--	random_offset_mins=5 -- interval precision deviation
	--},

	-- Click bonuses
	Bonus={
		interval_mins=5*60, -- time interval to start the mission
		random_offset_mins=60 -- interval precision deviation
	},

	-- Activate ready buildings or researches
	ActivateBuildings={
		interval_mins=30, -- time interval to start the mission
		random_offset_mins=10 -- interval precision deviation
	},

	-- Make a construction from the config/<username>-build.txt
	Construct={
		interval_mins=5, -- time interval to start the mission
		random_offset_mins=2 -- interval precision deviation
	},

	-- Set the new people to work
	Work={
		interval_mins=20, -- time interval to start the mission
		random_offset_mins=10 -- interval precision deviation
	},

	-- Set military task
	Military={
		interval_mins=5, -- time interval to start the mission
		random_offset_mins=1 -- interval precision deviation
	}
}
