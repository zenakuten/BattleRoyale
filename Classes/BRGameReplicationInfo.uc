class BRGameReplicationInfo extends GameReplicationInfo;

var StormZone Storm;
var BattleBus Bus;
var float RadarRange;
var bool bWarmup;

replication
{
    reliable if(Role == ROLE_Authority)
        Storm, Bus, RadarRange, bWarmup;
}

defaultproperties
{
}