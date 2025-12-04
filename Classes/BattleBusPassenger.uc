class BattleBusPassenger extends Pawn;

var BattleBus Bus;
var Name Seat;

function bool SpecialCalcView(out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local Coords C;

    ViewActor = self;
    C = Bus.GetBoneCoords(Seat);
    CameraLocation = C.Origin;    

    return true;
}

defaultproperties
{
    bHidden=false
    DrawType=DT_None
    Physics=PHYS_None
    bBlockActors=false
    bBlockPlayers=false
    bCollideWorld=false
    bCollideActors=false
    bIgnoreOutOfWorld=true
    bHardAttach=true
    bStasis=false
    bOnlyOwnerSee=false
    bOwnerNoSee=False
    bCanTeleport=True
    bUpdateSimulatedPosition=True
    RemoteRole=ROLE_SimulatedProxy
    NetPriority=2.000000
    bTravel=False

    Seat="PassA"
    bSpecialCalcView=true
}