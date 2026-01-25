//class HUDBattleRoyale extends ONSHUDOnslaught;
// i don't want this dependency but easiest way to get damage indicators to work
// todo fix utcomp to use overlay instead
class HUDBattleRoyale extends UTComp_ONSHudOnslaught;

var FinalBlend BusIcon;// Timer

var() NumericWidget StormTimerHours;
var() NumericWidget StormTimerMinutes;
var() NumericWidget StormTimerSeconds;
var() SpriteWidget StormTimerDigitSpacer[2];
var() SpriteWidget StormTimerIcon;
var() SpriteWidget StormTimerBackground;
var() SpriteWidget StormTimerBackgroundDisc;

var bool bShowDebug;

simulated function DrawHudPassA (Canvas C)
{
    super(HudCDeathMatch).DrawHudPassA(C);
    DrawStormTimer(C);
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
	Super(HudCDeathMatch).DrawSpectatingHud(C);
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

function DrawEnemyName(Canvas C)
{
    if(PawnOwner == None || PawnOwner.PlayerReplicationInfo == None)
        return;

    super.DrawEnemyName(C);
}

simulated function PostRender(Canvas C)
{
    super.PostRender(C);

    if(bShowDebug)
        DrawDebug(C);
}

simulated function DrawDebug(Canvas C)
{
    local float XPos, YPos;
    local plane OldModulate;
    local color OldColor;
    local BRGameReplicationInfo BRI;
    local float XL, YL;

    OldModulate = C.ColorModulate;
    OldColor = C.DrawColor;

    C.ColorModulate.X = 1;
    C.ColorModulate.Y = 1;
    C.ColorModulate.Z = 1;
    C.ColorModulate.W = HudOpacity/255;

    ResScaleX = C.SizeX / 640.0;
    ResScaleY = C.SizeY / 480.0;    
    C.Font = class'HUD'.static.GetConsoleFont(C);
    C.Style = ERenderStyle.STY_Alpha;
    C.DrawColor = ConsoleColor;
    PlayerOwner.ViewTarget.DisplayDebug(C, XPos, YPos);

    BRI = BRGameReplicationInfo(Level.GRI);
    if(BRI == None)
        return;

    C.StrLen("TEST", XL, YL);
    YPos += YL;
    C.SetPos(4, YPos);
    C.SetDrawColor(255,255,255);
    C.DrawText("Storm:");
    YPos += YL;
    C.SetPos(4, YPos);
    C.DrawText("Location: "$BRI.Storm.Location$" Rotation "$BRI.Storm.Rotation, false);
	YPos += YL;
	C.SetPos(4,YPos);
	C.DrawText("Velocity: "$BRI.Storm.Velocity$" Speed "$VSize(BRI.Storm.Velocity)$" Speed2D "$VSize(BRI.Storm.Velocity-BRI.Storm.Velocity.Z*vect(0,0,1)), false);
	YPos += YL;
	C.SetPos(4,YPos);
	C.DrawText("Radius: "$BRI.Storm.ZoneRadius$" Scale"$BRI.Storm.DrawScale3D$" Damage "$BRI.Storm.DamageValue());
    C.DrawActor(BRI.Storm,true);
    
    YPos += YL;
    C.SetPos(4, YPos);
    C.SetDrawColor(255,0,255);
    C.DrawText("Bus:");
    YPos += YL;
    C.SetPos(4, YPos);
    C.DrawText("Location: "$BRI.Bus.Location$" Rotation "$BRI.Bus.Rotation, false);
	YPos += YL;
	C.SetPos(4,YPos);
	C.DrawText("Velocity: "$BRI.Bus.Velocity$" Speed "$VSize(BRI.Bus.Velocity)$" Speed2D "$VSize(BRI.Bus.Velocity-BRI.Bus.Velocity.Z*vect(0,0,1)), false);
}

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

simulated function DrawStormTimer(Canvas C)
{
	local BRGameReplicationInfo BRI;
    local float dur;
	local int Minutes, Hours, Seconds;
    local int shift;

    BRI = BRGameReplicationInfo(PlayerOwner.GameReplicationInfo);
    if(BRI != None)
    {
        if(BRI.Storm != None)
        {
            dur = BRI.Storm.GetInfo().StormDuration;
            Seconds = Max(0,dur - (BRI.Storm.TimeSeconds - BRI.Storm.StartTime));
        }
    }

	StormTimerBackground.Tints[TeamIndex] = HudColorBlack;
    StormTimerBackground.Tints[TeamIndex].A = 150;

    shift = C.ClipX * 0.5 - 4;

    StormTimerBackground.OffsetX = default.StormTimerBackground.OffsetX + shift - 210;
    StormTimerBackgroundDisc.OffsetX = default.StormTimerBackgroundDisc.OffsetX + shift - 392;
    StormTimerIcon.OffsetX = default.StormTimerIcon.OffsetX + shift - 400 - 12;

	DrawSpriteWidget( C, StormTimerBackground);
	DrawSpriteWidget( C, StormTimerBackgroundDisc);
	DrawSpriteWidget( C, StormTimerIcon);

	StormTimerMinutes.OffsetX = default.StormTimerMinutes.OffsetX - 96 + shift;
	StormTimerSeconds.OffsetX = default.StormTimerSeconds.OffsetX - 96 + shift;
	StormTimerDigitSpacer[0].OffsetX = Default.StormTimerDigitSpacer[0].OffsetX + shift - 204;
	StormTimerDigitSpacer[1].OffsetX = Default.StormTimerDigitSpacer[1].OffsetX + shift - 204;

	if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

		DrawNumericWidget( C, StormTimerHours, DigitsBig);
        StormTimerHours.Value = Hours;

		if(Hours>9)
		{
			StormTimerMinutes.OffsetX = default.StormTimerMinutes.OffsetX + shift;
			StormTimerSeconds.OffsetX = default.StormTimerSeconds.OffsetX + shift;
		}
		else
		{
			StormTimerMinutes.OffsetX = default.StormTimerMinutes.OffsetX -56 + shift;
			StormTimerSeconds.OffsetX = default.StormTimerSeconds.OffsetX -56 + shift;
			StormTimerDigitSpacer[0].OffsetX = Default.StormTimerDigitSpacer[0].OffsetX - 32 + shift - 204;
			StormTimerDigitSpacer[1].OffsetX = Default.StormTimerDigitSpacer[1].OffsetX - 32 + shift - 202;
		}
		DrawSpriteWidget( C, StormTimerDigitSpacer[0]);
	}
	DrawSpriteWidget( C, StormTimerDigitSpacer[1]);

	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    StormTimerMinutes.Value = Min(Minutes, 60);
	StormTimerSeconds.Value = Min(Seconds, 60);

	DrawNumericWidget( C, StormTimerMinutes, DigitsBig);
	DrawNumericWidget( C, StormTimerSeconds, DigitsBig);
}

simulated function DrawTimer(Canvas C)
{
	local BRGameReplicationInfo BRI;
	local int Minutes, Hours, Seconds;

	BRI = BRGameReplicationInfo(PlayerOwner.GameReplicationInfo);

	if ( BRI.bWarmup )
		Seconds = BRI.WarmupTimer;
	else
		//Seconds = BRI.ElapsedTime;
		Seconds = BRI.GameTimer;

	TimerBackground.Tints[TeamIndex] = HudColorBlack;
    TimerBackground.Tints[TeamIndex].A = 150;

	DrawSpriteWidget( C, TimerBackground);
	DrawSpriteWidget( C, TimerBackgroundDisc);
	DrawSpriteWidget( C, TimerIcon);

	TimerMinutes.OffsetX = default.TimerMinutes.OffsetX - 80;
	TimerSeconds.OffsetX = default.TimerSeconds.OffsetX - 80;
	TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX;
	TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX;

	if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

		DrawNumericWidget( C, TimerHours, DigitsBig);
        TimerHours.Value = Hours;

		if(Hours>9)
		{
			TimerMinutes.OffsetX = default.TimerMinutes.OffsetX;
			TimerSeconds.OffsetX = default.TimerSeconds.OffsetX;
		}
		else
		{
			TimerMinutes.OffsetX = default.TimerMinutes.OffsetX -40;
			TimerSeconds.OffsetX = default.TimerSeconds.OffsetX -40;
			TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX - 32;
			TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX - 32;
		}
		DrawSpriteWidget( C, TimerDigitSpacer[0]);
	}
	DrawSpriteWidget( C, TimerDigitSpacer[1]);

	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    TimerMinutes.Value = Min(Minutes, 60);
	TimerSeconds.Value = Min(Seconds, 60);

	DrawNumericWidget( C, TimerMinutes, DigitsBig);
	DrawNumericWidget( C, TimerSeconds, DigitsBig);
}

defaultproperties
{
    BusIcon=FinalBlend'BattleRoyaleTex.Bomber.DropshipIconFB'
    bDrawTimer=true
    bShowDebug=false

    StormTimerHours=(RenderStyle=STY_Alpha,TextureScale=0.320000,DrawPivot=DP_MiddleLeft,OffsetX=90,OffsetY=45,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    StormTimerMinutes=(RenderStyle=STY_Alpha,MinDigitCount=2,TextureScale=0.320000,DrawPivot=DP_MiddleLeft,OffsetX=170,OffsetY=45,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255),bPadWithZeroes=1)
    StormTimerSeconds=(RenderStyle=STY_Alpha,MinDigitCount=2,TextureScale=0.320000,DrawPivot=DP_MiddleLeft,OffsetX=250,OffsetY=45,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255),bPadWithZeroes=1)
    StormTimerDigitSpacer(0)=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=495,Y1=91,X2=503,Y2=112),TextureScale=0.400000,DrawPivot=DP_MiddleLeft,OffsetX=194,OffsetY=36,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    StormTimerDigitSpacer(1)=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=495,Y1=91,X2=503,Y2=112),TextureScale=0.400000,DrawPivot=DP_MiddleLeft,OffsetX=130,OffsetY=36,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    StormTimerIcon=(WidgetTexture=Texture'BattleRoyaleTex.Storm.stormicon',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=32,Y2=32),TextureScale=0.550000,OffsetX=10,OffsetY=9,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    StormTimerBackground=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=168,Y1=211,X2=334,Y2=255),TextureScale=0.400000,OffsetX=60,OffsetY=14,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    StormTimerBackgroundDisc=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=119,Y1=258,X2=173,Y2=313),TextureScale=0.530000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
}