function MissionMilitary(params)
	AttackLogic():execute();
	SeekTargetsLogic():execute();
	if HarvestAntiSpy():isUnderAttack() then
		DefendLogic():execute();
	elseif params.tactic == "economy" then
		DisperseArmyLogic():execute();
	elseif params.tactic == "defense" then
		ConcentrateArmyLogic():execute(_ConcentrateArmyLogic.ARMY, nil);
	elseif params.tactic == "aggressive" then
		AttackTargetLogic():execute();
	end
	DefendLogic():killSpies();
end
