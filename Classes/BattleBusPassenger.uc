class BattleBusPassenger extends Pawn;

var BattleBus Bus;
var Name Seat;

replication
{
    unreliable if(ROLE == ROLE_Authority)
        Bus;
}

simulated function bool SpecialCalcView(out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local Coords C;

    ViewActor = self;
    C = Bus.GetBoneCoords(Seat);
    CameraLocation = C.Origin;

    return true;
}

simulated function vector CameraShake()
{
    return vect(0,0,0);
}

defaultproperties
{
    bHidden=false
    DrawType=DT_None
    Physics=PHYS_None
    bIgnoreOutOfWorld=true
    bStasis=false
    bOnlyOwnerSee=false
    bOwnerNoSee=False
    bCanTeleport=True
    bHardAttach=False
    bCollideActors=False
    bCollideWorld=False
    bBlockActors=False
    bReplicateMovement=True
    bUpdateSimulatedPosition=True
    bShouldBaseAtStartup=false
    RemoteRole=ROLE_SimulatedProxy
    NetPriority=3.000000
    Lifespan=0.0
    bRotateToDesired=True

    Seat="PassA"
    bSpecialCalcView=true
}