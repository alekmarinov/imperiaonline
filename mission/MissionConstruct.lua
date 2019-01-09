_MissionConstruct=_MissionConstruct or 
{
	LOAD_RESOURCES_DELAY=25,
	lastLoadResources=os.time()
}


function MissionConstruct()
	if not HarvestAntiSpy():isUnderAttack() then -- skip construction while we are under attack
		if not BuildLogic():buildAny() then
			-- if unable to build anything then proceed with MissionLoadResources

			-- check if at least 25 mins has been passed since the last resource loading
			if os.time()-_MissionConstruct.lastLoadResources>_MissionConstruct.LOAD_RESOURCES_DELAY*60 then
				execute_mission("LoadResources");
				_MissionConstruct.lastLoadResources=os.time();
			end
		end
	end
end
