#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	level.LivePILOT = false;
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "pilot", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "pilot", 5, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "pilot", 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "pilot", 6, 0, 30 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "pilot", 0, 0, 100 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( "pilot", 0, 0, 3 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "pilot", 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerNextVIPDvar( "pilot", 2, 0, 2 );
	maps\mp\gametypes\_globallogic::registerVIPNameDvar( "scr_pilot_name", 1, 0, 1 );
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	level.endGameOnScoreLimit = false;
	
	// controlar morte vip/commandante
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;		
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "goodtogo";
	//game["dialog"]["defense_obj"] = "goodtogo";
}

onPrecacheGameType()
{
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";

	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		precacheStatusIcon( "pilot_aircraft" );
		precacheShader("pilot_aircraft");
	}
	else
	{
		precacheStatusIcon( "pilot_tank" );
		precacheShader("pilot_tank");
	}
	
	precacheModel( "body_complete_mp_zack_woodland" );
	//precacheModel( "body_complete_mp_zack_desert" );
	
	precacheShader("compass_waypoint_target");
	precacheShader("waypoint_target");
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "waypoint_escort" );	
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
			game["switchedsides"] = !game["switchedsides"];
		else
			level.halftimeSubCaption = "";

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

onStartGameType()
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	level.PILOTescaped = 0;

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
	
	setClientNameMode( "manual_change" );
		
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_PILOT_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_PILOT_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_PILOT_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_PILOT_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_PILOT_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_PILOT_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_PILOT_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_PILOT_DEFENDER" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );

	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	novos_sd_init();
	
	if ( level.novos_objs )
	{
		thread bombs();
	}
	else
		thread bombsRELOAD();
	
	SetaMensagens();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}


onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;

	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();	

	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";
	
	// deleta skin do vip/commander se sobrou do round anterior
	if ( isdefined(self.pers["class"])&& ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP") )
		VIPloadModelBACK();

	if ( level.LivePILOT == false && self.pers["team"] == game["attackers"])
	{
		SpawnPILOT();
	}
	else
		SpawnSoldado();

	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( self.isCommander == true )
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
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints_player( self );
}

SpawnPILOT()
{
	self.isCommander = true;
	
	self iPrintLnbold( "^7You are the ^9Pilot^7!" );
	
	self thread createVipIcon();

	// troca a skin pra VIP/Commander
	VIPloadModel(); 	
	
	// diz q o mapa já tem um vip/commander vivo
	level.LivePILOT = true;	
	
	// icone defend!
	//self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	
	// seta nome do Commander para mostrar na tela
	level.ShowName = self.name;	

	// safe?
	thread PlayerSafe();
	
	thread NovaArma();
	
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
	
	if( isDefined(player.bIsBot) && player.bIsBot) 
	{
		wait 0.5;
		player TakeAllWeapons();
		player.weaponPrefix = "colt45_mp";
		player.pers["weapon"] = "colt45_mp";
	}			
}

SpawnDocs( trigger, visuals )
{
	pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,100) );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_escort" );
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

NovaArma()
{
	wait 1;
	self takeAllWeapons();
	self giveWeapon( "colt45_mp" );
	self giveMaxAmmo( "colt45_mp" );
	self switchToWeapon( "colt45_mp" );	
}

SpawnSoldado()
{
	self.isCommander = false;

	if ( self.pers["team"] == game["attackers"])
	{
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.escort_msg );

		if ( level.VIPName == 1 )
			thread ShowVipName();
	}
	else
	{
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.escort_dlt );
	}
}

PlayerSafe()
{
	self.Safe = false;
	
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.pos_zulu_A) < 100 || distance(self.origin,level.pos_zulu_B) < 100 )
			{
				if ( self.isCommander == true )
				{
					self.Safe = true;
					maps\mp\gametypes\_globallogic::givePlayerScore( "safe", self );
					// pontos extras por ser o VIP
					maps\mp\gametypes\_globallogic::givePlayerScore( "safe", self );
					
					thread printAndSoundOnEveryone( game["attackers"], game["defenders"], level.escaped_msg, level.escaped_msg, "plr_new_rank", "mp_obj_taken", "" );	
					
					level.PILOTescaped++;				
					
					if ( level.starstreak > 0 )
						self.fl_stars_pts = self.fl_stars_pts + 3;
					thread EscapeUpdateScore( self.team );
					self RespawnSafe();					
				}
			} 
		}
		wait 1;
	}
}

RespawnSafe()
{
	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";

	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		self disableWeapons();
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
		maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, true );
	}
	else
	{
		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
		self setorigin(spawnpoint.origin);
		self setplayerangles(spawnpoint.angles);	
	}
	self.Safe = false;
	self.lastSpawnTime = getTime(); // zera tempo
}

EscapeUpdateScore ( team )
{
	[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + 1 );
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
		msg_info = "^9" + level.ShowName + "^7 " + level.isvip;
		self iPrintLn( msg_info );
	}
}

VIPloadModel()
{
	// salva classe original
	self.class_original = self.pers["class"];

	self.pers["class"] = "CLASS_VIP";
	self.class = "CLASS_VIP";
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );

	thread Pilot();
}

Pilot()
{
	wait 0.1;
	self detachAll();
	self setModel( "body_complete_mp_zack_woodland" );
	
	//self setModel( "body_complete_mp_zack_desert" );

}

VIPloadModelBACK()
{
	// volta sempre pra assault caso não ache sua anterior
	if (isDefined ( self.class_original ) )
	{
		self.pers["class"] = self.class_original;
		self.class = self.class_original;
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

createVipIcon()
{
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		self.carryIcon = createIcon( "pilot_aircraft", 35, 35 );
		self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
		self.carryIcon.alpha = 0.75;
		
		// carrega icon no placar
		self.statusicon = "pilot_aircraft";
	}
	else
	{
		self.carryIcon = createIcon( "pilot_tank", 35, 35 );
		self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
		self.carryIcon.alpha = 0.75;
		
		// carrega icon no placar
		self.statusicon = "pilot_tank";
	}
}

onPlayerDisconnect()
{
	self vipDead();
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self vipDead(attacker);
}

vipDead(attacker)
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		if( isDefined(attacker) && isPlayer( attacker ) && self != attacker && attacker.team != self.team ) 
		{
			attacker.fl_stars_pts = attacker.fl_stars_pts + 2;
		}
	
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["defenders"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["attackers"] );

		// deixa de ser vip/commander
		self.isCommander = false;

		// diz q nao tem mais vip/Commander vivo
		level.LivePILOT = false;
	}
	else
	{
		//iPrintLn( "nao eh o alvo..." );
		return;
	}
}


sd_endGame( winningTeam, endReasonText )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();	
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	if ( team == "all" )
	{
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}

onOneLeftEvent( team )
{
	warnLastPlayer( team );
}


onTimeLimit()
{
	// da vitoria aos defenders em caso de empate
	winner = game["defenders"];
		
	if ( getDvarInt ( "war_server" ) == 1 && getDvarInt ( "ws_start" ) == 2 ) // se durante WAR pontuar defesa!
	{
		if ( level.PILOTescaped < 3 )
		{
			[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) + getDvarInt ( "ws_real" ) );	
		}
		else
		{
			winner = game["attackers"];
		}
	}
	else // não é WAR
	{
		if ( level.PILOTescaped > 0 )
			winner = game["attackers"];
	}

	logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

	// i think these two lines are obsolete
	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );

	sd_endGame( winner, game["strings"]["time_limit_reached"] );
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
		self maps\mp\gametypes\_globallogic::HajasDuel();
	}	
}

bombs()
{
	level.ZuluSafe = false;
	level.ZuluChopper = false;
	level.ZuluRevealed = false;
	
	novos_sd();

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	// salva trigger da maleta pra achar bomba correta
	maleta = trigger;

	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}

	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{	
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );    
			
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );
		
		// zulu point
		if ( index == 0 )
			level.pos_zulu_A = trigger.origin;
		else
			level.pos_zulu_B = trigger.origin;
		thread ZuluSmoke( trigger.origin, bombZone );
						
		// deleta visual
		for ( i = 0; i < visuals.size; i++ )
		{
			visuals[i] delete();
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
	}	
	
	// deleta clips longe do trigger
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{
			clips[i] delete();
		}
	}
}

bombsRELOAD()
{
	level.ZuluSafe = false;
	level.ZuluChopper = false;
	level.ZuluRevealed = false;
	
	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	// salva trigger da maleta pra achar bomba correta
	maleta = trigger;

	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}

	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{	
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );    
			
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );
		
		// zulu point
		if ( index == 0 )
			level.pos_zulu_A = trigger.origin;
		else
			level.pos_zulu_B = trigger.origin;
		thread ZuluSmoke( trigger.origin, bombZone );
						
		// deleta visual
		for ( i = 0; i < visuals.size; i++ )
		{
			visuals[i] delete();
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
	}	

	// deleta clips 
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{
			clips[i] delete();
		}
	}
}

playSoundinSpace( alias, origin )
{
	level endon( "game_ended" );

	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 6; // MP doesn't have "sounddone" notifies =(
	org delete();
}

ZuluSmoke( origin, zone ) 
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	zulutime = randomIntRange( 20, 60 );
	wait zulutime;

	zone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
	zone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" );
		
	thread playSoundinSpace( "smokegrenade_explode_default", origin );

	rot = randomfloat(360);
	zulupoint = spawnFx( level.zulu_point_smoke, origin, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( zulupoint );
	
	level.ZuluRevealed = true;

	thread ZuluRevealed();
}

ZuluRevealed()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["attackers"] )
		{
			player iPrintLn( level.escape_extpoint );
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
}

SetaMensagens()
{

	if ( getDvar( "scr_pilot_mark" ) == "" )
	{
		level.escape_extpoint =  "^1Warning ^0: ^7Extraction Point Marked!";
	}
	else
	{
		level.escape_extpoint = getDvar( "scr_pilot_mark" );
	}
	
	if ( getDvar( "scr_pilot_defend" ) == "" )
	{
		level.escort_dlt =  "^7Don't let the ^9Pilot ^7Escape!";
	}
	else
	{
		level.escort_dlt = getDvar( "scr_pilot_defend" );
	}
	
	if ( getDvar( "scr_pilot_attack" ) == "" )
	{
		level.escort_msg =  "^7Escort the ^9Pilot^7!";
	}
	else
	{
		level.escort_msg = getDvar( "scr_pilot_attack" );
	}			

	if ( getDvar( "scr_pilot_escaped" ) == "" )
	{
		level.escaped_msg =  "^7The ^9Pilot^7 escaped!";
	}
	else
	{
		level.escaped_msg = getDvar( "scr_pilot_escaped" );
	}	
	
	if ( getDvar( "scr_pilot_is" ) == "" )
	{
		level.isvip =  "is the ^9Pilot^7!";
	}
	else
	{
		level.isvip = getDvar( "scr_pilot_is" );
	}	

}

// ============ RANDOM =======================

novos_sd_init()
{
	level.novos_objs = true;
	temp = GetDvar ( "xsd_" + 0 );
	if ( temp == "" )
	{
		level.novos_objs = false;	
		return;
	}
		
	xsd(); // cria listas com pos
}

xsd()
{
	level.xsd_a = [];
	level.xsd_b = [];

	destroyed_models = getentarray("exploder", "targetname");
	trig_plant = getentarray("bombzone", "targetname");
	trig_plant_a = undefined;
	trig_plant_b = undefined;
	
	for(i=0 ; i<trig_plant.size ; i++)
	{
		if( trig_plant[i].script_label == "_a" )
			trig_plant_a = trig_plant[i];
		else if( trig_plant[i].script_label == "_b" )
			trig_plant_b = trig_plant[i];
	}

	level.xsd_a[0] = trig_plant_a.origin + (0, 0, 50);
	level.xsd_b[0] = trig_plant_b.origin + (0, 0, 50);

	gerando = true;
	index = 0;

	while (gerando)
	{
		temp = GetDvar ( "xsd_" + index );
		if ( temp == "eof" )
			gerando = false;
		else
		{
			temp = strtok( temp, "," );
			pos = (int(temp[0]),int(temp[1]),int(temp[2]));
			
			if ( distance( pos, level.xsd_a[0]) < distance( pos, level.xsd_b[0]) )
				level.xsd_a[level.xsd_a.size] = pos;
			else
				level.xsd_b[level.xsd_b.size] = pos;
				
		}	
		index++;
	}
}

novos_sd()
{
	if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
	{
		id_a = RandomInt(level.xsd_a.size);
		while ( ObjValido(level.xsd_a[id_a]) == false )
		{
			id_a = RandomInt(level.xsd_a.size);
			logprint( "======================== Não Válido A!!! " + "\n");
		}
		exesd( level.xsd_a[id_a], 1 );	
		
		id_b = RandomInt(level.xsd_b.size);
		while ( ObjValido(level.xsd_b[id_b]) == false )
		{
			id_b = RandomInt(level.xsd_b.size);
			logprint( "======================== Não Válido B!!! " + "\n");
		}
		exesd( level.xsd_b[id_b], 2 );		
	}
	else
	{
		exesd( level.xsd_a[RandomInt(level.xsd_a.size)], 1 );
		exesd( level.xsd_b[RandomInt(level.xsd_b.size)], 2 );
	}
}

exesd( pos, bomb )
{
	angles = (0,0,0);
	
	destroyed_models = getentarray("exploder", "targetname");
	trig_plant = getentarray("bombzone", "targetname");
	trig_plant_a = undefined;
	trig_plant_b = undefined;
	
	for(i=0 ; i<trig_plant.size ; i++)
	{
		if( trig_plant[i].script_label == "_a" )
			trig_plant_a = trig_plant[i];
		else if( trig_plant[i].script_label == "_b" )
			trig_plant_b = trig_plant[i];
	}

	a_destroyed_model = undefined;
	b_destroyed_model = undefined;
	
	if (IsDefined(destroyed_models))
	{
		for( i=0 ; i<destroyed_models.size ; i++ )
		{
			if( distance( destroyed_models[i].origin , trig_plant_a.origin ) <= 100 )
				a_destroyed_model = destroyed_models[i];
			
			if( distance( destroyed_models[i].origin , trig_plant_b.origin ) <= 100 )
				b_destroyed_model = destroyed_models[i];
		}
	}
	
//--------------------------------

	clips = getentarray( "script_brushmodel","classname" );
	obja_clip = undefined;
	objb_clip = undefined;
	
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{	
			if( clips[i].script_gameobjectname == "bombzone" )
			{
				if( distance( clips[i].origin , trig_plant_a.origin ) <= 100 )
					obja_clip = clips[i];
				
				if( distance( clips[i].origin , trig_plant_b.origin ) <= 100 )
					objb_clip = clips[i];
			}
		}
	}
	
//--------------------------------
	
	if ( bomb == 1 )
	{
		obj_a_origin = pos + (0, 0, -60);
		//obj_a_angles = trig_plant_a.angles;
		
		trig_plant_a.origin = obj_a_origin;
		
		if (IsDefined(a_destroyed_model))
			a_destroyed_model.origin = obj_a_origin;
		//a_destroyed_model.angles = obj_a_angles;
		
		a_obj_entire = getent( trig_plant_a.target, "targetname" );
		a_obj_entire.origin = obj_a_origin;
		//a_obj_entire.angles = obj_a_angles;
		
		obja_clip.origin = obj_a_origin + (0, 0, 30);
		//obja_clip rotateto( obj_a_angles, 0.1 );
	}
	else
	{
		obj_b_origin = pos + (0, 0, -60);
		//obj_b_angles = trig_plant_b.angles;
		
		trig_plant_b.origin = obj_b_origin;
		
		if (IsDefined(b_destroyed_model))
			b_destroyed_model.origin = obj_b_origin;
		//b_destroyed_model.angles = obj_b_angles;
		
		b_obj_entire = getent( trig_plant_b.target, "targetname" );
		b_obj_entire.origin = obj_b_origin;
		//b_obj_entire.angles = obj_b_angles;
		
		objb_clip.origin = obj_b_origin + (0, 0, 30);
		//objb_clip rotateto( obj_b_angles, 0.1 );
	}
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