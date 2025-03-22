#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

registerCommanderVIPDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.CommanderVIPDvar = dvarString;
	level.CommanderVIPMin = minValue;
	level.CommanderVIPMax = maxValue;
	level.CommanderVIP = getDvarInt( level.CommanderVIPDvar );
}

registerCommanderHardpointsDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.CommanderHardpointsDvar = dvarString;
	level.CommanderHardpointsMin = minValue;
	level.CommanderHardpointsMax = maxValue;
	level.CommanderHardpoints = getDvarInt( level.CommanderHardpointsDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	level.LiveVIP = false;
	level.endtext = "";
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "commander", 3, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "commander", 5, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "commander", 6, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "commander", 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "commander", 1, 1, 50 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "commander", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerNextVIPDvar( "commander", 2, 0, 2 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "commander", 1, 0, 1 );
		
	// registra vars do vip/commander
	registerCommanderVIPDvar( "scr_commander_vip", 0, 0, 1 );
	maps\mp\gametypes\_globallogic::registerVIPNameDvar( "scr_commander_name", 1, 0, 1 );
	registerCommanderHardpointsDvar( "scr_commander_hardpoints", 3, 0, 3 );
	
	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.onTimeLimit = ::onTimeLimit; 
	level.onDeadEvent = ::onDeadEvent;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.endGameOnScoreLimit = false;
	
	level.overrideTeamScore = true;
	
	//level.status_icon = "";
	
	// controlar morte vip/commandante
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;	

	game["dialog"]["gametype"] = "team_hardcore";

	game["dialog"]["offense_obj"] = "obj_destroy";
	game["dialog"]["defense_obj"] = "obj_defend";
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
	
	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	setClientNameMode( "manual_change" );
	
	// adequa todas as msgs para VIP ou COMMANDER
	if ( level.CommanderVIP == 1 )
	{
		maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_VIP_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_VIP_DEFENDER" );
		
		if ( level.splitscreen )
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_VIP_ATTACKER" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_VIP_DEFENDER" );
		}
		else
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_VIP_ATTACKER_SCORE" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_VIP_DEFENDER_SCORE" );
		}
		
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_VIP_ATTACKER_HINT" );
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_VIP_DEFENDER_HINT" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_CMD_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_CMD_DEFENDER" );
		
		if ( level.splitscreen )
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_CMD_ATTACKER" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_CMD_DEFENDER" );
		}
		else
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_CMD_ATTACKER_SCORE" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_CMD_DEFENDER_SCORE" );
		}
		
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_CMD_ATTACKER_HINT" );
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_CMD_DEFENDER_HINT" );		
	}
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
		
	//level.EhSD = isDefined( getEnt( "mp_sd_spawn_attacker", "targetname" ) );
	
	level.EhSD = true;
	level.spawn_all = getentarray( "mp_sd_spawn_attacker", "classname" );
	if ( !level.spawn_all.size )
		level.EhSD = false;
	
	if ( level.EhSD == true )
	{
		//logPrint("tudo certo!" + "\n");
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	}
	else
	{
		//logPrint("não achou? deu merda!" + "\n");
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

	allowed[0] = "vip";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	level.displayRoundEndText = false;
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	SetaMensagens();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );	
}

onPrecacheGameType()
{
	thread defineIcons();

	//carrega icones vip/commander
	if ( level.CommanderVIP == 1 )
	{
		precacheShader(level.hudvip_allies);
		precacheShader(level.hudvip_axis);
		precacheStatusIcon( "killiconheadshot" );
	}
	else
	{
		precacheStatusIcon( "faction_128_usmc" );
		precacheStatusIcon( "faction_128_sas" );
		precacheStatusIcon( "faction_128_arab" );
		precacheStatusIcon( "faction_128_ussr" );
	}

	precacheShader( "compass_waypoint_defend" );
	precacheShader( "waypoint_defend" );
	
	//sounds
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";
}

defineIcons()
{
	//carrega icones vip/commander
	if ( level.CommanderVIP == 1 )
	{
		// seta vip icons
		if( game["allies"] == "marines" )
			level.hudvip_allies = "killiconheadshot";
		else
			level.hudvip_allies = "killiconheadshot";
		
		if( game["axis"] == "russian" )
			level.hudvip_axis = "killiconheadshot";
		else
			level.hudvip_axis = "killiconheadshot";
	}
	else
	{
		// seta commander icons
		if( game["allies"] == "marines" )
			level.hudcommander_allies = "faction_128_usmc";
		else
			level.hudcommander_allies = "faction_128_sas";

		if( game["axis"] == "russian" )
			level.hudcommander_axis = "faction_128_ussr";
		else
			level.hudcommander_axis = "faction_128_arab";
	}
}

onSpawnPlayer()
{
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
	
	// deleta skin do vip/commander se sobrou do round anterior
	if ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP" )
		VIPloadModelBACK();
	
	// caso mude de lado, o próximo VIP será o primeiro spawn do novo time
	if ( isDefined ( game["VIPteam"] ) )
	{
		if ( game["VIPteam"] == game["attackers"] )
			game["VIPname"] = "";
	}
	else
		game["VIPname"] = "";

	if ( level.LiveVIP == false && self.pers["team"] == game["defenders"])
	{
		// next = 0 : último ìd
		// next = 1 : melhor score 
		// next = 2 : random
		
		if ( level.NextVIP > 0 )
		{
			// caso não volte nada, será o primeiro sempre...
			if ( game["VIPname"] == "" )
				SpawnVIP();
			else
			{
				if ( game["VIPname"] == self.name )
					SpawnVIP();
				else
					SpawnSoldado();
			}
		}
		else
			SpawnVIP();
	}
	else
		SpawnSoldado();
	
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
}

SpawnVIP()
{
	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
		self iPrintLnbold( level.msg_you );
	
	self thread defineIcons();
	self thread createVipIcon();

	// troca a skin pra VIP/Commander
	VIPloadModel(); 	
	
	// diz q o mapa já tem um vip/commander vivo
	level.LiveVIP = true;	
	
	// icone defend!
	//self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	
	// seta nome do Commander para mostrar na tela
	level.ShowName = self.name;	
	
	// carrega icon no placar
	self.statusicon = level.status_icon;
	
	// icone defend!
	thread CriaTriggers( self );	
}

CriaTriggers( player )
{
	while ( !self.hasSpawned )
		wait ( 0.1 );

	wait ( 0.1 );
	pos = player.origin + (0,0,-60);
	
	if ( !isDefined ( level.Docs ) )
	{
		docs["pasta_trigger"] = spawn( "trigger_radius", pos, 0, 20, 100 );
		docs["pasta"][0] = spawn( "script_model", pos);
		docs["zone_trigger"] = spawn( "trigger_radius", pos, 0, 50, 100 );	
		level.Docs = SpawnDocs( docs["pasta_trigger"], docs["pasta"] );	
	}
	else
	{
		level.Docs.trigger.origin = pos;
		level.Docs maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
		level.Docs maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );		
	}	
	level.Docs maps\mp\gametypes\_gameobjects::setPickedUp( player );
	
	
	if(isDefined(player.bIsBot) && player.bIsBot) 
	{
		wait 0.5;
		self TakeAllWeapons();
		
		if ( level.CommanderVIP )
		{
			player.weaponPrefix = "colt45_mp";
			player.pers["weapon"] = "colt45_mp";
		}
		else
		{
			player.weaponPrefix = "m4_reflex_mp";
			player.pers["weapon"] = "m4_reflex_mp";
		}
	}	
}

SpawnDocs( trigger, visuals )
{
	pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( game["defenders"], trigger, visuals, (0,0,100) );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
	pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );

	pastaObject.onPickup = ::onPickupDocs;	   
	pastaObject.onDrop = ::onDropDocs;
	pastaObject.allowWeapons = true;
	   
	return pastaObject;	
}

onDropDocs( player )
{
	level.Docs maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	level.Docs maps\mp\gametypes\_gameobjects::allowCarry( "none" );
}

onPickupDocs( player )
{
	team = player.pers["team"];
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
}


SpawnSoldado()
{
	self.isCommander = false;

	if ( self.pers["team"] == game["defenders"])
	{
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.msg_protect );
	
		if ( level.VIPName == 1 )
			thread ShowVipName();
	}
	else
	{
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.msg_kill );	
	}
}

ShowVipName()
{
	self endon ("disconnect");
	self endon ("death");
	self endon ( "game_ended" );
	
	wait 5;
	if ( !isDefined( level.ShowName ) )
	{
		wait 5;
	}
	if ( isDefined( level.ShowName ) )
	{
		msg_info = "^9" + level.ShowName + level.msg_is;
		self iPrintLn( msg_info );
	}
}


VIPloadModel()
{
	// salva classe original
	game["original_class"] = self.pers["class"];

	if ( level.CommanderVIP == 1 )
	{
		self.pers["class"] = "CLASS_VIP";
		self.class = "CLASS_VIP";
		self.pers["primary"] = 0;
		self.pers["weapon"] = undefined;

			self maps\mp\gametypes\_class::setClass( self.pers["class"] );
			self.tag_stowed_back = undefined;
			self.tag_stowed_hip = undefined;
			self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
	}
	else
	{
		self.pers["class"] = "CLASS_COMMANDER";
		self.class = "CLASS_COMMANDER";
		self.pers["primary"] = 0;
		self.pers["weapon"] = undefined;

			self maps\mp\gametypes\_class::setClass( self.pers["class"] );
			self.tag_stowed_back = undefined;
			self.tag_stowed_hip = undefined;
			self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
	}	

}

VIPloadModelBACK()
{
	// volta sempre pra assault caso não ache sua anterior
	if (isDefined ( game["original_class_atual"] ) )
	{
		self.pers["class"] = game["original_class_atual"];
		self.class = game["original_class_atual"];
	}
	else
	{
		self.pers["class"] = "CLASS_ASSAULT";
		self.class = "CLASS_ASSAULT";
	}
		
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
}

// nao está sendo usada
VIPSearchDestroy()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( isDefined( player.pers["class"] ) && ( player.pers["class"] == "CLASS_COMMANDER" || player.pers["class"] == "CLASS_VIP") )
		{
			wait 3;

			// volta sempre pra assault		
	
			player.pers["class"] = "CLASS_ASSAULT";
			player.class = "CLASS_ASSAULT";
			player.pers["primary"] = 0;
			player.pers["weapon"] = undefined;

			player maps\mp\gametypes\_class::setClass( player.pers["class"] );
			player.tag_stowed_back = undefined;
			player.tag_stowed_hip = undefined;
			player maps\mp\gametypes\_class::giveLoadout( player.pers["team"], player.pers["class"] );
			
			return;
		}
	}
}

onPlayerDisconnect()
{
	self vipDead();
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self vipDead();
}

vipDead()
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		level.endtext = "";
		
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["attackers"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["defenders"] );

		game["VIPname"] = "";

		level.endtext = level.msg_score;

		// deixa de ser vip/commander
		self.isCommander = false;

		// diz q nao tem mais vip/Commander vivo
		level.LiveVIP = false;

		level notify("vip_is_dead");
		
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		
		iPrintLn( level.msg_dead );
		makeDvarServerInfo( "ui_text_endreason", level.msg_dead );
		setDvar( "ui_text_endreason", level.msg_dead );
		
		wait 3;
		setGameEndTime( 0 );		

		CMD_EndGame( game["attackers"], level.endtext );
	}
}

createVipIcon()
{
	if ( level.CommanderVIP == 1 )
	{
		if( game["defenders"] == "allies" )
		{
			self.carryIcon = createIcon( level.hudvip_allies, 35, 35 );
			level.status_icon = level.hudvip_allies;
		}
		else
		{
			self.carryIcon = createIcon( level.hudvip_axis, 35, 35 );
			level.status_icon = level.hudvip_axis;
		}		
	}
	else
	{
		if( game["defenders"] == "allies" )
		{
			self.carryIcon = createIcon( level.hudcommander_allies, 50, 50 );
			level.status_icon = level.hudcommander_allies;
		}
		else
		{
			self.carryIcon = createIcon( level.hudcommander_axis, 50, 50 );
			level.status_icon = level.hudcommander_axis;
		}				
	}		

	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
}

onDeadEvent( team )
{
	if ( level.LiveVIP == false ) // VIP morto!
		return;
		
	wait 1;
		
	if ( team == "allies" )
	{

		level.overrideTeamScore = true;
		level.displayRoundEndText = true;		
	
		iPrintLn( game["strings"]["allies_eliminated"] );
		makeDvarServerInfo( "ui_text_endreason", game["strings"]["allies_eliminated"] );
		setDvar( "ui_text_endreason", game["strings"]["allies_eliminated"] );

		logString( "team eliminated, win: opfor, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
		
		CMD_EndGame( "axis", game["strings"]["allies_eliminated"]);
	}
	else if ( team == "axis" )
	{
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;		
	
		iPrintLn( game["strings"]["axis_eliminated"] );
		makeDvarServerInfo( "ui_text_endreason", game["strings"]["axis_eliminated"] );
		setDvar( "ui_text_endreason", game["strings"]["axis_eliminated"] );

		logString( "team eliminated, win: allies, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

		CMD_EndGame( "allies", game["strings"]["axis_eliminated"]);
	}
	else
	{
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;		
	
		makeDvarServerInfo( "ui_text_endreason", game["strings"]["tie"] );
		setDvar( "ui_text_endreason", game["strings"]["tie"] );

		logString( "tie, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
		
		if ( level.teamBased )
			CMD_EndGame( "tie", game["strings"]["tie"] );
		else
			CMD_EndGame( undefined, game["strings"]["tie"] );
	}
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
	
	CMD_EndGame( winner, game["strings"]["time_limit_reached"] );
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

CMD_EndGame( winningTeam, endReasonText )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	maps\mp\gametypes\_globallogic::proxVIP( game["defenders"] );
	
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
		
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );		
}

SetaMensagens()
{
	// locais
	
	if ( getDvar( "scr_commander_msg_vip" ) == "" )
	{
		msg_vip =  "VIP";
	}
	else
	{
		msg_vip = getDvar( "scr_commander_msg_vip" );
	}	
	
	if ( getDvar( "scr_commander_msg_com" ) == "" )
	{
		msg_com =  "Commander";
	}
	else
	{
		msg_com = getDvar( "scr_commander_msg_com" );
	}	

	
	if ( getDvar( "scr_commander_msg_you" ) == "" )
	{
		msg_you =  "You are the";
	}
	else
	{
		msg_you = getDvar( "scr_commander_msg_you" );
	}
	
	if ( getDvar( "scr_commander_msg_protect" ) == "" )
	{
		msg_protect =  "Protect the";
	}
	else
	{
		msg_protect = getDvar( "scr_commander_msg_protect" );
	}	
	
	if ( getDvar( "scr_commander_msg_kill" ) == "" )
	{
		msg_kill =  "Kill the";
	}
	else
	{
		msg_kill = getDvar( "scr_commander_msg_kill" );
	}	

	if ( getDvar( "scr_commander_msg_is" ) == "" )
	{
		msg_is =  "is the";
	}
	else
	{
		msg_is = getDvar( "scr_commander_msg_is" );
	}
	
	if ( getDvar( "scr_commander_msg_dead" ) == "" )
	{
		msg_dead =  "is Dead!";
	}
	else
	{
		msg_dead = getDvar( "scr_commander_msg_dead" );
	}		
	
	if ( getDvar( "scr_commander_msg_the" ) == "" )
	{
		msg_the =  "The";
	}
	else
	{
		msg_the = getDvar( "scr_commander_msg_the" );
	}	

	// finais
	if ( level.CommanderVIP == 1 )
	{
		// "^7You are the ^9VIP^7!"
		// "^7Protect the ^9VIP^7!"
		// "^7Kill the ^9VIP^7!"
		// "^9" + level.ShowName + "^7 is the ^9VIP^7!"
		// "^7The ^3VIP ^7is Dead!"
		// "^7The ^9VIP^7 is Dead!"
	
		level.msg_you = msg_you + " ^9" + msg_vip + "^7!";
		level.msg_protect = msg_protect + " ^9" + msg_vip + "^7!";
		level.msg_kill = msg_kill + " ^9" + msg_vip + "^7!";
		level.msg_is = "^7 " + msg_is + " ^9" + msg_vip + "^7!";
		level.msg_score = msg_the + " ^3" + msg_vip + " ^7" + msg_dead;
		level.msg_dead = msg_the + " ^9" + msg_vip + " ^7" + msg_dead;
	}
	else
	{
		level.msg_you = msg_you + " ^9" + msg_com + "^7!";
		level.msg_protect = msg_protect + " ^9" + msg_com + "^7!";
		level.msg_kill = msg_kill + " ^9" + msg_com + "^7!";
		level.msg_is = "^7 " + msg_is + " ^9" + msg_com + "^7!";
		level.msg_score = msg_the + " ^3" + msg_com + " ^7" + msg_dead;
		level.msg_dead = msg_the + " ^9" + msg_com + " ^7" + msg_dead;	
	}
}