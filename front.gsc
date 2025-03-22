#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerFrontExtDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.FrontExtDvar = dvarString;
	level.FrontExtMin = minValue;
	level.FrontExtMax = maxValue;
	level.FrontExt = getDvarInt( level.FrontExtDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerFrontExtDvar( "scr_front_ext", 0, 0, 1 );

	if ( level.FrontExt == 0 )
		init();
	else if ( level.FrontExt == 1 )
	{
		maps\mp\gametypes\exterminate::init();
		return;
	}
}

// funcao pra registrar scr_GAMETYPE_remember
registerRememberDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_remember");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	
	level.RememberDvar = dvarString;
	level.RememberMin = minValue;
	level.RememberMax = maxValue;
	level.Remember = getDvarInt( level.RememberDvar );
}

init()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "front", 3, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "front", 3, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "front", 6, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "front", 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "front", 1, 1, 50 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "front", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "front", 1, 0, 1 );
	registerRememberDvar( "front", 0, 0, 200 );
	
	// 1 = Flag
	maps\mp\gametypes\_globallogic::registerTypeDvar( "front", 1, 0, 1 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.onTimeLimit = ::onTimeLimit; 
	level.endGameOnScoreLimit = false;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["defense_obj"] = "security_complete";
	
	game["dialog"]["ourflag"] = "ourflag";
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	game["dialog"]["enemyflag"] = "enemyflag";
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";	
}

onPrecacheGameType()
{
	game["us_attack"] = "US_1mc_attack";
	game["uk_attack"] = "UK_1mc_attack";
	game["ru_attack"] = "RU_1mc_attack";
	game["ab_attack"] = "AB_1mc_attack";
		
	game["us_defend"] = "US_1mc_defend";
	game["uk_defend"] = "UK_1mc_defend";
	game["ru_defend"] = "RU_1mc_defend";
	game["ab_defend"] = "AB_1mc_defend";

	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
}

onStartGameType()
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	

	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	// war server - fazer o ataque sempre atacar
	if ( getDvarInt ( "war_server" ) == 1 && getDvarInt ( "ws_start" ) == 2 && getDvarInt ( "ws_real") > 0 )
	{	
		if( getDvar("ws_attackers") != "")
		{
			if ( getDvar("ws_attackers") == "blue" )
			{
				if ( maps\mp\gametypes\_warserver::Testa_Cor ( game["attackers"] ) == "red" )
					game["switchedsides"] = true;
			}
			else if ( getDvar("ws_attackers") == "red" )
			{
				if ( maps\mp\gametypes\_warserver::Testa_Cor ( game["attackers"] ) == "blue" )
					game["switchedsides"] = true;
			}
		}
	}
	
	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	setClientNameMode("manual_change");

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_FRONT_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_FRONT_DEFENDER" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_FRONT_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_FRONT_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_FRONT_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_FRONT_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_FRONT_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_FRONT_DEFENDER_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	//level.EhSD = isDefined( getEnt( "mp_sd_spawn_attacker", "targetname" ) );
	
	level.EhSD = true;
	level.spawn_all = getentarray( "mp_sd_spawn_attacker", "classname" );
	if ( !level.spawn_all.size )
	{
		level.EhSD = false;
	}

	// inicializa spawn da defesa
	level.defend_spawn = undefined;
	level.attack_spawn = undefined;	
	
	if ( level.EhSD == true )
	{
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
		level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
		level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	}
	else
	{
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	}
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
		
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "dom";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	level.displayRoundEndText = false;
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	//elimination style
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		level.onEndGame = ::onEndGame;

	// self.pers["team"] = allied / axis
	// game["allies"], game["axis"] = marines, opfor...
	//  game["attackers"] = saber quem tá atacando
	if ( level.Remember != 0 )
	{
		thread HajasPlaySound ( game["attackers"], game["allies"], game["axis"]);		
	}

	SetaMensagens();	

	if ( level.EhSD == true && level.Type == 1 )
	{
		// cria flag
		thread defFlag();	
	}	
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}

// ========================================================================
//		Início Flag
// ========================================================================

defFlag()
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
	
	precacheString( &"MP_CAPTURING_FLAG" );
	precacheString( &"MP_LOSING_FLAG" );
	precacheString( &"MP_DOM_YOUR_FLAG_WAS_CAPTURED" );
	precacheString( &"MP_DOM_ENEMY_FLAG_CAPTURED" );
	precacheString( &"MP_DOM_NEUTRAL_FLAG_CAPTURED" );

	precacheString( &"MP_ENEMY_FLAG_CAPTURED_BY" );
	precacheString( &"MP_NEUTRAL_FLAG_CAPTURED_BY" );
	precacheString( &"MP_FRIENDLY_FLAG_CAPTURED_BY" );
	
	
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		logPrint( "^1Not enough domination flags found in level!" );
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
	
	level.flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[level.flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[level.flags.size] = secondaryFlags[index];
		
	FlagCentral = SelecionaFlag();
	
	level.domFlags = [];
	for ( index = 0; index < 1; index++ )
	{
		trigger = level.flags[index];
		trigger.origin = FlagCentral + (0,0,-5);
		if ( isDefined( trigger.target ) )
		{
			visuals[0] = getEnt( trigger.target, "targetname" );
		}
		else
		{
			visuals[0] = spawn( "script_model", trigger.origin );
			visuals[0].angles = trigger.angles;
		}

		visuals[0] setModel( game["flagmodels"]["neutral"] );

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::setOwnerTeam( game["defenders"] );
		domFlag.visuals[0] setModel( game["flagmodels"][game["defenders"]] );		
		
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( 60.0 );
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
		domFlag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		domFlag.onUse = ::onUse;
		domFlag.onBeginUse = ::onBeginUse;
		domFlag.onUseUpdate = ::onUseUpdate;
		domFlag.onEndUse = ::onEndUse;
		
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
	}
	
	flagSetup();
}

SelecionaFlag()
{
	// acha flag da defesa
	spawns_final = undefined;
	
	spawns_final = level.defend_spawn;
	
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;	
	
	if ( game["switchedspawnsides"] )
	{
		spawns_final = level.attack_spawn;
	}
	else
	{
		spawns_final = level.defend_spawn;
	}
	
	return spawns_final;
}

flagSetup()
{
	closestdist = undefined;
	closestdesc = undefined;
	maperrors = [];
	descriptorsByLinkname = [];

	// (find each flag_descriptor object)
	descriptors = getentarray("flag_descriptor", "targetname");
	
	flags = level.flags;
	
	for (j = 0; j < descriptors.size; j++)
	{
		dist = distance(flags[0].origin, descriptors[j].origin);
		if (!isdefined(closestdist) || dist < closestdist) {
			closestdist = dist;
			closestdesc = descriptors[j];
		}
	}
	
	descriptors = [];
	descriptors[0] = closestdesc;
	
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
		
		if (!isdefined(closestdesc)) {
			maperrors[maperrors.size] = "there is no flag_descriptor in the map! see explanation in dom.gsc";
			break;
		}
		if (isdefined(closestdesc.flag)) {
			maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + closestdesc.script_linkname + "\" is nearby more than one flag; is there a unique descriptor near each flag?";
			continue;
		}
		flags[i].descriptor = closestdesc;
		closestdesc.flag = flags[i];
		descriptorsByLinkname[closestdesc.script_linkname] = closestdesc;
	}
	
	if (maperrors.size > 0)
	{
		logPrint("^1------------ Map Errors ------------\n");
		for(i = 0; i < maperrors.size; i++)
			logPrint(maperrors[i]);
		logPrint("^1------------------------------------\n");
		
		//maps\mp\_utility::error("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
}

onBeginUse( player )
{
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 1 );	
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
		ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
		if ( ownerTeam != "neutral" )
		{
			statusDialog( "ourflag", ownerTeam );
			statusDialog( "enemyflag", team );			
		}

		self.didStatusNotify = true;
	}
}


onEndUse( team, player, success )
{
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 0 );

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
}

onUse( player )
{
	team = player.pers["team"];
	oldTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	label = self maps\mp\gametypes\_gameobjects::getLabel();
	
	player logString( "flag captured the flag!" );
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
	self.visuals[0] setModel( game["flagmodels"][team] );
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel(), team );	
	
	level.useStartSpawns = false;
	
	assert( team != "neutral" );
	
	if ( oldTeam == "neutral" )
	{
		otherTeam = getOtherTeam( team );
		thread printAndSoundOnEveryone( team, otherTeam, &"MP_NEUTRAL_FLAG_CAPTURED_BY", &"MP_NEUTRAL_FLAG_CAPTURED_BY", "mp_war_objective_taken", undefined, player );
	}
	else
	{
		thread printAndSoundOnEveryone( team, oldTeam, &"MP_ENEMY_FLAG_CAPTURED_BY", &"MP_FRIENDLY_FLAG_CAPTURED_BY", "mp_war_objective_taken", "mp_war_objective_lost", player );
		
		statusDialog( "enemyflag_capt", team );
		statusDialog( "ourflag_capt", oldTeam );	
		
		level.bestSpawnFlag[ oldTeam ] = self.levelFlag;
	}

	thread giveFlagCaptureXP( self.touchList[team] );

	thread FincouFlag();
}

FincouFlag()
{
	wait 2;
	
	//iprintlnbold("Defesa sefu!");
			
	// termina o round
	level.overrideTeamScore = true;
	level.displayRoundEndText = true;
	
	msg_final = level.defend_secured;

	iPrintLn( msg_final );
	makeDvarServerInfo( "ui_text_endreason", msg_final );
	setDvar( "ui_text_endreason", msg_final );
	
	thread maps\mp\gametypes\_globallogic::endGame( game["attackers"], msg_final );
}

giveFlagCaptureXP( touchList )
{
	wait .05;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	players = getArrayKeys( touchList );
	for ( index = 0; index < players.size; index++ )
	{
		touchList[players[index]].player thread [[level.onXPEvent]]( "capture" );
		maps\mp\gametypes\_globallogic::givePlayerScore( "capture", touchList[players[index]].player );
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

// ========================================================================
//		Fim Flag
// ========================================================================


onSpawnPlayer()
{
	self.usingObj = undefined;

	if ( level.EhSD == true )
	{
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_sd_spawn_attacker";
		else
			spawnPointName = "mp_sd_spawn_defender";
		
		if ( !isDefined( game["switchedspawnsides"] ) )
			game["switchedspawnsides"] = false;
		
		if ( game["switchedspawnsides"] )
		{
			if ( spawnPointName == "mp_sd_spawn_defender")
			{
				spawnPointName = "mp_sd_spawn_attacker";
			}
			else
			{
				spawnPointName = "mp_sd_spawn_defender";
			}
		}		
	}
	else
	{
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_tdm_spawn_allies_start";
		else
			spawnPointName = "mp_tdm_spawn_axis_start";
		
		if ( !isDefined( game["switchedspawnsides"] ) )
			game["switchedspawnsides"] = false;
		
		if ( game["switchedspawnsides"] )
		{
			if ( spawnPointName == "mp_tdm_spawn_axis_start")
			{
				spawnPointName = "mp_tdm_spawn_allies_start";
			}
			else
			{
				spawnPointName = "mp_tdm_spawn_axis_start";
			}
		}			
	}

	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( self.pers["team"] == game["attackers"] )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		}
		else
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
	}
	else
		self spawn( spawnpoint.origin, spawnpoint.angles );	

	level notify ( "spawned_player" );

	// msg
	if ( level.SidesMSG == 1 )
	{	
		if ( self.pers["team"] != game["defenders"] )
			self iPrintLnbold( level.attack_msg );
		else
			self iPrintLnbold( level.defend_msg );
	}	
	
	// voice order
	if ( self.pers["team"] != game["defenders"] )
		self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
	else
		self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "defend" );
}

onOneLeftEvent( team )
{

	warnLastPlayer( team );
}

warnLastPlayer( team )
{
	if ( !isdefined( level.warnedLastPlayer ) )
		level.warnedLastPlayer = [];
	
	if ( isDefined( level.warnedLastPlayer[team] ) )
		return;
		
	level.warnedLastPlayer[team] = true;

	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( isDefined( player.pers["team"] ) && player.pers["team"] == team && isdefined( player.pers["class"] ) )
		{
			if ( player.sessionstate == "playing" && !player.afk )
				break;
		}
	}
	
	if ( i == players.size )
		return;
	
	players[i] thread giveLastAttackerWarning();
}


giveLastAttackerWarning()
{
	self endon("death");
	self endon("disconnect");
	
	fullHealthTime = 0;
	interval = .05;
	
	while(1)
	{
		if ( self.health != self.maxhealth )
			fullHealthTime = 0;
		else
			fullHealthTime += interval;
		
		wait interval;
		
		if (self.health == self.maxhealth && fullHealthTime >= 3)
			break;
	}
	
	//self iprintlnbold(&"MP_YOU_ARE_THE_ONLY_REMAINING_PLAYER");
	self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "last_alive" );
	
	self maps\mp\gametypes\_missions::lastManSD();

	// hajas duel
	if ( level.HajasDuel > 0 )
	{
		maps\mp\gametypes\_globallogic::HajasDuel();
	}	
}


onTimeLimit()
{
	// da vitoria aos defenders em caso de empate
	winner = undefined;

	if ( game["defenders"] == "allies" )
		winner = "allies";
	else
		winner = "axis";

	logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

	// i think these two lines are obsolete
	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	
	thread maps\mp\gametypes\_globallogic::endGame( winner, game["strings"]["time_limit_reached"] );
}

onRoundSwitchSpawn()
{
	// switch spawn sides
	
	if ( !isdefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedspawnsides"] = !game["switchedspawnsides"];
		}
		else
		{
			level.halftimeSubCaption = "";
						
		}
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedspawnsides"] = !game["switchedspawnsides"];
	}		
}

onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedsides"] = !game["switchedsides"];
		}
		else
		{
			level.halftimeSubCaption = "";
						
		}
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}

getBetterTeam()
{
	kills["allies"] = 0;
	kills["axis"] = 0;
	deaths["allies"] = 0;
	deaths["axis"] = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		team = player.pers["team"];
		if ( isDefined( team ) && (team == "allies" || team == "axis") )
		{
			kills[ team ] += player.kills;
			deaths[ team ] += player.deaths;
		}
	}
	
	if ( kills["allies"] > kills["axis"] )
		return "allies";
	else if ( kills["axis"] > kills["allies"] )
		return "axis";
	
	// same number of kills

	if ( deaths["allies"] < deaths["axis"] )
		return "allies";
	else if ( deaths["axis"] < deaths["allies"] )
		return "axis";
	
	// same number of deaths
	
	if ( randomint(2) == 0 )
		return "allies";
	return "axis";
}

onEndGame( winningTeam )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
}

HajasPlaySound ( ataque, aliado, eixo )
{
	self endon ("disconnect");
	self endon ("death");
	self endon ( "game_ended" );

	wait 50;

   // thread HajasPlaySound ( game["attackers"], game["allies"], game["axis"]);

	while(1)
	{
   		if( ataque == "allies" )
		{
			if( aliado == "marines" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["us_attack"], "allies" );
			}
			if( aliado == "sas" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["uk_attack"], "allies" );
			}
			if( eixo == "russian" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["ru_defend"], "axis" );
			}
			if( eixo == "opfor" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["ab_defend"], "axis" );
			}		
		}
		else
		{
			if( eixo == "russian" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["ru_attack"], "axis" );
			}
			if( eixo == "opfor" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["ab_attack"], "axis" );
			}
			if( aliado == "marines" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["us_defend"], "allies" );
			}
			if( aliado == "sas" )
			{
				maps\mp\_utility::playSoundOnPlayers( game["uk_defend"], "allies" );
			}		
		}
		wait level.Remember;
	}
}


SetaMensagens()
{
	if ( getDvar( "scr_front_attack" ) == "" )
	{
		level.attack_msg =  "^9Attack^7!";
	}
	else
	{
		level.attack_msg = getDvar( "scr_front_attack" );
	}
	
	if ( getDvar( "scr_front_defend" ) == "" )
	{
		level.defend_msg =  "^9Defend^7!";
	}
	else
	{
		level.defend_msg = getDvar( "scr_front_defend" );
	}
	
	if ( getDvar( "scr_front_secured" ) == "" )
	{
		level.defend_secured =  "Territory Secured";
	}
	else
	{
		level.defend_secured = getDvar( "scr_front_secured" );
	}	
}