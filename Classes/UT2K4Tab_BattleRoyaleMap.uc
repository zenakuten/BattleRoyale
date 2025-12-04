class UT2K4Tab_BattleRoyaleMap extends UT2K4Tab_OnslaughtMap;

var FinalBlend BusIcon;

function bool DrawMap(Canvas C)
{
    local ONSHUDOnslaught ONSHUD;
    local BRGameReplicationInfo BRI;
    local float RadarWidth, CenterRadarPosX, CenterRadarPosY;
    local LevelInfo Level;

    super.DrawMap(C);

    Level = PlayerOwner().Level;
    ONSHUD = ONSHudOnslaught(PlayerOwner().myHud);
    BRI = BRGameReplicationInfo(Level.GRI);
    if(ONSHUD != None 
        && BRI != None
        && ONSHUD.PlayerOwner != None 
        && !ONSHUD.PlayerOwner.IsInState('Dead'))
        //&& !ONSHUD.PlayerOwner.IsInState('PlayerWaiting'))
    {
        if (Level.bShowRadarMap && !ONSHUD.bMapDisabled)
        {
            RadarWidth = 0.5 * ONSHUD.RadarScale * ONSHUD.HUDScale * C.ClipX;
            CenterRadarPosX = (ONSHUD.RadarPosX * C.ClipX) - RadarWidth;
            CenterRadarPosY = (ONSHUD.RadarPosY * C.ClipY) + RadarWidth;
            class'RadarMapUtils'.static.DrawRadarMap(C, ONSHUD, BRI.Bus, BusIcon, CenterRadarPosX, CenterRadarPosY, RadarWidth);
        }        
    }

    return true;
}

defaultproperties
{
    BusIcon=FinalBlend'BattleRoyaleTex.Bomber.DropshipIconFB'
}