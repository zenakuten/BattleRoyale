class BattleBus extends Actor;

var array<name> Seats;
var array<BattleBusPassenger> Passengers;
var float spawntime;

simulated function PostBeginPlay()
{
    spawntime = level.timeseconds;

    // create pawns
    InitPassengers();

    // collision must be on for attach (above) to work? we want it off
    SetCollision(false,false,false);
}

function InitPassengers()
{
    local BattleBusPassenger P;
    local int i;

    Passengers.Length = Seats.Length;
    for(i = 0;i<Passengers.Length;i++)
    {
        P = spawn(class'BattleBusPassenger',self,,vect(0,0,0));
        P.Bus = self;
        P.Seat = Seats[i];
        P.SetBase(self);
        P.SetLocation(Location);
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

    P = Passengers[Rand(Passengers.Length)];
    PC.Pawn = P;
    PC.bBehindView = true;
    PC.Pawn.SetBase(self);
    PC.SetViewTarget(P);
    PC.ClientSetViewTarget(P);
    PC.ClientMessage(PC.OwnCamera, 'Event');
    PC.GotoState('PlayerWaiting');
    /*
    PC.Pawn = Passenger;
    PC.bBehindView = true;
    PC.Pawn.SetBase(self);
    PC.SetViewTarget(Passenger);
    PC.ClientSetViewTarget(Passenger);
    PC.ClientMessage(PC.OwnCamera, 'Event');
    PC.GotoState('PlayerWaiting');
    */
}

function Actor FindStartSpot(Controller C)
{
    local int i;
    for(i = 0;i<Passengers.Length;i++)
    {
        if(C.Pawn == Passengers[i])
            return Passengers[i];
    }

    return Passengers[0];
}

function Launch(float RadarRange, float StallZ, float Speed)
{
    local float startx, starty, endx, endy;
    local vector start, end, dir;

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
}

simulated function Tick(float deltaTime)
{
    local BRGameReplicationInfo BRI;
    local int i;

    super.Tick(deltaTime);

    BRI = BRGameReplicationInfo(Level.GRI);

    if(BRI != None && Level.TimeSeconds > SpawnTime + 5.0)
    {
        //assumes center = 0,0
        if(abs(Location.X) > BRI.RadarRange * 0.90 || abs(Location.Y) > BRI.RadarRange * 0.90)
        {
            KillPassengers();
            for(i=0;i<Passengers.Length;i++)
            {
                Passengers[i].SetBase(None);
                Passengers[i].SetOwner(None);
                Passengers[i].Destroy();
            }
            Destroy();
        }
    }
}

simulated function KillPassengers()
{
    local Controller C;
    local PlayerController PC;
    local int i;

    for(C = Level.ControllerList;C!=None;C=C.NextController)
    {
        PC = PlayerController(C);
        if(PC != None)
        { 
            for(i=0;i<Passengers.Length;i++)
            {
                if(PC.Pawn == Passengers[i] && PC.IsInState('PlayerWaiting') && !PC.PlayerReplicationInfo.bOnlySpectator)
                {
                    PC.Suicide();
                    PC.SetViewTarget(PC);
                    PC.ClientSetViewTarget(PC);
                    PC.GotoState('Spectating');
                    PC.ReceiveLocalizedMessage(class'BREventMessage',0);
                }
            }
        }
    }
}

simulated function Destroyed()
{
    local int i;
    for(i=0;i<Passengers.Length;i++)
    {
        Passengers[i].SetBase(None);
        Passengers[i].SetOwner(None);
        Passengers[i].Destroy();
    }

    Passengers.Length = 0;
    super.Destroyed();
}

defaultproperties
{
    DrawType=DT_Mesh
    bUseDynamicLights=True
    bStasis=False
    bUpdateSimulatedPosition=True
    RemoteRole=ROLE_SimulatedProxy
    NetPriority=2.000000
    bTravel=False
    bCanBeDamaged=False
    bShouldBaseAtStartup=False
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
    bBlockActors=True
    bProjTarget=False
    bRotateToDesired=false
    bIgnoreOutOfWorld=true
    bNoRepMesh=True
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