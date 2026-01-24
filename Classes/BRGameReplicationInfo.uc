class BRGameReplicationInfo extends GameReplicationInfo;

var StormZone Storm;
var BattleBus Bus;
var float RadarRange;
var bool bWarmup;
var int WarmupTimer;
var int GameTimer;

replication
{
    reliable if(Role == ROLE_Authority)
        Storm, Bus, RadarRange, bWarmup, WarmupTimer, GameTimer;
}

defaultproperties
{
}