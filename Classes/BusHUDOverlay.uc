class BusHUDOverlay extends HUDOverlay;

var Actor Bus;
var FinalBlend BusIcon;

simulated function Render(Canvas C)
{
    local ONSHUDOnslaught ONSHUD;
    local float RadarWidth, CenterRadarPosX, CenterRadarPosY;

    ONSHUD = ONSHUDOnslaught(Owner);
    if(ONSHUD != None 
        && ONSHUD.PlayerOwner != None 
        && !ONSHUD.PlayerOwner.IsInState('Dead')
        && !ONSHUD.PlayerOwner.IsInState('PlayerWaiting'))
    {
        if (Level.bShowRadarMap && !ONSHUD.bMapDisabled)
        {
            RadarWidth = 0.5 * ONSHUD.RadarScale * ONSHUD.HUDScale * C.ClipX;
            CenterRadarPosX = (ONSHUD.RadarPosX * C.ClipX) - RadarWidth;
            CenterRadarPosY = (ONSHUD.RadarPosY * C.ClipY) + RadarWidth;
            //class'RadarMapUtils'.static.DrawRadarMap(C, ONSHUD, Bus, BusIcon, CenterRadarPosX, CenterRadarPosY, RadarWidth);
        }        
    }
}

defaultproperties
{
    BusIcon=FinalBlend'BattleRoyaleTex.Bomber.DropshipIconFB'
}