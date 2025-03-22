#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	if ( getDvar( "waves_gametype" ) == "" )
		level.waves_gametype = 0;
	else
		level.waves_gametype = getDvarInt( "waves_gametype" );

	if ( level.waves_gametype == 0 )
		init();
	else if ( level.waves_gametype == 1 )
	{
		maps\mp\gametypes\resist::main();
		return;
	}
}

init()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "waves", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "waves", 8, 4, 40 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "waves", 3, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "waves", 4, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "waves", 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "waves", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "waves", 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerKillCamDvar( "waves", 0, 0, 1 );
	
	// tem q setar fixo pro Resist
	SetDvar( "scr_waves_playerrespawndelay", -1 );
	SetDvar( "scr_waves_waverespawndelay", 60 );
	
	// 1 = Flag
	maps\mp\gametypes\_globallogic::registerTypeDvar( "waves", 1, 0, 1 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.onTimeLimit = ::onTimeLimit; 
	level.endGameOnScoreLimit = false;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	level.overrideTeamScore = true;
	level.onRespawnDelay = ::getRespawnDelay;
	
	level.onDeadEvent = ::onDeadEvent;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["defense_obj"] = "security_complete";
	
	game["dialog"]["positions_lock"] = "positions_lock";
	game["dialog"]["keepfighting"] = "keepfighting";
	
	game["dialog"]["ourflag"] = "ourflag";
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	game["dialog"]["enemyflag"] = "enemyflag";
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";	
	
	level.reinf = false;
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

	flagBaseFX = [];
	flagBaseFX["marines"] = "misc/ui_flagbase_silver";
	flagBaseFX["sas"    ] = "misc/ui_flagbase_black";
	flagBaseFX["russian"] = "misc/ui_flagbase_red";
	flagBaseFX["opfor"  ] = "misc/ui_flagbase_gold";
}

onStartGameType()
{
	//garante que sempre tera todas as armas
	level.HajasWeap = 0;

	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	level.strikefoi = false;
	level.WavesProtected = true;

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
				{
					game["switchedsides"] = true;
				}
			}
			else if ( getDvar("ws_attackers") == "red" )
			{
				if ( maps\mp\gametypes\_warserver::Testa_Cor ( game["attackers"] ) == "blue" )
				{
					game["switchedsides"] = true;
				}
			}
		}
	}
	else // se não for war e for BOT-COOP players somente defendem!
	{
		if ( getDvarInt("fl_bots") == 1 && getDvarInt("fl_bots_coop") > 0)
		{
			setDvar( "scr_waves_roundswitch", 0 ); // não mudar de lado
			setDvar( "scr_waves_roundlimit", 1 ); // só um round
			if ( getDvarInt("fl_bots_coop") == 1 ) //allies
			{
				if ( game["defenders"] == "axis" )
					game["switchedsides"] = true;
			}
			else if ( getDvarInt("fl_bots_coop") == 2 ) //axis
			{
				if ( game["defenders"] == "allies" )
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

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_WAVES_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_WAVES_DEFENDER" );
	
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_WAVES_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_WAVES_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_WAVES_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_WAVES_DEFENDER_HINT" );
			
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
	
	dist_spawns = distance( level.defend_spawn , level.attack_spawn );
	level.dist_inicial = int(dist_spawns / 2);		
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "dom";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	level.displayRoundEndText = true;
	maps\mp\gametypes\_gameobjects::main(allowed);

	// calcula tempo pra reinforcements
	tempo_max = getDvarInt( level.timeLimitDvar );
	tempo_max = ( (tempo_max - 1) * 60 );
	tempo_min = tempo_max - 60;
	tempo_reinf = randomintrange ( tempo_min, tempo_max );
	level.chega_reinf = gettime() + tempo_reinf * 1000;
	
	// thread pra calcular os reforços
	thread ControlaReinf( game["defenders"], tempo_reinf );
	thread ControlaDefesa( game["defenders"] );
	
	// seta mensagens
	SetaMensagens();
	
	if ( level.EhSD == true && level.Type == 1 )
	{
		// cria flag
		thread defFlag();	
	}
	
	thread WavesLiberaAtaque();
	
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
	flag_defesa = undefined;
	
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
		
		maps\mp\_utility::error("Map errors. See above");
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
	
	msg_final = level.zone_sec;

	iPrintLn( msg_final );
	makeDvarServerInfo( "ui_text_endreason", msg_final );
	setDvar( "ui_text_endreason", msg_final );
	
	thread Waves_EndGame( game["attackers"], msg_final );
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
delayedLeaderDialogBothTeams( sound1, team1, sound2, team2 )
{
	wait .1;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialogBothTeams( sound1, team1, sound2, team2 );
}

// ========================================================================
//		Fim Flag
// ========================================================================


ControlaReinf( defenders, tempo )
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	level endon( "game_ended" );
	
	wait tempo;
	
	level.reinf = true;
	level.inOvertime = true;
	
	thread forceSpawnTeam( game["defenders"] );
	
	for ( index = 0; index < level.players.size; index++ )
	{
		if ( level.players[index].pers["team"] == game["defenders"] )
		{
			level.players[index] notify("force_spawn");
			level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( level.reinf_msg, level.hold_msg, undefined, (1, 0, 0), "mp_last_stand" );

			level.players[index] setClientDvars("cg_deadChatWithDead", 1,
								"cg_deadChatWithTeam", 0,
								"cg_deadHearTeamLiving", 0,
								"cg_deadHearAllLiving", 0,
								"cg_everyoneHearsEveryone", 0,
								"g_compassShowEnemies", 0 );
			
			thread WavesSound( level.players[index], "keepfighting" );	
		}
		else
		{
			thread WavesSound( level.players[index], "losing" );	
		}
	}
	
	thread maps\mp\gametypes\_hardpoints::WavesReinf( game["defenders"] );
	
	thread ControlaAtaque( game["attackers"] );
}

WavesSound( player, sound )
{
	wait 3;
	player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( sound );
}

ControlaDefesa( defenders )
{
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );	
	
	while(1)
	{
		wait 5;
		//iprintlnbold(level.aliveCount[defenders]);
		if ( level.everExisted[defenders] && level.aliveCount[defenders] == 0 )
		{
			// termina o round
			level.overrideTeamScore = true;
			level.displayRoundEndText = true;
			
			msg_final = game["strings"][game["defenders"]+"_eliminated"];

			iPrintLn( msg_final );
			makeDvarServerInfo( "ui_text_endreason", msg_final );
			setDvar( "ui_text_endreason", msg_final );
			
			Waves_EndGame( game["attackers"], msg_final );
			return;			
		}
	}
}

ControlaAtaque( attackers )
{
	level endon( "game_ended" );
	
	thread forceSpawnTeam( game["attackers"] );
	
	while(1)
	{
		wait 5;
		//iprintlnbold(level.aliveCount[attackers]);
		if ( level.everExisted[attackers] && level.aliveCount[attackers] == 0 )
		{
			// termina o round
			level.overrideTeamScore = true;
			level.displayRoundEndText = true;

			iPrintLn( level.zone_sec );
			makeDvarServerInfo( "ui_text_endreason", level.zone_sec );
			setDvar( "ui_text_endreason", level.zone_sec );
			
			Waves_EndGame( game["defenders"], level.zone_sec );
			return;			
		}
	}
}

onSpawnPlayer()
{
	self.usingObj = undefined;
	
	if ( !isDefined(self.fl_1stSpawn) ) 
		self.fl_1stSpawn = true; // indica que é o primeiro spawn e pode jogar!	
	else
		self.fl_1stSpawn = false; // indica que não é mais o primeiro spawn	

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
				spawnPointName = "mp_sd_spawn_attacker";
			else
				spawnPointName = "mp_sd_spawn_defender";
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
				spawnPointName = "mp_tdm_spawn_allies_start";
			else
				spawnPointName = "mp_tdm_spawn_axis_start";
		}			
	}

	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
	if ( getDvarInt ( "frontlines_abmode" ) == 0 )
	{
		self spawn( spawnpoint.origin, spawnpoint.angles );
		level notify ( "spawned_player" );

		if ( self.pers["team"] == game["attackers"] )
		{
			if( level.strikefoi == false )
				self freezeControls( true );
			else
			{
				if ( level.SidesMSG == 1 )
					self iPrintLnbold( level.msg_attack );
				self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
			}
		}
		else if ( self.pers["team"] == game["defenders"] )
		{
			if ( level.strikefoi == true && level.reinf == false )
			{
				if ( self.fl_1stSpawn == false )
					thread mata_player( self );
			}				
			else
			{	
				if ( level.SidesMSG == 1 )
					self iPrintLnbold( level.msg_defend );
				
				self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "defend" );
				thread maps\mp\gametypes\_class::WavesArmasDefesa();
			}
		}
	}
	else // airborne
	{
		if ( self.pers["team"] == game["attackers"] )
		{
			if( level.strikefoi == false )
			{
				self spawn( spawnpoint.origin, spawnpoint.angles );
				level notify ( "spawned_player" );
				self freezeControls( true );
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
				self thread AirborneSeguraAtaque();
			}
			else
			{
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );	
				maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );			
				level notify ( "spawned_player" );
				if ( level.SidesMSG == 1 )
					self iPrintLnbold( level.msg_attack );
				self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
			}
		}
		else if ( self.pers["team"] == game["defenders"] )
		{
			
			if ( level.strikefoi == true && level.reinf == false )
			{
				if ( self.fl_1stSpawn == false )
					thread mata_player( self );
				else
				{
					spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
					spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
					maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );				
					level notify ( "spawned_player" );
				}
			}	
			else if ( level.strikefoi == true && level.reinf == true )
			{
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
				maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );				
				level notify ( "spawned_player" );
			}
			else
			{
				self spawn( spawnpoint.origin, spawnpoint.angles );
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
				level notify ( "spawned_player" );
				if ( level.SidesMSG == 1 )
					self iPrintLnbold( level.msg_defend );
				
				self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "defend" );
				thread maps\mp\gametypes\_class::WavesArmasDefesa();
			}
		}	
	}
}

mata_player( player )
{
	wait (0.5);
	player.switching_teams = true;
	player.joining_team = "spectator";
	player.leaving_team = self.pers["team"];
	player suicide();	
}

onDeadEvent( team )
{
	if ( team == "all" )
		Waves_EndGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	else if ( team == game["attackers"] )
		Waves_EndGame( game["defenders"], level.zone_sec );
	else if ( team == game["defenders"] )
		Waves_EndGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
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
	makeDvarServerInfo( "ui_text_endreason", level.zone_sec );
	setDvar( "ui_text_endreason", level.zone_sec );
	
	Waves_EndGame( winner, level.zone_sec );
}


Waves_EndGame( winningTeam, endReasonText )
{
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();

	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
		
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

getRespawnDelay()
{
	if ( self.pers["team"] == game["defenders"] )
	{
		if ( level.reinf == false )
		{
			self.lowerMessageOverride = undefined;
			self.lowerMessageOverride = &"HAJAS_WAVES_WAITING";
			
			return (1000);
		}
	}
}

forceSpawnTeam( team )
{
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( !isdefined( player ) )
			continue;
		
		if ( player.pers["team"] == team )
		{
			player.lowerMessageOverride = undefined;
			player notify( "force_spawn" );
			wait .1;
		}
	}
}

onOneLeftEvent( team )
{
	if ( team == game["defenders"] )
	{
		warnLastPlayer( team );
	}
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
	
	players[i] thread giveLastDefenderWarning();
}


giveLastDefenderWarning()
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

SetaMensagens()
{
	if ( getDvar( "scr_waves_msg_reinf" ) == "" )
	{
		level.reinf_msg = "Reinforcements have Arrived!";
	}
	else
	{
		level.reinf_msg = getDvar( "scr_waves_msg_reinf" );
	}
	
	if ( getDvar( "scr_waves_msg_hold" ) == "" )
	{
		level.hold_msg = "Hold on a Little Longer";
	}
	else
	{
		level.hold_msg = getDvar( "scr_waves_msg_hold" );
	}	
	
	if ( getDvar( "scr_waves_msg_secured" ) == "" )
	{
		level.zone_sec = "Zone Secured";
	}
	else
	{
		level.zone_sec = getDvar( "scr_waves_msg_secured" );
	}	

	if ( getDvar( "scr_waves_msg_attack" ) == "" )
	{
		level.msg_attack = "^9Attack^7!";
	}
	else
	{
		level.msg_attack = getDvar( "scr_waves_msg_attack" );
	}
	
	if ( getDvar( "scr_waves_msg_defend" ) == "" )
	{
		level.msg_defend = "^9Defend^7!";
	}
	else
	{
		level.msg_defend = getDvar( "scr_waves_msg_defend" );
	}	
}

// controles

WavesLiberaAtaque()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	strike_msg = getDvar("scr_waves_msg_strike");
	
	if ( strike_msg == "" )
	{
		strike_msg = "Waiting for Strike Order!";
	}	

	maps\mp\gametypes\_globallogic::leaderDialog( "goodtogo", game["attackers"] );

	strike_wait = randomIntRange ( 45, 70 );
	dura_timer = int(( strike_wait - 5 )*1000);
	
	if ( dura_timer > 60000 )
		dura_timer = 60000;	
	
	//iprintln ("duration = " + dura_timer );
		
	// texto "Waiting for the Strike orders!"
	waves_strike = createServerFontString(  "objective", 2, game["attackers"] );
	waves_strike setPoint( "TOP", "TOP", 0, 120 );
	waves_strike.glowColor = (0.52,0.28,0.28);
	waves_strike.glowAlpha = 1;
	waves_strike setText( strike_msg );
	waves_strike.hideWhenInMenu = true;
	waves_strike.archived = false;
	waves_strike setPulseFX( 100, dura_timer, 1000 );	
	
	// deleta quando termina o jogo
	thread WavesRemoveTexto(waves_strike);
	
	// timer
	timerDisplay = [];
	timerDisplay[game["attackers"]] = createServerTimer( "objective", 4, game["attackers"] );
	timerDisplay[game["attackers"]] setPoint( "TOP", "TOP", 0, 150 );
	timerDisplay[game["attackers"]].glowColor = (0.52,0.28,0.28);
	timerDisplay[game["attackers"]].glowAlpha = 1;
	timerDisplay[game["attackers"]].alpha = 1;
	timerDisplay[game["attackers"]].archived = false;
	timerDisplay[game["attackers"]].hideWhenInMenu = true;
	timerDisplay[game["attackers"]] setTimer( strike_wait );
	
	// deleta quando termina o jogo
	thread WavesRemoveClock( timerDisplay[game["attackers"]] );

	wait strike_wait;
	
	// deleta timer
	if ( isDefined( waves_strike ) )
		waves_strike destroyElem();		
	timerDisplay[game["attackers"]].alpha = 0;		
	
	level.strikefoi = true;	
	thread WavesProtection();

	for ( index = 0; index < level.players.size; index++ )
	{
		if ( level.players[index].team == game["attackers"] )
		{
			thread maps\mp\gametypes\_class::WavesArmasAtaque( level.players[index] );
			level.players[index] freezeControls( false );
			if ( getDvarInt ( "frontlines_abmode" ) == 0 )
				level.players[index] enableWeapons();
			if ( level.SidesMSG == 1 )
				level.players[index] iPrintLnbold( level.msg_attack );
			level.players[index] maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
		}
	}
	
	
	maps\mp\gametypes\_globallogic::leaderDialog( "offense_obj", game["attackers"], "introboost" );
	maps\mp\gametypes\_globallogic::leaderDialog( "secure_all", game["defenders"], "secure_all" );
}

WavesProtection()
{
	level.WavesProtected = true;
	wait 5;
	level.WavesProtected = false;
}


WavesDefesaMsg()
{
	defense_msg = getDvar("scr_waves_msg_defense");
	
	if ( defense_msg == "" )
		defense_msg = "Hurry! Setup our defenses!";
		
	self.waves_defesa = newClientHudElem(self);
	self.waves_defesa.x = 320;
	self.waves_defesa.alignX = "center";
 	self.waves_defesa.y = 180;
	self.waves_defesa.alignY = "middle";
	self.waves_defesa.sort = -3;
	self.waves_defesa setPulseFX( 100, 8000, 1000 );
	self.waves_defesa.alpha = 1;
	self.waves_defesa.fontScale = 2;
	self.waves_defesa.glowColor = (0.52,0.28,0.28);
	self.waves_defesa.glowAlpha = 1;	
	self.waves_defesa.hideWhenInMenu = true;
	self.waves_defesa.archived = true;		
	self.waves_defesa setText( defense_msg );
	
	// deleta quando termina o jogo
	thread WavesRemoveTexto(self.waves_defesa);
	
	while( level.strikefoi == false )
		wait 1;

	if ( isDefined( self.waves_defesa ) )
		self.waves_defesa destroyElem();	
}

WavesRemoveTexto( waves_texto )
{
	level waittill("game_ended");
	if ( isDefined( waves_texto ) )
		waves_texto destroyElem();	
}
WavesRemoveClock( timerDisplay )
{
	level waittill("game_ended");
	timerDisplay.alpha = 0;
}

AirborneSeguraAtaque()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	while ( level.strikefoi == false )
		wait ( 0.05 );
		
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
	spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, true );
	level.WavesProtected = false;				
}