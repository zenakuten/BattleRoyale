class StormZone extends Actor;

#exec OBJ LOAD FILE=..\Textures\BattleRoyaleTex.utx
#exec OBJ LOAD FILE=..\StaticMeshes\BattleRoyaleSM.usx
#EXEC AUDIO IMPORT FILE="Sounds\StormSurge.wav" NAME="StormSurge"


var() float InitialScaleMultiplier;
var float ZoneRadius, TargetRadius;
var float RadarRange;
var vector MapCenter;
var FinalBlend ZoneTexture;
var TerrainInfo PrimaryTerrain;
var float StartTime, ShrinkStartTime;
var float ShrinkStep;
var float ZTop;
var bool bShrinking;
var vector TargetLocation;
var float MinimumRadius;
var float TargetExtent;
var Sound StormSurgeSound;
var bool bSoundedSurge;

var int StormNumber;

replication
{
    reliable if(Role == ROLE_Authority)
        ZoneRadius, TargetRadius, bShrinking, TargetLocation;
}

struct StormInfo
{
    var float StormDuration;
    var float ShrinkDuration;
    var float TargetRadiusScale;
    var int OutOfBoundsDPS;
};

var array<StormInfo> StormData;

simulated function PostBeginPlay()
{
    local TerrainInfo T;
    local vector startloc;

    super.PostBeginPlay();

    SetTimer(1.0, true);
    Skins[0] = ZoneTexture;

    foreach AllActors(class'TerrainInfo', T)
    {
        PrimaryTerrain = T;
        if (T.Tag == 'PrimaryTerrain')
            Break;
    }

    StormNumber=0;
    ZoneRadius = GetRadarRange() * InitialScaleMultiplier;
    TargetRadius = ZoneRadius * StormData[StormNumber].TargetRadiusScale;
    SetRadius(ZoneRadius);

    startloc = MapCenter;
    //startloc.Z = ZTop;
    if(PrimaryTerrain != None)
        startloc.Z = PrimaryTerrain.Location.Z;

    SetLocation(startloc);

//debug
    //TargetLocation.X = frand()*ZoneRadius - ZoneRadius*0.5;
    //TargetLocation.Y = frand()*ZoneRadius - ZoneRadius*0.5;

    //TargetLocation.Z = ZTop;
    TargetLocation.Z = startloc.Z;
    
    InformBots();
    StartTime = Level.TimeSeconds;
}

simulated event Touch(Actor other)
{
    //Level.GetLocalPlayerController().ClientMessage("Storm touched "$other);
}

simulated event UnTouch(Actor other)
{
    //Level.GetLocalPlayerController().ClientMessage("Storm un touched "$other);
}

simulated function BroadcastSurgeSound()
{
    local Controller C;
    if(Role == ROLE_Authority)
    {
        for(C=Level.ControllerList;C!=None;C=C.NextController)
        {
            if(C.Pawn != None && PlayerController(C) != None)
                C.Pawn.PlayOwnedSound(StormSurgeSound, SLOT_None,255.0);
        }
    }
}

simulated function Tick(float DeltaTime)
{
    local bool bWasShrinking;
    local vector newloc;
    local float StormLife;
    
    super.Tick(DeltaTime);
    
    StormLife = Level.TimeSeconds - StartTime;

    bWasShrinking = bShrinking;
    bShrinking = StormLife > StormData[StormNumber].StormDuration;

    if(StormLife + 3.8 > StormData[StormNumber].StormDuration && !bSoundedSurge && !bShrinking)
    {
        BroadcastSurgeSound();
        bSoundedSurge=true;
    }

    if(bShrinking)
    {
        if(!bWasShrinking)
        {
            // shrink started
            //Level.GetLocalPlayerController().ClientMessage("storm shrink started");
            ShrinkStartTime = Level.TimeSeconds;
            // set our velocity so we reach target when shrink finishes
            Velocity = Normal(TargetLocation - Location)*VSize(TargetLocation - Location)/StormData[StormNumber].ShrinkDuration;
            Velocity.Z = 0;
            // set our shrink rate to match duration
            ShrinkStep=(ZoneRadius - TargetRadius)/StormData[StormNumber].ShrinkDuration;
        }

        // if we are close enough, stop
        if(VSize(TargetLocation - Location) <= TargetExtent)
        {
            Velocity = vect(0,0,0);
        }

        //do shrink
        ZoneRadius-=ShrinkStep * DeltaTime;
        ZoneRadius=fmax(ZoneRadius, MinimumRadius);
        SetRadius(ZoneRadius);
        
        if(ZoneRadius<=TargetRadius)
        {
            // finished shrinking, stop shrinking and advance storm
            bSoundedSurge=false;
            StormNumber=min(StormNumber+1, StormData.Length-1);
            StartTime = Level.TimeSeconds;
            newloc = GetAverageLocation();
            TargetLocation.X = newloc.X;
            TargetLocation.Y = newloc.Y;
            //TargetLocation.Z = ZTop;
            TargetLocation.Z = Location.Z;
            TargetRadius=ZoneRadius * StormData[StormNumber].TargetRadiusScale;
            Velocity = vect(0,0,0);
            InformBots();
            //Level.GetLocalPlayerController().ClientMessage("Storm shrink stopped, new storm "$StormNumber);
        }        
    }
}

function Timer()
{
    HurtPlayers();
}

// zone damage 
function HurtPlayers()
{
    local Controller C;
    local Vector ploc, loc;
    local float dist;
    for(C=Level.ControllerList;C!=None;C=C.NextController)
    {
        if(C.Pawn != None)
        {
            loc.X = location.X;
            loc.Y = location.Y;
            loc.Z = 0;
            ploc.X = C.Pawn.Location.X;
            ploc.Y = C.Pawn.Location.Y;
            ploc.Z = 0;
            dist = VSize(ploc-loc);

            if(dist > ZoneRadius)
            {
                //if(C == Level.GetLocalPlayerController())
                //    Level.GetLocalPlayerController().ClientMessage("Taking zone damage");

                C.Pawn.TakeDamage(StormData[StormNumber].OutOfBoundsDPS, None, vect(0,0,0), vect(0,0,0), class'StormPain');
            }
        }
    }
}

// figure out the map size
function float GetRadarRange()
{
    if(RadarRange != 0.0)
        return RadarRange;
    
    if (Level.bUseTerrainForRadarRange && PrimaryTerrain != None)
        RadarRange = abs(PrimaryTerrain.TerrainScale.X * PrimaryTerrain.TerrainMap.USize) / 2.0;
    else if (Level.CustomRadarRange > 0)
        RadarRange = Level.CustomRadarRange;

    return RadarRange;
}

// set the radius of the storm
simulated function SetRadius(float radius)
{
    local float scale;
    local vector scale3d;

    if(radius < 0)
        return;

    ZoneRadius = radius;
    //scale = ZoneRadius / 105; // magic value found experimentally, depends on staticmesh etc
    scale = ZoneRadius / 1024; // magic value found experimentally, depends on staticmesh etc
    scale3d.X = scale;
    scale3D.Y = scale;
    //scale3D.Z = 500; // we really just want a cylinder, stretch out the mesh vertically beyond map size
    scale3D.Z = 10; // we really just want a cylinder, stretch out the mesh vertically beyond map size
    SetDrawScale3D(scale3d);
}

// find the average player location
function vector GetAverageLocation()
{
    local Controller C;
    local vector retval;
    local int count;
    for(C=Level.ControllerList;C!=None;C=C.NextController)
    {
        if(!C.IsInState('Dead') && C.Pawn != None)
        {
            retval += C.Pawn.Location;
            count++;
        }
    }    

    return retval/max(count,1);
}

// tell bots to follow storm
// TODO this will probably need a battle royale bot class :(
// bots follow team orders, enemies, game objectives, all based on path nodes, which are
// bstatic, bnodelete so our storm cannot be a gameobjective for bot to follow
// we tell bots to follow us here but they don't
function InformBots()
{
    local Controller C;
    for(C=Level.ControllerList;C!=None;C=C.NextController)
    {
        if(!C.IsInState('Dead') && !C.IsInState('GameEnded') && Bot(C) != None)
        {
            Bot(C).SetRouteToGoal(self);
        }
    }
}

function StormInfo GetInfo()
{
    return StormData[StormNumber];
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    ZoneRadius=8000.0
    MapCenter=vect(0.0,0.0,0.0)
    DrawType=DT_StaticMesh
    CullDistance=0.0
    StaticMesh=StaticMesh'BattleRoyaleSM.StormMesh'
    ZoneTexture=FinalBlend'BattleRoyaleTex.Storm.StormShader'
    StormSurgeSound=Sound'StormSurge'
    //ZoneTexture=FinalBlend'XEffectMat.Shock.ShockCoilFB'

    //StaticMesh=StaticMesh'BattleRoyaleMesh.ONS.EnergonShield'
    //StaticMesh=StaticMesh'VMStructures.CoreGroup.CoreDivided'
    //ZoneTexture=FinalBlend'SkaarjPackSkins.Skins.Skaarjw3'
    NetUpdateFrequency=10.000000    

    //ZTop=150000.0
    ZTop=0.0
    ShrinkStep=100.0
    TargetExtent=500.0
    MinimumRadius=500.0

    // needed to get touch event
    bBlockActors=True
    bBlockKarma=True
    bBlockZeroExtentTraces=false
    bBlockNonZeroExtentTraces=false
    bUseCollisionStaticMesh=true

    bStasis=false
    bAlwaysTick=true
    bAlwaysRelevant=true

    Physics=PHYS_Flying
    bIgnoreOutOfWorld=true

    InitialScaleMultiplier=1.1
    StormNumber=0
    StormData(0)=(StormDuration=200.0,ShrinkDuration=20.0,TargetRadiusScale=0.7,OutOfBoundsDPS=1)
    StormData(1)=(StormDuration=160.0,ShrinkDuration=20.0,TargetRadiusScale=0.7,OutOfBoundsDPS=1)
    StormData(2)=(StormDuration=120.0,ShrinkDuration=20.0,TargetRadiusScale=0.7,OutOfBoundsDPS=2)
    StormData(3)=(StormDuration=100.0,ShrinkDuration=15.0,TargetRadiusScale=0.7,OutOfBoundsDPS=3)
    StormData(4)=(StormDuration=90.0,ShrinkDuration=15.0,TargetRadiusScale=0.7,OutOfBoundsDPS=5)
    StormData(5)=(StormDuration=80.0,ShrinkDuration=15.0,TargetRadiusScale=0.7,OutOfBoundsDPS=8)
    StormData(6)=(StormDuration=70.0,ShrinkDuration=10.0,TargetRadiusScale=0.7,OutOfBoundsDPS=13)
    StormData(7)=(StormDuration=60.0,ShrinkDuration=10.0,TargetRadiusScale=0.7,OutOfBoundsDPS=21)
    StormData(8)=(StormDuration=30.0,ShrinkDuration=10.0,TargetRadiusScale=0.7,OutOfBoundsDPS=34)
    StormData(9)=(StormDuration=15.0,ShrinkDuration=5.0,TargetRadiusScale=0.7,OutOfBoundsDPS=55)
    StormData(10)=(StormDuration=15.0,ShrinkDuration=5.0,TargetRadiusScale=0.7,OutOfBoundsDPS=55)
    StormData(11)=(StormDuration=15.0,ShrinkDuration=5.0,TargetRadiusScale=0.7,OutOfBoundsDPS=55)
    StormData(12)=(StormDuration=15.0,ShrinkDuration=5.0,TargetRadiusScale=0.7,OutOfBoundsDPS=55)

    /*
    StormData(0)=(StormDuration=10.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(1)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(2)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(3)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(4)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(5)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(6)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(7)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(8)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(9)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(10)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(11)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(12)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(13)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(14)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(15)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(16)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(17)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    StormData(18)=(StormDuration=5.0,ShrinkDuration=5.0,TargetRadiusScale=0.8,OutOfBoundsDPS=0)
    */
}
