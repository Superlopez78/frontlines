#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "swarm", 30, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "swarm", 300, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "swarm", 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "swarm", 0, 0, 10 );

	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onRoundSwitch = ::onRoundSwitch;	
	
	// dobro tempo de espera pra quem tá na defesa
	level.onRespawnDelay = ::getRespawnDelay;

	game["dialog"]["gametype"] = "capturehold";
	game["dialog"]["offense_obj"] = "captureflag";
	game["dialog"]["defense_obj"] = "captureflag";
	
	// the enemy has our flag
	game["dialog"]["ourflag"] = "ourflag";
	
	// the enemy capture our flag
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	
	// our flag has been dropped
	game["dialog"]["ourflag_drop"] = "ourflag_drop";

	// out flag has been returned	
	game["dialog"]["ourflag_return"] = "ourflag_return";
	
	// we have the enemy flag
	game["dialog"]["enemyflag"] = "enemyflag";
	
	// we captured the enemy flag
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";
	
	// enemy flag dropped
	game["dialog"]["enemyflag_drop"] = "enemyflag_drop";
	
	// enemy flag returned
	game["dialog"]["enemyflag_return"] = "enemyflag_return";
}

defineIcons()
{
	// define models pras flags
	if( game["allies"] == "marines" )
	{
		game["prop_flag_carry_allies"] = "prop_flag_american_carry";
	}
	else
	{
		game["prop_flag_carry_allies"] = "prop_flag_brit_carry";
	}
	
	if( game["axis"] == "russian" )
	{ 
		game["prop_flag_carry_axis"] = "prop_flag_russian_carry";
	}
	else
	{
		game["prop_flag_carry_axis"] = "prop_flag_opfor_carry";
	}

	// define icons das flags
	if( game["allies"] == "marines" )
	{
		level.icon_flag_allies = "compass_flag_american";
	}
	else
	{
		level.icon_flag_allies = "compass_flag_british";
	}
	
	if( game["axis"] == "russian" )
	{
		level.icon_flag_axis = "compass_flag_russian";
	}
	else
	{
		level.icon_flag_axis = "compass_flag_opfor";
	}
}

onPrecacheGameType()
{
	defineIcons();
   
    // pega no meio
	precacheString(&"MP_FRIENDLY_FLAG_CAPTURED_BY");
	precacheString(&"MP_ENEMY_FLAG_CAPTURED_BY");
    
	// flag retornada automaticamente
	precacheString(&"MP_FLAG_RETURNED");

	precacheModel( game["prop_flag_carry_allies"] );
	precacheModel( game["prop_flag_carry_axis"] );
	
	precacheModel( "prop_flag_neutral_carry" );
	
	precacheShader( level.icon_flag_allies );
	precacheShader( level.icon_flag_axis );
	
	precacheStatusicon( level.icon_flag_allies );
	precacheStatusicon( level.icon_flag_axis );
	
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_escort" );	
}

onStartGameType()
{	
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_SWARM_MAIN" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_SWARM_MAIN" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_SWARM_MAIN" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_SWARM_MAIN" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_SWARM_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_SWARM_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_SWARM_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_SWARM_HINT" );

	setClientNameMode("auto_change");

	allowed[0] = "sab";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	// testa se tem sab
	level.sab_ok = true;
	testa_sab = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( testa_sab ) ) 
	{
		level.sab_ok = false;
		thread DeletaSab();
	}
	
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	if ( level.sab_ok == true )
	{
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_allies_start" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_axis_start" );
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_sab_spawn_allies" );
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_sab_spawn_axis" );
		level.spawn_axis = getentarray("mp_sab_spawn_axis", "classname");
		level.spawn_allies = getentarray("mp_sab_spawn_allies", "classname");
		level.spawn_axis_start = getentarray("mp_sab_spawn_axis_start", "classname");
		level.spawn_allies_start = getentarray("mp_sab_spawn_allies_start", "classname");
	}
	else
	{
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
		level.spawn_axis = getentarray("mp_tdm_spawn", "classname");
		level.spawn_allies = getentarray("mp_tdm_spawn", "classname");
		level.spawn_axis_start = getentarray("mp_tdm_spawn_axis_start", "classname");
		level.spawn_allies_start = getentarray("mp_tdm_spawn_allies_start", "classname");
	}
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	

	// pro sound funcionar
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;

	if ( level.sab_ok == true )		
	{
		thread SuitcaseFlag();
		maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sab" );
	}
	else
	{
		thread SpawnPointFlag();
		maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );
	}
	thread SpawnFlag();
}

// ========================================================================
//		Flag
// ========================================================================

SpawnPointFlag()
{
	team = "axis";
	ale = RandomInt(2);
	if ( ale == 1 )
		team = "allies";
		
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( team );
	spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	level.FlagPosInicial = spawnPoint.origin;
}

SuitcaseFlag()
{
	trigger = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) ) 
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		error( "No sab_bomb_pickup_trig trigger found in map." );
		return;
	}
	level.FlagPosInicial = trigger.origin;
	thread DeletaSab();
}

DeletaSab()
{
	allowed = [];
	maps\mp\gametypes\_gameobjects::main(allowed);
}

SpawnFlag()
{
	onPrecacheGameType();

	local = level.FlagPosInicial;
	flagModel = "prop_flag_neutral_carry";
	level.FlagStatus = "home";

	flag_caida = [];
	flag_caida["flag_trigger"] = spawn( "trigger_radius", local + (0,0,8), 0, 20, 100 );
	flag_caida["flag"][0] = spawn( "script_model", local + (0,0,8));
	flag_caida["zone_trigger"] = spawn( "trigger_radius", local + (0,0,8), 0, 50, 100 );
	
	flag_caida["flag"][0] setModel( flagModel );
	level.flagCarry = criaFlagCarregavel( "neutral", flag_caida["flag_trigger"], flag_caida["flag"] );
}

criaFlagCarregavel( team, trigger, visuals )
{
	//logPrint("criaFlagCaida - time = " + team + "\n");

	flagObject = maps\mp\gametypes\_gameobjects::createCarryObject( team, trigger, visuals, (0,0,100) );

	flagObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" );
	flagObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" );
	flagObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	flagObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
	flagObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
	flagObject maps\mp\gametypes\_gameobjects::allowCarry( "any" );
   
	flagObject.onPickup = ::onPickupFlag;
	flagObject.onDrop = ::onDropFlag;
	flagObject.allowWeapons = true;
	
	// inicia lado da bandeira!
	level.FlagTeam = "neutral";
   
	return flagObject;
}

onPickupFlag( player )
{
	level.FlagStatus = "hand";

	level.FlagTeam = player.pers["team"];
	
	if ( self.ownerTeam != level.FlagTeam ) // capture!
	{
		//thread printAndSoundOnEveryone( level.FlagTeam, getOtherTeam( level.FlagTeam ), &"MP_ENEMY_FLAG_CAPTURED_BY", &"MP_FRIENDLY_FLAG_CAPTURED_BY", "", "", player );
			
		statusDialog( "enemyflag_capt", level.FlagTeam );
		statusDialog( "ourflag_capt", getOtherTeam( level.FlagTeam ) );	
	}
	else
	{
		//thread printAndSoundOnEveryone( self.ownerTeam, getOtherTeam( self.ownerTeam ), &"MP_ENEMY_FLAG_CAPTURED_BY", &"MP_FRIENDLY_FLAG_CAPTURED_BY", "", "", player );
		statusDialog( "enemyflag", self.ownerTeam );
		statusDialog( "ourflag", getOtherTeam( self.ownerTeam ) );	
	}
	
	player.flagger = true;
	player.mostraflag = false;
	player thread PegaCamper( self );

	self maps\mp\gametypes\_gameobjects::setModelVisibility( false );
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( level.FlagTeam );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_escort" );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
	
	player thread CriaIconFlag( level.FlagTeam );

	if(isdefined(player.flagAttached))
		return;

	if(player.pers["team"] == "axis")
	{
		flagModel = game["prop_flag_carry_axis"];
		player.statusicon = level.icon_flag_axis;
	}
	else
	{
		flagModel = game["prop_flag_carry_allies"];
		player.statusicon = level.icon_flag_allies;
	}	
	
	player attach(flagModel, "J_Spine4", true);
	player.flagAttached = true;
	
	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}	
}

CriaIconFlag( FlagTeam )
{
	if( FlagTeam == "allies" )
	{
		self.carryIcon = createIcon( level.icon_flag_allies, 35, 35 );
	}
	else
	{
		self.carryIcon = createIcon( level.icon_flag_axis, 35, 35 );
	}		
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;	
}

onResetFlag( team )
{
	x=0;
	
	while ( x != 60 )
	{
		// se flag já tem dono, aborta!
		if ( level.FlagStatus != "away" )
			return;

		wait 1;
		x++;
	}
	
	thread printAndSoundOnEveryone( team, getOtherTeam( team ), &"MP_FLAG_RETURNED", &"MP_FLAG_RETURNED", "", "", "" );
	
	statusDialog( "ourflag_return", team );
	statusDialog( "enemyflag_return", getOtherTeam( team ) );	
	
	self thread maps\mp\gametypes\_gameobjects::returnHome();
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
	self maps\mp\gametypes\_gameobjects::allowCarry( "any" );	
	self maps\mp\gametypes\_gameobjects::setModelVisibility( true );
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( "neutral" );
}

onDropFlag( player )
{
	level.FlagStatus = "away";
	level.FlagTeam = "neutral";
	
	thread onResetFlag( self.ownerTeam );
	
	statusDialog( "ourflag_drop", self.ownerTeam );
	statusDialog( "enemyflag_drop", getOtherTeam( self.ownerTeam ) );	
   
	if(isDefined(player))
		thread printOnTeamArg( &"MP_ENEMY_FLAG_DROPPED_BY", getOtherTeam( self.ownerTeam ), player );
	
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
	self maps\mp\gametypes\_gameobjects::setModelVisibility( true );	
	self maps\mp\gametypes\_gameobjects::allowCarry( "any" );
	//self maps\mp\gametypes\_gameobjects::setOwnerTeam( "neutral" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );	
	
	if(!isdefined(player))
		return;
		
	if(!isdefined(player.flagAttached))
		return;

	player detachFlag();
}

detachFlag()
{
	self.flagger = false;
	self.statusicon = "";

	// se cara desconecta, não dá mais erro
	if ( !isDefined( self ) )
	{
      if ( !isAlive( self ) )
			return;
	}
	
	if ( !isDefined( self ) )
		return;	
		
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();				
		
	if(!isdefined(self.flagAttached))
		return;	

	if( self.team == "axis")
	{
		flagModel = game["prop_flag_carry_axis"];
	}
	else if( self.team == "allies")
	{
		flagModel = game["prop_flag_carry_allies"];
	}
	else // sem time, não tira flag!
		return;
	
	self detach(flagModel, "J_Spine4");
	self.flagAttached = undefined;
}


// ========================================================================
//		Player
// ========================================================================

onSpawnPlayer()
{
	self.flagger = false;
	self.statusicon = "";

	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();

	spawnteam = self.pers["team"];
	if ( game["switchedsides"] )
		spawnteam = getOtherTeam( spawnteam );

	if ( level.useStartSpawns )
	{
		if (spawnteam == "axis")
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_axis_start);
		else
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_allies_start);
	}	
	else
	{
		if (spawnteam == "axis")
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(level.spawn_axis);
		else
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(level.spawn_allies);
	}

	assert( isDefined(spawnpoint) );
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( self.pers["team"] != level.FlagTeam && level.FlagTeam != "neutral" )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		}
		else
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn(spawnpoint.origin, spawnpoint.angles);
		}
	}
	else	
		self spawn( spawnpoint.origin, spawnpoint.angles );
}

// se flagger camperar muito, motra flag pra todos!
PegaCamper( flag )
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while( self.flagger == true )
	{
		wait 1;
		if ( self.mostraflag == true )
		{
			flag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
			return;
		}
	}
}

// ========================================================================
//		Sound
// ========================================================================

statusDialog( dialog, team )
{
	time = getTime();
	if ( getTime() < level.lastStatus[team] + 6000 )
		return;
		
	thread delayedLeaderDialog( dialog, team );
	level.lastStatus[team] = getTime();	
}

delayedLeaderDialog( sound, team )
{
	wait .1;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialog( sound, team );
}
delayedLeaderDialogBothTeams( sound1, team1, sound2, team2 )
{
	wait .1;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialogBothTeams( sound1, team1, sound2, team2 );
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	team = self.pers["team"];
	if ( team != level.FlagTeam && level.FlagTeam != "neutral" )
	{	
		if ( team == "axis" )
		{
			[[level._setTeamScore]]( "allies", [[level._getTeamScore]]( "allies" ) + 1 );
		}
		else if ( team == "allies" )
		{
			[[level._setTeamScore]]( "axis", [[level._getTeamScore]]( "axis" ) + 1 );
		}
	}
}

getRespawnDelay()
{
	if ( level.FlagTeam == self.pers["team"] )
	{
		timeremaining = 15;
	
		if( getDvarInt( "scr_swarm_waverespawndelay" ) > 0 )
		{
			timeRemaining = getDvarInt( "scr_swarm_waverespawndelay" ) * 2;
		}
		else if ( getDvarInt( "scr_swarm_playerrespawndelay" ) > 0 )
		{
			timeRemaining = getDvarInt( "scr_swarm_playerrespawndelay" ) * 2;
		}		
		return (int(timeRemaining));
	}
}

onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	level.halftimeType = "halftime";
	game["switchedsides"] = !game["switchedsides"];
}