class BattleBus extends Actor;

#EXEC AUDIO IMPORT FILE="Sounds\BusHorn.wav" NAME="BusHorn"
#EXEC AUDIO IMPORT FILE="Sounds\didntdie.wav" NAME="didntdie"
#EXEC AUDIO IMPORT FILE="Sounds\die4.wav" NAME="die4"
#EXEC AUDIO IMPORT FILE="Sounds\goodbye.wav" NAME="goodbye"
#EXEC AUDIO IMPORT FILE="Sounds\notsofast.wav" NAME="notsofast"
#EXEC AUDIO IMPORT FILE="Sounds\simpledie.wav" NAME="simpledie"
#EXEC AUDIO IMPORT FILE="Sounds\playshit.wav" NAME="playshit"

var array<name> Seats;
var array<BattleBusPassenger> Passengers;
var float spawntime;
var int BusLaunchSound;
var array<Sound> BusLaunchSounds;

replication
{
    reliable if ( Role == ROLE_Authority )
        BusLaunchSound;
}

function PostBeginPlay()
{
    super.PostBeginPlay();

    spawntime = level.timeseconds;
    BusLaunchSound = rand(BusLaunchSounds.Length);

    // create pawns
    InitPassengers();

    // collision must be on for attach (above) to work? we want it off
    SetCollision(false,false);
}

simulated function PostNetBeginPlay()
{
    local PlayerController PC;

    super.PostNetBeginPlay();

    if(Level.NetMode != NM_DedicatedServer)
    {
        PC = Level.GetLocalPlayerController();
        if(PC != None && PC.Pawn != None)
        {
            PC.Pawn.PlayOwnedSound(BusLaunchSounds[BusLaunchSound], SLOT_None,2.0);
        }
    }

    SetTimer(2.5,false);
}

simulated function Timer()
{
    PlayAnim('DoorOpen');
}

function InitPassengers()
{
    local BattleBusPassenger P;
    local int i;

    Passengers.Length = Seats.Length;
    for(i = 0;i<Passengers.Length;i++)
    {
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

        AttachToBone(P, P.Seat);
        Passengers[i] = P;
    }
}

function AddPassenger(PlayerController PC)
{
    local BattleBusPassenger P;

    //P = Passengers[Rand(Passengers.Length)];
    // humans sit up front so they can see
    //P = Passengers[Rand(1)];
    P = Passengers[0];
    PC.Pawn = P;

    PC.SetViewTarget(P);
    PC.ClientSetViewTarget(P);
    PC.bBehindView = false;
    PC.ClientSetBehindView(false);

    PC.ClientMessage(PC.OwnCamera, 'Event');
    PC.GotoState('PlayerWaiting');
}

function Actor FindStartSpot(Controller C)
{
    local int i;

    if(C == None)
        return Passengers[Rand(Passengers.Length)];

    for(i = 0;i<Passengers.Length;i++)
    {
        if(C.Pawn == Passengers[i])
            return Passengers[i];
    }

    return Passengers[Rand(Passengers.Length)];
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
    for(i=0;i<Passengers.Length;i++)
    {
        Passengers[i].Velocity = velocity;
    }

    //log("Bus: launched from: "$start$" towards"$dir);
}

defaultproperties
{
    DrawType=DT_Mesh
    bUseDynamicLights=True

    bAlwaysRelevant=true
    bStasis=False
    bUpdateSimulatedPosition=True
    bForceSkelUpdate=True
    bReplicateMovement=true
    bNetInitialRotation=true
    bNetTemporary=False
    RemoteRole=ROLE_SimulatedProxy
    NetPriority=3.000000

    bCanBeDamaged=False
    bShouldBaseAtStartup=False

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

    BusLaunchSounds(0)=Sound'BusHorn'
    BusLaunchSounds(1)=Sound'didntdie'
    BusLaunchSounds(2)=Sound'die4'
    BusLaunchSounds(3)=Sound'goodbye'
    BusLaunchSounds(4)=Sound'notsofast'
    BusLaunchSounds(5)=Sound'simpledie'
    BusLaunchSounds(6)=Sound'playshit'
}