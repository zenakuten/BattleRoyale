class BattleRoyale extends xLastManStandingGame;

#EXEC AUDIO IMPORT FILE="Sounds\BusHorn.wav" NAME="BusHorn"
#EXEC AUDIO IMPORT FILE="Sounds\didntdie.wav" NAME="didntdie"
#EXEC AUDIO IMPORT FILE="Sounds\die4.wav" NAME="die4"
#EXEC AUDIO IMPORT FILE="Sounds\goodbye.wav" NAME="goodbye"
#EXEC AUDIO IMPORT FILE="Sounds\notsofast.wav" NAME="notsofast"
#EXEC AUDIO IMPORT FILE="Sounds\simpledie.wav" NAME="simpledie"
#EXEC AUDIO IMPORT FILE="Sounds\playshit.wav" NAME="playshit"

var StormZone Storm;
var config float StormDurationSeconds;
var config float StormShrinkLength;
var config float VehicleRoadRageScaling;
var config int WarmupPlayerStartTeamNum;
var BattleBus Bus;
var TerrainInfo PrimaryTerrain;
var int WarmupTimer;

var array<Sound> BusLaunchSounds;

/*
replication
{
    reliable if(Role == ROLE_Authority)
        Storm, Bus;
}
*/

function PostBeginPlay()
{
    local TerrainInfo T;

    super.PostBeginPlay();

    foreach AllActors(class'TerrainInfo', T)
    {
        PrimaryTerrain = T;
        if (T.Tag == 'PrimaryTerrain')
            Break;
    }    

    if (Level.bUseTerrainForRadarRange && PrimaryTerrain != None)
        BRGameReplicationInfo(GameReplicationInfo).RadarRange = abs(PrimaryTerrain.TerrainScale.X * PrimaryTerrain.TerrainMap.USize) / 2.0;
    else if (Level.CustomRadarRange > 0)
        BRGameReplicationInfo(GameReplicationInfo).RadarRange = Level.CustomRadarRange;
    else
        BRGameReplicationInfo(GameReplicationInfo).RadarRange = 10000.0;
}

event InitGame(string Options, out string Error)
{
    super.InitGame(Options, Error);
}

function StartMatch()
{
    if ( Level.NetMode == NM_Standalone )
        RemainingBots = InitialBots;
    else
        RemainingBots = 0;

    GotoState('Warmup');
}

auto State PendingMatch
{
	function RestartPlayer( Controller aPlayer )
	{
	}

    function bool AddBot(optional string botName)
    {
        return true;
    }

    function Timer()
    {
        log("pendingmatch:timer numplayers="$NumPlayers$" bWaitForNetPlayers="$bWaitForNetPlayers);

        Global.Timer();

        // start warmup if anybody joins
        if(NumPlayers > 0)
            StartMatch();
    }

    function beginstate()
    {
        log("pendingmatch:begin");
		bWaitingToStartMatch = true;
        StartupStage = 0;
        NetWait = Max(NetWait,10);
    }

Begin:
	if ( bQuickStart )
    {
        log("quick start");
		StartMatch();
    }
}

state MatchInProgress
{
    function Timer()
    {
        local Controller C;

        Global.Timer();

        if (RemainingBots > 0)
        {
            Level.GetLocalPlayerController().ClientMessage("RemainingBots = "$RemainingBots);
            for(C=Level.ControllerList;C!=None;C=C.NextController)
            {
                if(C.IsA('Bot') && C.Pawn == None)
                {
                    Level.GetLocalPlayerController().ClientMessage("Restart bot");
                    RestartPlayer(C);
                }
            }

            RemainingBots--;
        }

        if ( bOverTime )
			EndGame(None,"TimeLimit");
        else if ( TimeLimit > 0 )
        {
            GameReplicationInfo.bStopCountDown = false;
            RemainingTime--;
            GameReplicationInfo.RemainingTime = RemainingTime;
            if ( RemainingTime % 60 == 0 )
                GameReplicationInfo.RemainingMinute = RemainingTime;
            if ( RemainingTime <= 0 )
                EndGame(None,"TimeLimit");
        }
        else if ( (MaxLives > 0) && (NumPlayers + NumBots != 1) )
			CheckMaxLives(none);

        ElapsedTime++;
        GameReplicationInfo.ElapsedTime = ElapsedTime;
    }

    function endstate()
    {
        log("matchinprogress:endstate");
    }

    function beginstate()
    {
		local PlayerReplicationInfo PRI;
        local Controller C;

        log("matchinprogress:beginstate");
		foreach DynamicActors(class'PlayerReplicationInfo',PRI)
			PRI.StartTime = 0;

		ElapsedTime = 0;
		bWaitingToStartMatch = false;
        StartupStage = 5;
        PlayStartupMessage();
        StartupStage = 6;
        //RemainingBots = InitialBots;
        RemainingBots = 0;
        for(C=Level.ControllerList;C!=None;C=C.NextController)
        {
            if(C.IsA('Bot'))
                RemainingBots++;
        }
    }
}

function PlayStartupMessage()
{
    BroadcastLocalized(self, class'BRStartupMessage', StartupStage);
}

function BroadcastStatusAnnouncement(name announcement)
{
    local Controller C;
    for(C = Level.ControllerList;C!=None;C=C.NextController)
    {
        if(PlayerController(C) != None)
            PlayerController(C).PlayStatusAnnouncement(announcement, 1.0, true);
    }
}

state Warmup
{
    function Timer()
    {
        local Controller P;
        local bool bReady;
        local int PlayerCount, ReadyCount;

        WarmupTimer--;
        if ( NeedPlayers() && AddBot() && (RemainingBots > 0) )
        {
			RemainingBots--;
        }        

		// check if players are ready
        PlayerCount=0;
        ReadyCount=0;
        for (P=Level.ControllerList; P!=None; P=P.NextController )
        {
            if ( P.IsA('PlayerController') && (P.PlayerReplicationInfo != None) && P.bIsPlayer)
            {
                PlayerCount++;
                if(!P.PlayerReplicationInfo.bWaitingPlayer && P.PlayerReplicationInfo.bReadyToPlay)
                    ReadyCount++;
            }
        }
        log("warmup:timer p="$PlayerCount$" r="$ReadyCount);
        //bReady=PlayerCount != 0 && ReadyCount != 0 && PlayerCount >= MinPlayers && float(ReadyCount)/float(PlayerCount) > 0.51;
        bReady=PlayerCount != 0 && ReadyCount != 0 && float(ReadyCount)/float(PlayerCount) > 0.51;

        if ( bReady && WarmupTimer > 10)
        {
            WarmupTimer = 10;
        }

        if(WarmupTimer < 10)
            BroadcastLocalizedMessage(class'TimerMessage', WarmupTimer);
        else if(WarmupTimer % 3 == 0)
            BroadcastLocalizedMessage(class'BRStartupMessage', 0);

        if(WarmupTimer <= 0)
        {
            RemainingBots=0;
            GotoState('Dropping');
        }
    }

    function CheckScore(PlayerReplicationInfo Scorer)
    {
    }

    function ScoreKill(Controller Killer, Controller Killed)
    {
    }

    function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
    {
        return 0;
    }

    function EndState()
    {
        local Controller C, Next;
        local int i;

        BRGameReplicationInfo(Level.GRI).bWarmup=false;
        C = Level.ControllerList;
        while(C != None)
        {
            Next = C.NextController;
            if(C.Pawn != None && C.PlayerReplicationInfo != None && !C.PlayerReplicationinfo.bOnlySpectator)
            {
                C.Pawn.Died(None, class'Suicided', vect(0,0,0));
                C.PlayerReplicationInfo.Reset();
                C.PlayerReplicationInfo.NumLives = default.MaxLives;
            }

            C = Next;
        }

        i=0;
        for(C=level.controllerlist;c!=none;c=c.nextcontroller)
            i++;

        //we mess with these only to allow spec/join to work in warmup
        bWaitingToStartMatch=true;
        Level.GRI.bMatchHasBegun=false;
    }

    function BeginState()
    {
        local Controller C;
        BRGameReplicationInfo(Level.GRI).bWarmup=true;
        MaxLives=0;
        for(C=Level.ControllerList;C!=None;C=C.NextController)
        {
            if(C.PlayerReplicationInfo != None)
            { 
                if(!C.PlayerReplicationInfo.bOnlySpectator)
                    RestartPlayer(C);
                C.PlayerReplicationInfo.bReadyToPlay=false;
            }
        }

        WarmupTimer = 90;
        
        //we mess with these only to allow spec/join to work in warmup
        bWaitingToStartMatch=false;
        Level.GRI.bMatchHasBegun=true;

        SetTimer(1.0, true);
    }
}

// debug
exec function EndWarmup()
{
    WarmupTimer = 10;
}

state Dropping
{
    function CheckScore(PlayerReplicationInfo Scorer)
    {
    }

    function ScoreKill(Controller Killer, Controller Killed)
    {
    }

    function Timer()
    {
        //simpledie
        //KillBots(100);
    }

    function Tick(float dt)
    {
    }

    function bool CheckMaxLives(PlayerReplicationInfo Scorer)
    {
        return false;
    }

    function RestartPlayer( Controller aPlayer )
    {
    }

    function endstate()
    {
        log("dropping:endstate");
    }

    function beginstate()
    {
        local Controller C;

        log("dropping:beginstate");
        MaxLives=default.MaxLives;
        //RemainingBots=InitialBots;

        Storm = spawn(class'StormZone');
        BRGameReplicationInfo(GameReplicationInfo).Storm = Storm;

        Bus = spawn(class'BattleBus',self,,vect(0,0,8000));
        BRGameReplicationInfo(GameReplicationInfo).Bus = Bus;


        for(C=Level.ControllerList;C!=None;C=C.NextController)
        {
            if(PlayerController(C) != None)
            {
                Bus.AddPassenger(PlayerController(C));
                if(C.Pawn != None)
                    C.Pawn.PlayOwnedSound(BusLaunchSounds[rand(BusLaunchSounds.Length)], SLOT_Interact, 255.0);
            }
        }

        Bus.Launch(BRGameReplicationInfo(GameReplicationInfo).RadarRange * 0.5, Level.StallZ * 0.5, 1000.0);

        log("dropping:end beginstate");
    }

Begin:
    log("dropping:begin label");
    Sleep(3.5);
    //Sleep(2.5);
    //Bus.PlayAnim('DoorOpen');
    //Sleep(1.0);
    BroadcastStatusAnnouncement('three');
    Sleep(1.0);
    BroadcastStatusAnnouncement('two');
    Sleep(1.0);
    BroadcastStatusAnnouncement('one');
    Sleep(1.0);
    BroadcastStatusAnnouncement('Play');
    log("dropping:begin end label");
    GotoState('MatchInProgress');
}

function float RatePlayerStart(NavigationPoint N, byte Team, Controller Player)
{
    if(PlayerStart(N) != None && PlayerStart(N).TeamNumber == WarmupPlayerStartTeamNum)
        return 999999999;
    
    return super.RatePlayerStart(N, Team, Player);
}

function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string incomingName )
{
    local NavigationPoint N, BestStart;
    local Teleporter Tel;
    local float BestRating, NewRating;
    local byte Team;

    /*
    // always pick StartSpot at start of match
    if ( (Player != None) && (Player.StartSpot != None) && (Level.NetMode == NM_Standalone)
        && (bWaitingToStartMatch || ((Player.PlayerReplicationInfo != None) && Player.PlayerReplicationInfo.bWaitingPlayer))  )
    {
        return Player.StartSpot;
    }
    */

    if ( GameRulesModifiers != None )
    {
        N = GameRulesModifiers.FindPlayerStart(Player,InTeam,incomingName);
        if ( N != None )
            return N;
    }

    // if incoming start is specified, then just use it
    if( incomingName!="" )
        foreach AllActors( class 'Teleporter', Tel )
            if( string(Tel.Tag)~=incomingName )
                return Tel;

    // use InTeam if player doesn't have a team yet
    if ( (Player != None) && (Player.PlayerReplicationInfo != None) )
    {
        if ( Player.PlayerReplicationInfo.Team != None )
            Team = Player.PlayerReplicationInfo.Team.TeamIndex;
        else
            Team = InTeam;
    }
    else
        Team = InTeam;

    for ( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
    {
        NewRating = RatePlayerStart(N,Team,Player);
        if ( NewRating > BestRating )
        {
            BestRating = NewRating;
            BestStart = N;
        }
    }

    if ( (BestStart == None) || ((PlayerStart(BestStart) == None) && (Player != None) && Player.bIsPlayer) )
    {
        log("Warning - PATHS NOT DEFINED or NO PLAYERSTART with positive rating");
		BestRating = -100000000;
        ForEach AllActors( class 'NavigationPoint', N )
        {
            NewRating = RatePlayerStart(N,0,Player);
            if ( InventorySpot(N) != None )
				NewRating -= 50;
			NewRating += 20 * FRand();
            if ( NewRating > BestRating )
            {
                BestRating = NewRating;
                BestStart = N;
            }
        }
    }

    return BestStart;
}

function RestartPlayer( Controller aPlayer )
{
    local Actor startSpot;
    local int TeamNum;
    local class<Pawn> DefaultPlayerClass;
	local Vehicle V, Best;
	local vector ViewDir;
	local float BestDist, Dist;

    log("RestartPlayer:"$aPlayer);

    if( bRestartLevel && Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer )
        return;

    if(PlayerController(aPlayer) != None && aPlayer.PlayerReplicationInfo != None)
    {
        log("RestartPlayer:"$aPlayer$" spec="$aPlayer.PlayerReplicationInfo.bOnlySpectator);
        if(aPlayer.PlayerReplicationInfo.bOnlySpectator)
        {
            log("RestartPlayer: not restarting, viewing next player for spectator");
            PlayerController(aPlayer).ServerViewNextPlayer();
            return;
        }
    }

    if ( (aPlayer.PlayerReplicationInfo == None) || (aPlayer.PlayerReplicationInfo.Team == None) )
        TeamNum = 255;
    else
        TeamNum = aPlayer.PlayerReplicationInfo.Team.TeamIndex;

    //startSpot = FindPlayerStart(aPlayer, TeamNum);
    if(IsInState('Warmup'))
        startSpot = FindPlayerStart(aPlayer, TeamNum);
    else if(Bus != None)
    {
        startSpot = Bus.FindStartSpot(aPlayer);
        //debug!
        //startSpot = aPlayer.Pawn;
        log("bus returned (debug!) "$startSpot$ " state="$GetStateName());
    }
    else
        log("Bus is None");

    log("startSpot = "$startSpot$" wtf="$startSpot == None);
    if( startSpot == None )
    {
        log(" Player start not found!!! bus="$Bus$" State="$GetStateName());
        return;
    }
    else
    {
        log(" got start "$startSpot);
        
    }

    //debug 
    if(aPlayer.Pawn != None)
    {
        //aPlayer.Pawn.Destroy();
        aPlayer.Pawn=None;
    }

    if (aPlayer.PreviousPawnClass!=None && aPlayer.PawnClass != aPlayer.PreviousPawnClass)
        BaseMutator.PlayerChangedClass(aPlayer);

    if ( aPlayer.PawnClass != None )
        aPlayer.Pawn = Spawn(aPlayer.PawnClass,,,StartSpot.Location+vect(0,0,0),aPlayer.Rotation);


    if( aPlayer.Pawn==None )
    {
        DefaultPlayerClass = GetDefaultPlayerClass(aPlayer);
        aPlayer.Pawn = Spawn(DefaultPlayerClass,,,StartSpot.Location+vect(0,0,0),aPlayer.Rotation);
    }

    if ( aPlayer.Pawn == None )
    {
        log("Couldn't spawn player of type "$aPlayer.PawnClass$" at "$StartSpot$" loc="$StartSpot.Location);
        aPlayer.GotoState('Dead');
        if ( PlayerController(aPlayer) != None )
			PlayerController(aPlayer).ClientGotoState('Dead','Begin');
        return;
    }
    if ( PlayerController(aPlayer) != None )
		PlayerController(aPlayer).TimeMargin = -0.1;

    if( Bot(aPlayer) != None)
    {
        Bot(aPlayer).Pawn.Velocity = vect(440,440,0) * VRand();
    }

    //aPlayer.Pawn.Anchor = startSpot;
	//aPlayer.Pawn.LastStartSpot = PlayerStart(startSpot);
	aPlayer.Pawn.LastStartTime = Level.TimeSeconds;
    aPlayer.PreviousPawnClass = aPlayer.Pawn.Class;

    aPlayer.Possess(aPlayer.Pawn);
    aPlayer.PawnClass = aPlayer.Pawn.Class;

    aPlayer.Pawn.PlayTeleportEffect(true, true);
    aPlayer.ClientSetRotation(aPlayer.Pawn.Rotation);
    //AddDefaultInventory(aPlayer.Pawn);
    aPlayer.Pawn.CreateInventory("XWeapons.ShieldGun");
    aPlayer.Pawn.CreateInventory("BattleRoyale.ParachutePowerup");


    //TriggerEvent( StartSpot.Event, StartSpot, aPlayer.Pawn);

    if ( bAllowVehicles && (Level.NetMode == NM_Standalone) && (PlayerController(aPlayer) != None) )
    {
		// tell bots not to get into nearby vehicles for a little while
		BestDist = 2000;
		ViewDir = vector(aPlayer.Pawn.Rotation);
		for ( V=VehicleList; V!=None; V=V.NextVehicle )
			if ( V.bTeamLocked && (aPlayer.GetTeamNum() == V.Team) )
			{
				Dist = VSize(V.Location - aPlayer.Pawn.Location);
				if ( (ViewDir Dot (V.Location - aPlayer.Pawn.Location)) < 0 )
					Dist *= 2;
				if ( Dist < BestDist )
				{
					Best = V;
					BestDist = Dist;
				}
			}

		if ( Best != None )
			Best.PlayerStartTime = Level.TimeSeconds + 8;
	}  
}

// assign menu, force new joins to spec
event PostLogin( playercontroller NewPlayer )
{
    local class<Scoreboard> ScoreboardClass;

    if (UnrealPlayer(NewPlayer) != None)
    {
        LoginMenuClass="BattleRoyale.BattleRoyaleLoginMenu";
        UnrealPlayer(NewPlayer).ClientReceiveLoginMenu(LoginMenuClass, bAlwaysShowLoginMenu);
        UnrealPlayer(NewPlayer).PlayStartUpMessage(StartupStage);
    }

    // this needs tested
    if(IsInState('MatchInProgress'))
    {
        log("Forcing new player to spectator while match in progress");
        //todo this will probably just be hardcoded
        ScoreboardClass = class<Scoreboard>(DynamicLoadObject(ScoreBoardType, class'Class'));
        NewPlayer.ClientSetHUD(class'HUDBattleRoyale', ScoreboardClass);

        NewPlayer.PlayerReplicationInfo.NumLives=0;
        NewPlayer.PlayerReplicationInfo.bOnlySpectator=true;
        NewPlayer.ServerSpectate();
        return;
    }

	Super.PostLogin(NewPlayer);
}

function bool AllowBecomeActivePlayer(PlayerController P)
{
    if(IsInState('Warmup'))
        return true;

    return super.AllowBecomeActivePlayer(P);
}

// nerf road rage
function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    if(ClassIsChildOf(DamageType, class'DamTypeRoadKill'))
        return VehicleRoadRageScaling * Damage;

    return super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
}

// toss weapons on death
function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local array<Weapon> Inv;
	local Inventory tInv;
	local int i;
	local vector TossVel;

	if (Super.PreventDeath(Killed, Killer, DamageType, HitLocation)) 
        return True;

	for (tInv = Killed.Inventory; tInv != None; tInv = tInv.Inventory)
		if (tInv.IsA('Weapon')) 
            Inv[Inv.Length] = Weapon(tInv);

	for (i = 0; i < Inv.Length; i++)
	{
		Inv[i].HolderDied();
		if (Killed.Weapon == Inv[i])
		{
			TossVel = Vector(Killed.GetViewRotation());
			TossVel = TossVel * ((Killed.Velocity Dot TossVel) + 500) + Vect(0,0,200);
			Inv[i].Velocity = TossVel;
			Killed.Weapon = None;
			Killed.DeleteInventory(Inv[i]);
			Inv[i].DropFrom(Vector(Killed.GetViewRotation()) * Killed.CollisionRadius * 1.5);
		}
		else
		{
			TossVel = Normal(Killed.Velocity);
			TossVel = TossVel * ((Killed.Velocity Dot TossVel) + 500) + vect(0,0,200) + VRand() * 200;
			Inv[i].Velocity = TossVel;
			Killed.DeleteInventory(Inv[i]);
			Inv[i].DropFrom(Killed.Location + Normal(Killed.Velocity) * Killed.CollisionRadius * 1.5 + VRand() * 20.0);
		}
	}

	Inv.Length = 0;

	return False;
}

static function FillPlayInfo(PlayInfo PI)
{
	Super.FillPlayInfo(PI);

	PI.AddSetting(default.RulesGroup, "bAllowVehicles",      GetDisplayText("bAllowVehicles"),       40, 1, "Check",         ,,     ,True);
}

static function string GetDisplayText(string PropName)
{
	switch (PropName)
	{
		case "bAllowVehicles":				return "Allow vehicles";
	}

	return Super.GetDisplayText(PropName);
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bAllowVehicles":				return "Allow vehicles";
	}

	return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    GameName="Battle Royale"
    Description="Battle Royale"
    Acronym="BRY"

    //bDelayedStart=false
    //NetWait=0
    MaxLives=1
    TimeLimit=0
    bAllowPickups=true
    bAllowAdrenaline=true
    bAllowSuperweapons=true
    bAllowVehicles=true
    bLiberalVehiclePaths=true

    StormDurationSeconds=30.0
    StormShrinkLength=2000.0

    MutatorClass="BattleRoyale.MutBattleRoyale"
    HUDType="BattleRoyale.HUDBattleRoyale"
    GameReplicationInfoClass="BattleRoyale.BRGameReplicationInfo"

    MapListType="Onslaught.ONSMapListOnslaught"
    MapPrefix="ONS"
    // TODO
    BroadcastHandlerClass="BonusPack.LMSBroadcastHandler"
    ScreenShotName="UT2004Thumbnails.LMSShots"
    DecoTextName="BonusPack.LastManStandingGame"

    //LoginMenuClass="GUI2K4.UT2K4OnslaughtLoginMenu"
    //GameUMenuType="GUI2K4.UT2K4OnslaughtLoginMenu"
    LoginMenuClass="BattleRoyale.BattleRoyaleLoginMenu"
    GameUMenuType="BattleRoyale.BattleRoyaleLoginMenu"
    bAlwaysShowLoginMenu=True
    bQuickStart=false

    VehicleRoadRageScaling=0.0001
    WarmupPlayerStartTeamNum=3
    BusLaunchSounds(0)=Sound'BusHorn'
    BusLaunchSounds(1)=Sound'didntdie'
    BusLaunchSounds(2)=Sound'die4'
    BusLaunchSounds(3)=Sound'goodbye'
    BusLaunchSounds(4)=Sound'notsofast'
    BusLaunchSounds(5)=Sound'simpledie'
    BusLaunchSounds(6)=Sound'playshit'
}