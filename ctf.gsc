#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

registerRoundSwitchDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_roundswitch");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	
	level.roundswitchDvar = dvarString;
	level.roundswitchMin = minValue;
	level.roundswitchMax = maxValue;
	level.roundswitch = getDvarInt( level.roundswitchDvar );
}

registerRoundLimitDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_roundlimit");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	
	level.roundLimitDvar = dvarString;
	level.roundlimitMin = minValue;
	level.roundlimitMax = maxValue;
	level.roundLimit = getDvarInt( level.roundLimitDvar );
}

registerTimeLimitDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_timelimit");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarFloat( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarFloat( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	level.timeLimitDvar = dvarString;	
	level.timelimitMin = minValue;
	level.timelimitMax = maxValue;
	level.timelimit = getDvarFloat( level.timeLimitDvar );
	
	setDvar( "ui_timelimit", level.timelimit );		
}

registerNumLivesDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_numlives");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	level.numLivesDvar = dvarString;	
	level.numLivesMin = minValue;
	level.numLivesMax = maxValue;
	level.numLives = getDvarInt( level.numLivesDvar );
	level.numLivesOriginal = getDvarInt( level.numLivesDvar );
}

main()
{
	if ( getdvar("mapname") == "mp_background" )
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	level.teamBased = true;
	level.overrideTeamScore = true;

	registerRoundSwitchDvar( level.gameType, 1, 0, 9 );
	registerTimeLimitDvar( level.gameType, 10, 0, 1440 );
	registerRoundLimitDvar( level.gameType, 2, 0, 10 );
	registerNumLivesDvar( level.gameType, 0, 0, 0 );
	
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onRoundSwitch = ::onRoundSwitch;
			
	level.endGameOnScoreLimit = false;
		
	game["dialog"]["gametype"] = "captureflag";
	game["dialog"]["offense_obj"] = "boost";
	game["dialog"]["defense_obj"] = "boost";
	
	game["dialog"]["ourflag"] = "ourflag";
	game["dialog"]["ourflag_return"] = "ourflag_return";
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	game["dialog"]["ourflag_drop"] = "ourflag_drop";
	
	game["dialog"]["enemyflag"] = "enemyflag";
	game["dialog"]["enemyflag_return"] = "enemyflag_return";
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";
	game["dialog"]["enemyflag_drop"] = "enemyflag_drop";
}

defineIcons()
{
	// define models pras flags
	if( game["allies"] == "marines" )
	{
		game["prop_flag_allies"] = "prop_flag_american";
		game["prop_flag_carry_allies"] = "prop_flag_american_carry";
	}
	else
	{
		game["prop_flag_allies"] = "prop_flag_brit";
		game["prop_flag_carry_allies"] = "prop_flag_brit_carry";
	}
	
	if( game["axis"] == "russian" )
	{ 
		game["prop_flag_axis"] = "prop_flag_russian";
		game["prop_flag_carry_axis"] = "prop_flag_russian_carry";
	}
	else
	{
		game["prop_flag_axis"] = "prop_flag_opfor";
		game["prop_flag_carry_axis"] = "prop_flag_opfor_carry";
	}

	// define icons das flags
	if( game["allies"] == "marines" )
		level.icon_flag_allies = "compass_flag_american";
	else
		level.icon_flag_allies = "compass_flag_british";
	
	if( game["axis"] == "russian" )
		level.icon_flag_axis = "compass_flag_russian";
	else
		level.icon_flag_axis = "compass_flag_opfor";
}

onPrecacheGameType()
{
	defineIcons();

	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";

    // scored!
    precacheString(&"MP_TEAM_SCORED");    
    precacheString(&"MP_ENEMY_SCORED");
    
    // pega no meio
    precacheString(&"MP_FLAG_TAKEN_BY");    
    precacheString(&"MP_ENEMY_FLAG_TAKEN_BY");

	// pega na base    
	precacheString(&"MP_FRIENDLY_FLAG_CAPTURED_BY");
	precacheString(&"MP_ENEMY_FLAG_CAPTURED_BY");
	
	// flag retornada
	precacheString(&"MP_FLAG_RETURNED_BY");
	precacheString(&"MP_ENEMY_FLAG_RETURNED");
	// flag retornada automaticamente
	precacheString(&"MP_FLAG_RETURNED");
	
	// flag dropada!
	precacheString(&"MP_ENEMY_FLAG_DROPPED_BY");

	precacheModel( game["prop_flag_allies"] );
	precacheModel( game["prop_flag_axis"] );
	precacheModel( game["prop_flag_carry_allies"] );
	precacheModel( game["prop_flag_carry_axis"] );
	
	precacheShader( level.icon_flag_allies );
	precacheShader( level.icon_flag_axis );
	
	precacheStatusicon( level.icon_flag_allies );
	precacheStatusicon( level.icon_flag_axis );
	
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	precacheShader( "compass_waypoint_defend" );
}

onStartGameType()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	setClientNameMode("auto_change");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"OBJECTIVES_CTF" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"OBJECTIVES_CTF" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OBJECTIVES_CTF" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OBJECTIVES_CTF" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"OBJECTIVES_CTF_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"OBJECTIVES_CTF_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"OBJECTIVES_CTF_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"OBJECTIVES_CTF_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_sab_spawn_allies" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_sab_spawn_axis" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	level.spawn_axis = getentarray("mp_sab_spawn_axis", "classname");
	level.spawn_allies = getentarray("mp_sab_spawn_allies", "classname");
	level.spawn_axis_start = getentarray("mp_sab_spawn_axis_start", "classname");
	level.spawn_allies_start = getentarray("mp_sab_spawn_allies_start", "classname");
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	

	allowed[0] = "sab";
	allowed[1] = "dom";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	ctf();

	DeletaOutrosSpawns( "sab,tdm" );	
}

DeleteSabBombs()
{
	allowed = [];
	allowed[0] = "dom";
	maps\mp\gametypes\_gameobjects::main(allowed);
}

// ========================================================================
//		CTF
// ========================================================================

ctf()
{
	onPrecacheGameType();
	
	level.FlagTeams = [];

    level.flags = [];
    level.flagsCarry = [];
    level.FlagZones = [];
    level.FlagOrigin = [];
    
	novos_sab_init();
	if ( level.novos_objs )
		novos_sab();    
    
    // controle return de flag por um flagger
    level.FlagStatus["allies"] = "home";
    level.FlagStatus["axis"] = "home";
    
	// pega posição dos Targets do Sabotage!
	level.FlagZonesOriginal["allies"] = getEnt( "sab_bomb_allies", "targetname" );
	level.FlagZonesOriginal["axis"] = getEnt( "sab_bomb_axis", "targetname" );

	// define posições para bandeiras
	if ( game["switchedsides"] )
	{
		level.FlagZones["allies"] = level.FlagZonesOriginal["axis"].origin;
		level.FlagZones["axis"] = level.FlagZonesOriginal["allies"].origin;
	}
	else
	{
		level.FlagZones["allies"] = level.FlagZonesOriginal["allies"].origin;
		level.FlagZones["axis"] = level.FlagZonesOriginal["axis"].origin;
	}
	
	//logPrint("switchedsides = " + game["switchedsides"] + "\n");
	//logPrint("level.FlagZones[allies] = " + level.FlagZones["allies"] + "\n");
	//logPrint("level.FlagZones[axis] = " + level.FlagZones["axis"] + "\n");
	
	// inicia criação das bandeiras
	domFlags(); 
	
	// depois de pegar posição, deleta todos os objs do sab
	DeleteSabBombs(); 
}

// ========================================================================
//		Início Flag
// ========================================================================

domFlags()
{
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	game["flagmodels"] = [];
	game["flagmodels"]["neutral"] = "prop_flag_neutral";

	if ( game["allies"] == "marines" )
		game["flagmodels"]["allies"] = "prop_flag_american";
	else
		game["flagmodels"]["allies"] = "prop_flag_brit";
	
	if ( game["axis"] == "russian" ) 
		game["flagmodels"]["axis"] = "prop_flag_russian";
	else
		game["flagmodels"]["axis"] = "prop_flag_opfor";
	
	precacheModel( game["flagmodels"]["neutral"] );
	precacheModel( game["flagmodels"]["allies"] );
	precacheModel( game["flagmodels"]["axis"] );
	
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		printLn( "^1Not enough domination flags found in level!" );
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );
		return;
	}
	
	level.flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[level.flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[level.flags.size] = secondaryFlags[index];
	
	// inicialisa flags
	level.domFlags = [];
	
	for ( index = 0; index < 2; index++ ) // só pega as 2 primeiras flags
	{
		// seleciona de que time é a bandeira
		flag_team = "allies";
		if ( index == 1 )
			flag_team = "axis";	
		
		trigger = level.flags[index];
		
		// move trigger
		trigger.origin = level.FlagZones[flag_team] + (0,0,-10);
		
		if ( isDefined( trigger.target ) )
			visuals[0] = getEnt( trigger.target, "targetname" );
		else
		{
			visuals[0] = spawn( "script_model", trigger.origin );
			visuals[0].angles = trigger.angles;
		}

		visuals[0] setModel( game["flagmodels"]["neutral"] );
		
		//logPrint("flag_team = " + flag_team + "\n");

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( flag_team, trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::setOwnerTeam( flag_team );
		domFlag.visuals[0] setModel( game["flagmodels"][flag_team] );		
		
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( 0.0 );
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
		
		if ( flag_team == "allies" )
		{
			domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_allies );
			domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_allies );
			domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_allies );
			domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_allies );
		}
		else if ( flag_team == "axis" )
		{
			domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_axis );
			domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_axis );
			domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_axis );
			domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_axis );
		}
		
		domFlag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		domFlag.onUse = ::onUse;
		domFlag.onBeginUse = ::onBeginUse;
		domFlag.onUseUpdate = ::onUseUpdate;
		domFlag.onEndUse = ::onEndUse;		
		
		// cria flag carregável!
		FlagCarregavel( flag_team, trigger.origin ); 
		
		traceStart = visuals[0].origin + (0,0,32);
		traceEnd = visuals[0].origin + (0,0,-32);
		trace = bulletTrace( traceStart, traceEnd, false, undefined );
	
		upangles = vectorToAngles( trace["normal"] );
		domFlag.baseeffectforward = anglesToForward( upangles );
		domFlag.baseeffectright = anglesToRight( upangles );
		
		domFlag.baseeffectpos = trace["position"];

		// legacy spawn code support
		level.flags[index].useObj = domFlag;
		level.flags[index].adjflags = [];
		level.flags[index].nearbyspawns = [];
		
		domFlag.levelFlag = level.flags[index];
		
		level.domFlags[level.domFlags.size] = domFlag;
		level.FlagTeams[flag_team] = domFlag;
	}
	flagSetup();
}

FlagCarregavel( team, local )
{
	//logPrint("FlagCaiu - time = " + team + "\n");
	
	if( team == "axis")
		flagModel = game["prop_flag_carry_axis"];
	else
		flagModel = game["prop_flag_carry_allies"];
	
	flag_caida = [];
	flag_caida[team]["flag_trigger"] = spawn( "trigger_radius", local + (0,0,8), 0, 20, 100 );
	flag_caida[team]["flag"][0] = spawn( "script_model", local + (0,0,8));
	flag_caida[team]["zone_trigger"] = spawn( "trigger_radius", local + (0,0,8), 0, 50, 100 );
	
	flag_caida[team]["flag"][0] setModel( flagModel );
	level.flagsCarry[team] = criaFlagCarregavel( team, flag_caida[team]["flag_trigger"], flag_caida[team]["flag"] );
}

criaFlagCarregavel( team, trigger, visuals )
{
	//logPrint("criaFlagCaida - time = " + team + "\n");

   flagObject = maps\mp\gametypes\_gameobjects::createCarryObject( team, trigger, visuals, (0,0,100) );

	if ( team == "allies" )
	{
		flagObject maps\mp\gametypes\_gameobjects::setCarryIcon( level.icon_flag_allies );
		flagObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_allies );
		flagObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_allies );
		flagObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_allies );
		flagObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_allies );
	}
	else if ( team == "axis" )
	{
		flagObject maps\mp\gametypes\_gameobjects::setCarryIcon( level.icon_flag_axis );
		flagObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_axis );
		flagObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_axis );
		flagObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_axis );
		flagObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_axis );
	}
	
	flagObject.LadoTime = team;

	// inicia sempre invisível...
	flagObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	flagObject maps\mp\gametypes\_gameobjects::setModelVisibility( false );
	
	// só inimigo pode pegar!
	flagObject maps\mp\gametypes\_gameobjects::allowCarry( "enemy" );
   
	flagObject.onPickup = ::onPickupFlag;
	flagObject.onDrop = ::onDropFlag;
	flagObject.allowWeapons = true;
   
	return flagObject;
}

onPickupFlag( player )
{
	team = player.pers["team"];
	flagTeam = self.ownerTeam;
	
   // se player é do mesmo time da bandeira, retorna bandeira!
   if ( team == flagTeam )
   {
      self flagRetornada( player );
      return;
   }	

	player.flagger = true;
	player.mostraflag = false;
	
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" ); 
	self maps\mp\gametypes\_gameobjects::setModelVisibility( false );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );
	
	// flag caída no chão
	if ( level.FlagStatus[flagTeam] == "away" )
	{
		statusDialog( "enemyflag", getOtherTeam( flagTeam ) );
		statusDialog( "ourflag", flagTeam );
	
		lpselfnum = player getEntityNumber();
		lpGuid = player getGuid();
		logPrint("FT;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");
		
		thread printAndSoundOnEveryone( getOtherTeam( flagTeam ), flagTeam, &"MP_ENEMY_FLAG_TAKEN_BY", &"MP_FLAG_TAKEN_BY", "mp_war_objective_taken", "mp_war_objective_lost", player );		
	}	
	
	// flag na base
	if ( level.FlagStatus[flagTeam] == "home" )
	{
		level.FlagTeams[flagTeam] maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" );
		level.FlagTeams[flagTeam] maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );
		level.FlagTeams[flagTeam] maps\mp\gametypes\_gameobjects::setModelVisibility( false );

		level.FlagTeams[flagTeam].visuals[0] setModel( game["flagmodels"]["neutral"] );
		setDvar( "scr_obj" + level.FlagTeams[flagTeam] getLabel(), "neutral" );	
		
		level.useStartSpawns = false;
		
		assert( team != "neutral" );
		
		thread printAndSoundOnEveryone( team, flagTeam, &"MP_ENEMY_FLAG_CAPTURED_BY", &"MP_FRIENDLY_FLAG_CAPTURED_BY", "mp_war_objective_taken", "mp_war_objective_lost", player );
	
		statusDialog( "enemyflag_capt", team );
		statusDialog( "ourflag_capt", flagTeam );	
		
		lpselfnum = player getEntityNumber();
		lpGuid = player getGuid();
		logPrint("FC;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");			
	}
	
	level.FlagStatus[self.ownerTeam] = "hand";
	
	player thread flaggerSearch();
	player thread PegaCamper( self );

	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}
	
	if(!isdefined(player.flagAttached))
	{
		if(player.pers["team"] == "allies")
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
	}
}

// testa se flagger toca flag inimiga para retorná-la
flaggerSearch()
{
	level endon( "game_ended" );
	
	team = self.pers["team"];
	
	for(;;)
	{
		// se deixa de ser flagger sai!
		if ( !isDefined(self.flagger) || self.flagger == false )
			return;
			
		if ( !isAlive( self ) )
			return;
		
		if ( isDefined( level.FlagOrigin[team] ) )
		{
			// se player
			if ( distance(self.origin,level.FlagOrigin[team]) < 50 )
			{
				if ( level.FlagStatus[team] == "away" )
				{
					//iprintlnbold("retorna flag!!!");
					maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", self );
					self thread [[level.onXPEvent]]( "pickup" );
					
					// zera o local da flag pra não repetir
					level.FlagOrigin[team] = undefined;
					
					// retorna flag pra base!
					level.flagsCarry[team] flagRetornada( self );
				}
			}
		}
		wait 0.5;
	}
}

// se flagger camperar muito, motra flag pra todos!
PegaCamper( flag )
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	if(isdefined(self.bIsBot))	
		return;
	
	while( level.FlagStatus[flag.ownerTeam] == "hand" )
	{
		wait 1;
		if ( self.mostraflag == true )
		{
			flag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
			return;
		}
	}
}

flagRetornada( player )
{
	if ( player.pers["team"] == "allies" )
		thread ResetFlags( "allies" );
	else if ( player.pers["team"] == "axis" )
		thread ResetFlags( "axis" );

	statusDialog( "ourflag_return", player.pers["team"] );
	statusDialog( "enemyflag_return", getOtherTeam( player.pers["team"] ) );	
	
    lpselfnum = player getEntityNumber();
    lpGuid = player getGuid();
    logPrint("FR;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");		
    
    if(isDefined(player))
		thread printOnTeamArg( &"MP_FLAG_RETURNED_BY", self.ownerTeam , player );
    thread printOnTeamArg( &"MP_ENEMY_FLAG_RETURNED", getOtherTeam( self.ownerTeam ) , "" );
        
	maps\mp\gametypes\_globallogic::givePlayerScore( "capture", player );
	player thread [[level.onXPEvent]]( "capture" );	
	
	level.FlagStatus[self.ownerTeam] = "home";
	
	self thread maps\mp\gametypes\_gameobjects::returnHome();
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	self maps\mp\gametypes\_gameobjects::setModelVisibility( false );	
	self maps\mp\gametypes\_gameobjects::allowCarry( "enemy" );	
}

onResetFlag()
{
	x=0;
	
	while ( x != 60 )
	{
		// se flag já retornou, aborta!
		if ( level.FlagStatus[self.ownerTeam] != "away" )
			return;

		wait 1;
		x++;
	}
	
	ResetFlags( self.ownerTeam );
	
	level.FlagStatus[self.ownerTeam] = "home";
	
	thread printAndSoundOnEveryone( self.ownerTeam, getOtherTeam( self.ownerTeam ), &"MP_FLAG_RETURNED", &"MP_ENEMY_FLAG_RETURNED", "", "", "" );
	
	self thread maps\mp\gametypes\_gameobjects::returnHome();
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	self maps\mp\gametypes\_gameobjects::setModelVisibility( false );	
	self maps\mp\gametypes\_gameobjects::allowCarry( "enemy" );	
	
	statusDialog( "ourflag_return", self.ownerTeam );
	statusDialog( "enemyflag_return", getOtherTeam( self.ownerTeam ) );	
}

onDropFlag( player )
{
	if ( isDefined( player ) )
	{
		player.flagger = false;
		player.statusicon = "";
	}
	
	if ( isDefined(player) && isDefined( player.carryIcon ) )
		player.carryIcon destroyElem();	

	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
	self maps\mp\gametypes\_gameobjects::setModelVisibility( true );	
	self maps\mp\gametypes\_gameobjects::allowCarry( "any" );
	
	if ( self.ownerTeam == "allies" )
	{
		self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_allies );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_allies );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_allies );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_allies );
	}
	else if ( self.ownerTeam == "axis" )
	{
		self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_axis );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_axis );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_axis );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_axis );
	}	
	
	// flag no chão fora da base!
	level.FlagStatus[self.ownerTeam] = "away";
	level.FlagOrigin[self.ownerTeam] = self.trigger.origin;
   
   if(!isDefined(player))
   {
		statusDialog( "ourflag_drop", self.ownerTeam );
		statusDialog( "enemyflag_drop", getOtherTeam( self.ownerTeam ) );	
   }
   else if (isDefined(player) && !isAlive(player))
   {
		thread printOnTeamArg( &"MP_ENEMY_FLAG_DROPPED_BY", getOtherTeam( self.ownerTeam ), player );
		statusDialog( "ourflag_drop", self.ownerTeam );
		statusDialog( "enemyflag_drop", getOtherTeam( self.ownerTeam ) );	
   }
      
   thread onResetFlag();
	
	if(!isdefined(player))
		return;
		
	if(!isdefined(player.flagAttached))
		return;

	player detachFlag();
}

detachFlag()
{
	// se cara desconecta, não dá mais erro
	if ( !isDefined( self ) )
	{
      if ( !isAlive( self ) )
			return;
	}

	if ( !isDefined( self ) )
		return;
	
	if(!isdefined(self.flagAttached))
		return;	

	if( self.team == "allies")
	{
		flagModel = game["prop_flag_carry_axis"];
	}
	else if( self.team == "axis")
	{
		flagModel = game["prop_flag_carry_allies"];
	}
	else // sem time, não tira flag!
		return;	
	
	self detach(flagModel, "J_Spine4");
	self.flagAttached = undefined;
}

flagSetup()
{
	maperrors = [];
	descriptorsByLinkname = [];

	// (find each flag_descriptor object)
	descriptors = getentarray("flag_descriptor", "targetname");
	
	flags = level.flags;
	
	for (i = 0; i < level.domFlags.size; i++)
	{
		closestdist = undefined;
		closestdesc = undefined;
		for (j = 0; j < descriptors.size; j++)
		{
			dist = distance(flags[i].origin, descriptors[j].origin);
			if (!isdefined(closestdist) || dist < closestdist) {
				closestdist = dist;
				closestdesc = descriptors[j];
			}
		}
		
		flags[i].descriptor = closestdesc;
		closestdesc.flag = flags[i];
		descriptorsByLinkname[closestdesc.script_linkname] = closestdesc;
	}
	
	if (maperrors.size > 0)
	{
		logPrint("^1------------ Map Errors ------------" + "\n");
		for(i = 0; i < maperrors.size; i++)
			logPrint(maperrors[i] + "\n");
		logPrint("^1------------------------------------" + "\n");
		
		Rerror("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );
	
		return;
	}
}

onBeginUse( player )
{
	ownerTeam = self getOwnerTeam();
	setDvar( "scr_obj" + self getLabel() + "_flash", 1 );	
	self.didStatusNotify = false;

	if ( ownerTeam == "neutral" )
	{
		self.objPoints[player.pers["team"]] thread maps\mp\gametypes\_objpoints::startFlashing();
		return;
	}
		
	if ( ownerTeam == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::startFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::startFlashing();
}

onUseUpdate( team, progress, change )
{
	if ( progress > 0.05 && change && !self.didStatusNotify )
	{
		ownerTeam = self getOwnerTeam();
		self.didStatusNotify = true;
	}
}

onEndUse( team, player, success )
{
	setDvar( "scr_obj" + self getLabel() + "_flash", 0 );

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
}

onUse( player )
{
	team = player.pers["team"];
	flagTeam = self getOwnerTeam();
	label = self getLabel();	
	flag_icon_team = getDvar( "scr_obj" + self getLabel() );	
	
	if ( flagTeam == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";
	
	// se flag já foi pega
	if ( flag_icon_team == "neutral" )
	{
		// testa se ele é do time e é flagger (está retornando com bandeira inimiga!)
		if ( team == flagTeam && player.flagger == true )
		{
			// avisa que tem q recuperar primeiro bandeira dele, e aborta
			//player iPrintLnbold("Recupere sua bandeira primeiro");
			return;
		}
	}
	else if ( flag_icon_team != "neutral" ) // se bandeira no posto
	{
		if ( team == flagTeam && player.flagger == true )	
		{
			// flag dele, e está com a do inimigo
			// ponto pro time, reseta bandeiras!
			//player iPrintLnbold("Ponto!!!!");
			
			// remove flag do score
			player.statusicon = "";
			player.flagger = false;
			if ( isDefined( player.carryIcon ) )
				player.carryIcon destroyElem();		
			
			if ( team == "axis" )
			{
				[[level._setTeamScore]]( "axis", [[level._getTeamScore]]( "axis" ) + 1 );
				thread printAndSoundOnEveryone( "axis", "allies", &"MP_TEAM_SCORED", &"MP_ENEMY_SCORED", "plr_new_rank", "mp_obj_taken", "" );
			}
			else if ( team == "allies" )
			{
				[[level._setTeamScore]]( "allies", [[level._getTeamScore]]( "allies" ) + 1 );
				thread printAndSoundOnEveryone( "allies", "axis", &"MP_TEAM_SCORED", &"MP_ENEMY_SCORED", "plr_new_rank", "mp_obj_taken", "" );
			}
		
			maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
			player thread [[level.onXPEvent]]( "plant" );

			level.FlagStatus[otherTeam] = "home";
			player detachFlag();
			thread ResetFlags( otherTeam );
			level.flagsCarry[otherTeam] thread maps\mp\gametypes\_gameobjects::returnHome();
			level.flagsCarry[otherTeam] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
			level.flagsCarry[otherTeam] maps\mp\gametypes\_gameobjects::setModelVisibility( false );			
		}
	}
}

ResetFlags( team )
{
	if ( !isDefined(team) )
	{
		// reseta todas as flags
		for ( index = 0; index < level.domFlags.size; index++ )
		{
			flag_atual = level.domFlags[index];
			flagTeam = flag_atual getOwnerTeam();
			label = flag_atual getLabel();	
			flag_atual.visuals[0] setModel( game["flagmodels"][flagTeam] );
			setDvar( "scr_obj" + flag_atual getLabel(), flagTeam );	

			if ( flagTeam == "allies" )
			{
				flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_allies );
				flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_allies );
				flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_allies );
				flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_allies );
			}
			else if ( flagTeam == "axis" )
			{
				flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_axis );
				flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_axis );
				flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_axis );
				flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_axis );
			}	
			flag_atual maps\mp\gametypes\_gameobjects::setModelVisibility( true );
		}
	}
	else
	{
		// reseta apenas flag do time enviado
		for ( index = 0; index < level.domFlags.size; index++ )
		{
			flag_atual = level.domFlags[index];
			flagTeam = flag_atual getOwnerTeam();
			
			if ( flagTeam == team )
			{
				label = flag_atual getLabel();	
				flag_atual.visuals[0] setModel( game["flagmodels"][flagTeam] );
				setDvar( "scr_obj" + flag_atual getLabel(), flagTeam );	
				
				if ( flagTeam == "allies" )
				{
					flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_allies );
					flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_allies );
					flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_allies );
					flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_allies );
				}
				else if ( flagTeam == "axis" )
				{
					flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", level.icon_flag_axis );
					flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", level.icon_flag_axis );
					flag_atual maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", level.icon_flag_axis );
					flag_atual maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", level.icon_flag_axis );
				}
				flag_atual maps\mp\gametypes\_gameobjects::setModelVisibility( true );				
			}
		}
	}
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();
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

// ========================================================================
//		Fim Flag
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
		Ganhando = maps\mp\gametypes\_globallogic::getREALLYWinningTeam();
		if ( self.pers["team"] == Ganhando )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );		
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		}
		else
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn( spawnPoint.origin, spawnPoint.angles );
		}
	}
	else
		self spawn( spawnpoint.origin, spawnpoint.angles );
}

onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	level.halftimeType = "halftime";
	game["switchedsides"] = !game["switchedsides"];
}

// ============ RANDOM =======================
	
novos_sab_init()
{
	level.novos_objs = true;
	temp = GetDvar ( "xsab_" + 0 );
	if ( temp == "" )
	{
		level.novos_objs = false;	
		return;
	}

	xsab(); // cria listas com pos

	if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
	{
		id_a = RandomInt(level.xsab_a.size);
		while ( ObjValido(level.xsab_a[id_a]) == false )
		{
			id_a = RandomInt(level.xsab_a.size);
			logprint( "======================== Não Válido A!!! " + "\n");
		}
		game["xsab_temp_A"] = level.xsab_a[id_a];	
		
		id_b = RandomInt(level.xsab_b.size);
		while ( ObjValido(level.xsab_b[id_b]) == false )
		{
			id_b = RandomInt(level.xsab_b.size);
			logprint( "======================== Não Válido B!!! " + "\n");
		}
		game["xsab_temp_B"] = level.xsab_b[id_b];
	}
	else
	{
		game["xsab_temp_A"] = level.xsab_a[RandomInt(level.xsab_a.size)];
		game["xsab_temp_B"] = level.xsab_b[RandomInt(level.xsab_b.size)];
	}
}

novos_sab()
{
	exesab( game["xsab_temp_A"], 1 );
	exesab( game["xsab_temp_B"], 0 );
}	

xsab()
{
	level.xsab_a = [];
	level.xsab_b = [];
	
	sab_bomb_al = getEnt( "sab_bomb_allies", "targetname" );
	sab_bomb_ax = getEnt( "sab_bomb_axis", "targetname" );
	
	level.xsab_a[0] = sab_bomb_al.origin + (0, 0, 50); // axis
	level.xsab_b[0] = sab_bomb_ax.origin + (0, 0, 50);

	gerando = true;
	index = 0;

	while (gerando)
	{
		temp = GetDvar ( "xsab_" + index );
		if ( temp == "eof" )
			gerando = false;
		else
		{
			temp = strtok( temp, "," );
			pos = (int(temp[0]),int(temp[1]),int(temp[2]));
					
			if ( distance( pos, level.xsab_a[0]) < distance( pos, level.xsab_b[0]) )
				level.xsab_a[level.xsab_a.size] = pos;
			else
				level.xsab_b[level.xsab_b.size] = pos;
				
		}	
		index++;
	}
}

exesab( pos, bomb )
{
	angles = (0,0,0);
	
	destroyed_models = getentarray("exploder", "targetname");
	trig_plant_allies = getent("sab_bomb_allies", "targetname");
	trig_plant_axis = getent("sab_bomb_axis", "targetname");
	allies_destroyed_model = undefined;
	axis_destroyed_model = undefined;
	
	for( i=0 ; i<destroyed_models.size ; i++ )
	{
		if( isdefined( trig_plant_allies ) && isdefined( trig_plant_axis ) )
		{
			if( distance( destroyed_models[i].origin , trig_plant_allies.origin ) <= 100 )
				allies_destroyed_model = destroyed_models[i];
			
			if( distance( destroyed_models[i].origin , trig_plant_axis.origin ) <= 100 )
				axis_destroyed_model = destroyed_models[i];
		}
	}
	
	clips = getentarray( "script_brushmodel" , "classname" );
	allies_clip = undefined;
	axis_clip = undefined;
	
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{	
			if( clips[i].script_gameobjectname == "sab" )
			{
				if( distance( clips[i].origin , trig_plant_allies.origin ) <= 100 )
					allies_clip = clips[i];
				
				if( distance( clips[i].origin , trig_plant_axis.origin ) <= 100 )
					axis_clip = clips[i];
			}
		}
	}
	

	if( bomb == 1 )
	{
		obj_allies_origin = pos + (0, 0, -60);
		//obj_allies_angles = angles;
		
		trig_plant_allies.origin = obj_allies_origin;
		
		allies_destroyed_model.origin = obj_allies_origin;
		//allies_destroyed_model.angles = obj_allies_angles;
		
		allies_obj_entire = getent(trig_plant_allies.target , "targetname" );
		allies_obj_entire.origin = obj_allies_origin;
		//allies_obj_entire.angles = obj_allies_angles;
		
		allies_clip.origin = obj_allies_origin + (0, 0, 30);
		//allies_clip rotateto( obj_allies_angles, 0.1 );
	}
	else
	{
		obj_axis_origin = pos + (0, 0, -60);
		//obj_axis_angles = angles;
		
		trig_plant_axis.origin = obj_axis_origin;
		
		axis_destroyed_model.origin = obj_axis_origin;
		//axis_destroyed_model.angles = obj_axis_angles;
		
		axis_obj_entire = getent(trig_plant_axis.target , "targetname" );
		axis_obj_entire.origin = obj_axis_origin;
		//axis_obj_entire.angles = obj_axis_angles;
		
		axis_clip.origin = obj_axis_origin + (0, 0, 30);
		//axis_clip rotateto( obj_axis_angles, 0.1 );
	}
}

DeletaOutrosSpawns( spawnlist )
{
	// deleta todos os spawns do mapa que não são usados para diminuir ents no jogo, assim tentando evitar o G_Spawn error
	
	if ( level.WarFX == 1 )
		WarFXInit();
	
	spawns_ok = strtok( spawnlist, "," );
	
	deleta_dm = true;
	deleta_tdm = true;
	deleta_dom = true;	
	deleta_sab = true;
	deleta_sd = true;	
	
	// DM
	for ( s=0; s<spawns_ok.size; s++ )
	{
		if ( spawns_ok[s] == "dm" )
			deleta_dm = false;
	}
	if ( deleta_dm == true )
	{
		dm_spawn_points = getentarray( "mp_dm_spawn", "classname" );	
		for(k=0 ; k<dm_spawn_points.size ; k++)
			dm_spawn_points[k] delete();
	}
	
	// TDM (WAR)
	for ( s=0; s<spawns_ok.size; s++ )
	{
		if ( spawns_ok[s] == "tdm" )
			deleta_tdm = false;
	}
	if ( deleta_tdm == true )
	{
		tdm_spawn_points = getentarray( "mp_tdm_spawn_allies_start", "classname" );	
		for(k=0 ; k<tdm_spawn_points.size ; k++)
			tdm_spawn_points[k] delete();

		tdm_spawn_points = getentarray( "mp_tdm_spawn_axis_start", "classname" );	
		for(k=0 ; k<tdm_spawn_points.size ; k++)
			tdm_spawn_points[k] delete();

		tdm_spawn_points = getentarray( "mp_tdm_spawn", "classname" );	
		for(k=0 ; k<tdm_spawn_points.size ; k++)
			tdm_spawn_points[k] delete();
	}	
	
	// DOM
	for ( s=0; s<spawns_ok.size; s++ )
	{
		if ( spawns_ok[s] == "dom" )
			deleta_dom = false;
	}
	if ( deleta_dom == true )
	{
		dom_spawn_points = getentarray( "mp_dom_spawn_allies_start", "classname" );	
		for(k=0 ; k<dom_spawn_points.size ; k++)
			dom_spawn_points[k] delete();

		dom_spawn_points = getentarray( "mp_dom_spawn_axis_start", "classname" );	
		for(k=0 ; k<dom_spawn_points.size ; k++)
			dom_spawn_points[k] delete();

		dom_spawn_points = getentarray( "mp_dom_spawn", "classname" );	
		for(k=0 ; k<dom_spawn_points.size ; k++)
			dom_spawn_points[k] delete();
	}	

	// SAB
	for ( s=0; s<spawns_ok.size; s++ )
	{
		if ( spawns_ok[s] == "sab" )
			deleta_sab = false;
	}
	if ( deleta_sab == true )
	{
		sab_spawn_points = getentarray( "mp_sab_spawn_allies_start", "classname" );	
		for(k=0 ; k<sab_spawn_points.size ; k++)
			sab_spawn_points[k] delete();

		sab_spawn_points = getentarray( "mp_sab_spawn_axis_start", "classname" );	
		for(k=0 ; k<sab_spawn_points.size ; k++)
			sab_spawn_points[k] delete();

		sab_spawn_points = getentarray( "mp_sab_spawn_allies", "classname" );	
		for(k=0 ; k<sab_spawn_points.size ; k++)
			sab_spawn_points[k] delete();

		sab_spawn_points = getentarray( "mp_sab_spawn_axis", "classname" );	
		for(k=0 ; k<sab_spawn_points.size ; k++)
			sab_spawn_points[k] delete();
	}				
				
	// SD
	for ( s=0; s<spawns_ok.size; s++ )
	{
		if ( spawns_ok[s] == "sd" )
			deleta_sd = false;
	}
	if ( deleta_sd == true )
	{
		sd_spawn_points = getentarray( "mp_sd_spawn_attacker", "classname" );	
		for(k=0 ; k<sd_spawn_points.size ; k++)
			sd_spawn_points[k] delete();

		sd_spawn_points = getentarray( "mp_sd_spawn_defender", "classname" );	
		for(k=0 ; k<sd_spawn_points.size ; k++)
			sd_spawn_points[k] delete();
	}

	// KOTH = TDM
}

// ==================================================================================================================
//   Smoke FX
// ==================================================================================================================

WarFXInit()
{
	if ( maps\mp\gametypes\_globallogic::RevertGT( level.gametype ) == "evac" || maps\mp\gametypes\_globallogic::RevertGT( level.gametype ) == "surrender" ) 
		return;
	
	// posição spawns para marcar spawns da defesa/ataque!
	attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_allies_start" );
	defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_axis_start" );

	level.rot = randomfloat(360); // define angulos das fumaças!
	tamanho = distance( attack_spawn, defender_spawn );
	tamanho_spread = int(tamanho/6);
	if ( tamanho_spread < 1000 )
		tamanho_spread = 1000;
	NumSmokesIniciais = int(tamanho_spread/120);
	thread CriaSmoke(NumSmokesIniciais);
}

CriaSmoke( num )
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
	
	while(num > 0 )
	{
		thread seta_smoke( PosInicial() );
		num--;
	}
}

// de onde será o pulo
seta_smoke( origem )
{
	smoke = Gera_Smoke( origem );
	Smoking( smoke );		
}

Gera_Smoke( origem )
{
	smoke_spread = 2000;
	// calcula ponto central pra fazer vento inicial para tirar das bordas
	x = randomIntRange ( (smoke_spread * -1), smoke_spread );
	y = randomIntRange ( (smoke_spread * -1), smoke_spread );
	x_centro = int(origem[0] + x );
	y_centro = int(origem[1] + y );
	z_centro = origem[2];
	
	smoke_final = PlayerPhysicsTrace( (x_centro,y_centro,z_centro), (x_centro,y_centro,z_centro) + (0,0,-500) );
		
	return smoke_final;
}

Smoking( alvo )
{
	alvo = alvo + (0,0,-100);

	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(level.rot),sin(level.rot),0) );
	triggerFx( smoke );
}

PosInicial()
{
	lado =  randomInt(2);
	ladoteam = "axis";
	if ( lado == 1 ) ladoteam = "allies";

	ListaSpawns = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( ladoteam );
	assert( ListaSpawns.size );
	
	LocalSmoke = level.mapCenter;
	
	// se tem TDM spawn, pega random
	if (ListaSpawns.size > 0 )
	{
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( ListaSpawns );
		LocalSmoke = spawnPoint.origin;
	}
	
	return LocalSmoke;	
}

Rerror(msg)
{
	println("^c*ERROR* ", msg);
	wait .05;	// waitframe
/#
	if (getdvar("debug") != "1")
		assertmsg("This is a forced error - attach the log file");
#/
}

getLabel()
{
	label = self.trigger.script_label;
	if ( !isDefined( label ) )
	{
		label = "";
		return label;
	}
	
	if ( label[0] != "_" )
		return ("_" + label);
	
	return label;
}

getOwnerTeam()
{
	return self.ownerTeam;
}

ObjValido(pos)
{
    if(!isDefined(level.waypoints) || level.waypointCount == 0)
    {
		logprint( "======================== level.waypoints ZERADO! " + "\n");
        return -1;
    }

    if ( level.novos_objs == false )
		return true;
		
    nearestDistance = 200;
    for(i = 0; i < level.waypointCount; i++)
    {
        distance = Distance(pos, level.waypoints[i].origin);
    
        if(distance < nearestDistance)
			return true;
	}
	return false;
}