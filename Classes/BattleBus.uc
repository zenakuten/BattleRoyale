//class BattleBus extends Actor;
class BattleBus extends Vehicle;

var array<name> Seats;
var array<BattleBusPassenger> Passengers;
var float spawntime;

function PostBeginPlay()
{
    super.PostBeginPlay();
    log("battlebus:postbeginplay");

    spawntime = level.timeseconds;

    // create pawns
    InitPassengers();

    // collision must be on for attach (above) to work? we want it off
    SetCollision(false,false);
}

/*
simulated function PostNetBeginPlay()
{
    local BattleBusPassenger P;

    super.PostNetBeginPlay();

    foreach ChildActors(class'BattleBusPassenger', P)
    {
        P.bHardAttach=true;
        P.SetBase(self);
    }

}
*/

function InitPassengers()
{
    local BattleBusPassenger P;
    local Coords C;
    local int i;

    Passengers.Length = Seats.Length;
    for(i = 0;i<Passengers.Length;i++)
    {
        //P = spawn(class'BattleBusPassenger',self,,Location,rotator(vect(0,0,0)));
        P = spawn(class'BattleBusPassenger',self);
        P.Bus = self;
        P.Seat = Seats[i];
        P.bHardAttach=true;
        P.bCollideWorld=false;
        P.SetCollision(false,false,false);
        P.SetLocation(Location);
        P.SetPhysics(PHYS_None);
        P.SetBase(self);
        if(i % 2 == 0)
            P.SetRelativeRotation(rot(0,16384,0));
        else
            P.SetRelativeRotation(rot(0,-16384,0));

        //C = GetBoneCoords(P.Seat);
        //P.SetRelativeLocation(C.Origin);
        AttachToBone(P, P.Seat);
        Passengers[i] = P;
    }
}

function AddPassenger(PlayerController PC)
{
    local BattleBusPassenger P;

    /*
    P = spawn(class'BattleBusPassenger',self);
    P.Bus = self;
    P.Seat = Seats[0];
    P.bCollideWorld=false;
    P.RemoteRole=ROLE_SimulatedProxy;
    P.SetPhysics(PHYS_None);
    P.SetCollision(false,false);
    P.SetLocation(Location);
    P.bHardAttach=true;
    P.SetBase(self);
    P.SetRelativeRotation(rot(0,16384,0));
    AttachToBone(P, Seats[0]);


    //PC.Pawn = None;
    PC.Pawn = P;
    //PC.Possess(P);
    //PC.bBehindView = false;
    //PC.ClientSetBehindView(false);
    PC.SetViewTarget(P);
    PC.ClientSetViewTarget(P);
    PC.bBehindView = true;
    PC.ClientSetBehindView(true);
    PC.CameraDist=0.0;
    PC.GotoState('PlayerWaiting');
    */

    //P = Passengers[Rand(Passengers.Length)];
    // humans sit up front so they can see
    //P = Passengers[Rand(1)];
    P = Passengers[0];
    PC.Pawn = P;

    PC.SetViewTarget(P);
    PC.ClientSetViewTarget(P);
    PC.bBehindView = false;
    PC.ClientSetBehindView(false);

    /*
    //debug
    PC.SetViewTarget(self);
    PC.ClientSetViewTarget(self);
    PC.bBehindView = false;
    //PC.CameraDist=0.0;
    PC.ClientSetBehindView(false);
    */

    PC.ClientMessage(PC.OwnCamera, 'Event');
    PC.GotoState('PlayerWaiting');
}

function Actor FindStartSpot(Controller C)
{
    local int i;
    local Actor start;

    log("Bus:FindStartSpot C="$C$"Passengers = "$Passengers.Length);
    if(Passengers.Length > 0)
        log("Passengers[0] = "$Passengers[0]);

    if(C == None)
    {
        log("Bus: trying to find start for None controller l="$Passengers.Length);
        //return None;
        return Passengers[Rand(Passengers.Length)];
    }

    for(i = 0;i<Passengers.Length;i++)
    {
        if(C.Pawn == Passengers[i])
        {
            log("Bus:FindPlayerStart: returning start: "$Passengers[i]);
            return Passengers[i];
        }
    }

    start = Passengers[Rand(Passengers.Length)];
    log("Bus:FindPlayerStart: returning start: "$start);
    return start;
}

function Launch(float RadarRange, float StallZ, float Speed)
{
    local float startx, starty, endx, endy;
    local vector start, end, dir;
    local int i;

    if(frand() < 0.5)
    {
        startx = (RadarRange * 2) * frand() - RadarRange;
        starty = -radarrange;
        endx = (RadarRange * 2) * frand() - RadarRange;
        endy = radarrange;
    }
    else
    {
        starty = (RadarRange * 2) * frand() - RadarRange;
        startx = -radarrange;
        endy = (RadarRange * 2) * frand() - RadarRange;
        endx = radarrange;
    }

    start.x = startx;
    start.y = starty;
    start.z = stallz;
    end.x = endx;
    end.y = endy;
    end.z = stallz;

    dir = normal(end - start);
    SetLocation(start);
    SetRotation(rotator(dir));
    velocity = dir * Speed;
    /*
    for(i=0;i<Passengers.Length;i++)
    {
        Passengers[i].Velocity = velocity;
    }
    */
    //log("debug: set btearoff");
    //bTearOff=true;
    // this caused no plane to show, but still shaking

    log("Bus: launched from: "$start$" towards"$dir);
}

function Destroyed()
{
    log("BattleBus:destroyed");
    super.Destroyed();
}

defaultproperties
{
    DrawType=DT_Mesh
    bUseDynamicLights=True

    bAlwaysRelevant=true
    bStasis=False
    bUpdateSimulatedPosition=True
    //bUpdateSimulatedPosition=False
    bForceSkelUpdate=True
    bReplicateMovement=true
    bNetInitialRotation=true
    bNetTemporary=False
    RemoteRole=ROLE_SimulatedProxy
    NetPriority=3.000000

    bCanBeDamaged=False
    bShouldBaseAtStartup=False

    //bSpecialCalcView=true

    bTravel=False
    bOwnerNoSee=False
    bCanTeleport=True
    bDisturbFluidSurface=True
    SoundVolume=255
    SoundRadius=160.000000
    CollisionRadius=120.000000
    CollisionHeight=50.000000
    CullDistance=0.0

    bCollideActors=True
    bCollideWorld=False
    bBlockActors=False
    bProjTarget=False

    bRotateToDesired=false
    bIgnoreOutOfWorld=true
    bDirectional=True
    
    Mesh=SkeletalMesh'BattleRoyale_Anim.UTDropShip'

    Physics=PHYS_Flying
    Lifespan=180.0
    Seats(0)="PassA"
    Seats(1)="PassB"
    Seats(2)="PassC"
    Seats(3)="PassD"
    Seats(4)="PassE"
    Seats(5)="PassF"
    Seats(6)="PassG"
    Seats(7)="PassH"
}