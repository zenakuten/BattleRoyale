class MutBattleRoyale extends DMMutator
	HideDropDown
	CacheExempt;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local BattleRoyale BRYGame;

	BRYGame = BattleRoyale(Level.Game);

	if(BRYGame == None)
	{
		Log("Should only use MutBattleRoyale with BattleRoyale game type.");
		bSuperRelevant = 0;
		return true;
	}

	// Remove conventional weapon pickups. Leave super weapons, all ammo etc.
	if ( Other.IsA('Pickup') )
	{
    	if (!BRYGame.bAllowPickups)
	    	return !Level.bStartup;

		if (Other.IsA('AdrenalinePickup') && !BRYGame.bAllowAdrenaline)
        	return false;

		if( Other.IsA('WeaponPickup') )
		{
			if( BRYGame.bAllowSuperweapons && (Other.IsA('PainterPickup') || Other.IsA('RedeemerPickup')) )
			{
				bSuperRelevant = 0;
				return true;
			}
			else
				return !Level.bStartup;
		}
		else
		{
			bSuperRelevant = 0;
			return true;
		}
	}

    if(Other.IsA('GameObjective'))
    {
        GameObjective(Other).DefenderTeamIndex = 0;
        GameObjective(Other).StartTeam = 0;
    }
    if(Other.IsA('ONSVehicleFactory'))
    {
        ONSVehicleFactory(Other).TeamNum = 0;
    }
    if(Other.IsA('Vehicle'))
    {
        Vehicle(Other).Team = 0;
        Vehicle(Other).OldTeam = 0;
        Vehicle(Other).PrevTeam = 0;
    }

	// Hide all weapon bases apart from super weapons
	if ( Other.IsA('xPickupBase') )
	{
		if ( Other.IsA('xWeaponBase') )
        {
            if( BRYGame.bAllowSuperweapons && (xWeaponBase(Other).WeaponType == class'Painter' || xWeaponBase(Other).WeaponType == class'Redeemer') )
                Other.bHidden = false;
            else
                Other.bHidden = true;
        }
        else if (!BRYGame.bAllowPickups)
        	Other.bHidden = true;

	}
    if(Other.IsA('Vehicle'))
    {
        Vehicle(Other).bTeamLocked=false;
    }

	bSuperRelevant = 0;
	return true;
}