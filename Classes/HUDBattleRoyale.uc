class HUDBattleRoyale extends ONSHUDOnslaught;

var FinalBlend BusIcon;

simulated function DrawHudPassA (Canvas C)
{
    super(HudCDeathMatch).DrawHudPassA(C);
}

simulated function DrawHudPassC (Canvas C)
{
    local float RadarWidth, CenterRadarPosX, CenterRadarPosY;
    super(HudCDeathMatch).DrawHudPassC(C);

    if (Level.bShowRadarMap && !bMapDisabled)
    {
        RadarWidth = 0.5 * RadarScale * HUDScale * C.ClipX;
        CenterRadarPosX = (RadarPosX * C.ClipX) - RadarWidth;
        CenterRadarPosY = (RadarPosY * C.ClipY) + RadarWidth;
        DrawRadarMap(C, CenterRadarPosX, CenterRadarPosY, RadarWidth, false);
    }
}
simulated function DrawSpectatingHud (Canvas C)
{
    local float RadarWidth, CenterRadarPosX, CenterRadarPosY;
	Super.DrawSpectatingHud(C);
    if (Level.bShowRadarMap && !bMapDisabled)
    {
        RadarWidth = 0.5 * RadarScale * HUDScale * C.ClipX;
        CenterRadarPosX = (RadarPosX * C.ClipX) - RadarWidth;
        CenterRadarPosY = (RadarPosY * C.ClipY) + RadarWidth;
        DrawRadarMap(C, CenterRadarPosX, CenterRadarPosY, RadarWidth, false);
    }
}
/*
simulated function DrawMyScore ( Canvas C )
{
}
*/

simulated function UpdateHud()
{
    super(HudCDeathMatch).UpdateHud();
}

simulated function DrawRadarMap(Canvas C, float CenterPosX, float CenterPosY, float RadarWidth, bool bShowDisabledNodes)
{
    local BRGameReplicationInfo BRI;
    super.DrawRadarMap(C, CenterPosX, CenterPosY, RadarWidth, bShowDisabledNodes);
    BRI = BRGameReplicationInfo(Level.GRI);
    if(BRI != None)
    {
        if(BRI.Storm != None)
            DrawStormZone(C, BRI.Storm, CenterPosX, CenterPosY, RadarWidth);
        if(BRI.Bus != None)
            class'RadarMapUtils'.static.DrawRadarMap(C, self, BRI.Bus, BusIcon, CenterPosX, CenterPosY, RadarWidth);
    }
}

simulated function DrawStormZone(Canvas C, StormZone storm, float CenterPosX, float CenterPosY, float RadarWidth)
{
    local vector HUDLocation;
    local FinalBlend StormFB, StormNextFB;
    local float CircleScale;
    local float MapScale, MapRadarWidth, TexSize, TexFudge;
    local Color BackColor;

	C.Style = ERenderStyle.STY_Alpha;
    BackColor.A = 255;

	MapRadarWidth = RadarWidth;
    if (PawnOwner != None)
    {
//    	MapCenter.X = FClamp(PawnOwner.Location.X, -RadarMaxRange + RadarRange, RadarMaxRange - RadarRange);
//    	MapCenter.Y = FClamp(PawnOwner.Location.Y, -RadarMaxRange + RadarRange, RadarMaxRange - RadarRange);
        MapCenter.X = 0.0;
        MapCenter.Y = 0.0;
    }
    else
        MapCenter = vect(0,0,0);

	HUDLocation.X = RadarWidth;
	HUDLocation.Y = RadarRange;
	HUDLocation.Z = RadarTrans;    
    MapScale = MapRadarWidth/RadarRange;    
    TexSize=1024.0;
    TexFudge=0.1;

    if (storm != None)
    {
        // Final Blend (Combiner): 
        //   TexScaler (shift/pan) -> TexScaler (scaling) -> Circle Texture
        //   Transparent Texture
        StormFB = FinalBlend'BattleRoyaleTex.Storm.StormFB';
        CircleScale=fmax(1.05,storm.ZoneRadius/(RadarRange*TexFudge)); // found empirically
        TexScaler(TexScaler(Combiner(StormFB.Material).Material1).Material).UScale=CircleScale;
        TexScaler(TexScaler(Combiner(StormFB.Material).Material1).Material).VScale=CircleScale;
        TexScaler(TexScaler(Combiner(StormFB.Material).Material1).Material).UOffset=TexSize * 0.5 - (TexSize / ( 2 * CircleScale) );
        TexScaler(TexScaler(Combiner(StormFB.Material).Material1).Material).VOffset=TexSize * 0.5 - (TexSize / ( 2 * CircleScale) );
        TexScaler(Combiner(StormFB.Material).Material1).UOffset=-storm.Location.X * 0.5 / RadarRange * TexSize;
        TexScaler(Combiner(StormFB.Material).Material1).VOffset=-storm.Location.Y * 0.5  / RadarRange * TexSize;
        DrawMapImage(C, StormFB, CenterPosX, CenterPosY, MapCenter.X, MapCenter.Y, HUDLocation);
        //debug!
        //class'RadarMapUtils'.static.DrawRadarMap(C, self, storm, FinalBlend'BattleRoyaleTex.Bomber.DropshipIconFB', CenterPosX, CenterPosY, RadarWidth);       

        if(storm.bShrinking)
        {
            StormNextFB = FinalBlend'BattleRoyaleTex.Storm.StormNextFB';
            CircleScale=fmax(1.05,storm.TargetRadius/(RadarRange*TexFudge)); // found empirically
            TexScaler(TexScaler(Combiner(StormNextFB.Material).Material1).Material).UScale=CircleScale;
            TexScaler(TexScaler(Combiner(StormNextFB.Material).Material1).Material).VScale=CircleScale;
            TexScaler(TexScaler(Combiner(StormNextFB.Material).Material1).Material).UOffset=TexSize * 0.5 - (TexSize / ( 2 * CircleScale) );
            TexScaler(TexScaler(Combiner(StormNextFB.Material).Material1).Material).VOffset=TexSize * 0.5 - (TexSize / ( 2 * CircleScale) );
            TexScaler(Combiner(StormNextFB.Material).Material1).UOffset=-storm.TargetLocation.X * 0.5 / RadarRange * TexSize;
            TexScaler(Combiner(StormNextFB.Material).Material1).VOffset=-storm.TargetLocation.Y * 0.5 / RadarRange * TexSize;
            DrawMapImage(C, StormNextFB, CenterPosX, CenterPosY, MapCenter.X, MapCenter.Y, HUDLocation);
        }
    }
}

defaultproperties
{
    BusIcon=FinalBlend'BattleRoyaleTex.Bomber.DropshipIconFB'

}