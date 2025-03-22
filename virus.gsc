#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	level.tem_koth = true;

	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "virus", 1, 1, 1 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "virus", 30, 0, 100 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "virus", 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "virus", 2, 1, 2 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "virus", 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "virus", 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( "virus", 0, 0, 1 );
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	
	// controlar morte Commander
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "capture_objs";
	game["dialog"]["defense_obj"] = "objs_defend";
	
	// se não definido controle, cria como false
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	
	if( game["roundsplayed"] == 0 )
	{
		SetDvar( "mission_time_A", 0 );
		SetDvar( "mission_time_B", 0 );
		
		SetDvar( "mission_time_A_full", 0 );
		SetDvar( "scr_virus_timelimit_original", getDvarFloat("scr_virus_timelimit") );
	}
}


onPrecacheGameType()
{
	// airborne
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::init();
	else
		game["nuke_alarm"] = "nuke_alarm";
	
	// nuke
	game["nuke_01"] = "nuke";
	game["nuke_02"] = "nuke_impact";
	game["nuke_incoming"] = "nuke_incoming";
	game["hack_alarm"] = "hack_alarm";
	
	game["alarm_red"] = "alarm_missile_incoming";
	game["alarm_blue"] = "alarm_altitude";	
	precacheShader("ac130_overlay_25mm");
	
	precacheStatusIcon( "death_helicopter" );	
	
	precacheStatusIcon( "specialty_longersprint" );

	// Commander Sounds
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";
	
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";
	
	precacheModel( "prop_suitcase_bomb" );	
	precacheShader("hud_suitcase_bomb");
	precacheStatusIcon( "hud_suitcase_bomb" );	

	precacheShader( "waypoint_targetneutral" );
	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "waypoint_kill" );
	
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "compass_waypoint_target" );

	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );	
}

IniciaVirus()
{
	level.virus_heroi = undefined;
	level.RPGLiberada = false;
	level.PriPegada = true;
	level.JahResetou = false;
	
	level.virus_samples = 0;
	level.labcomputerID = "";
	
	level.ZuluRevealed = false;
	level.ZuluRevealedStartou = false;
	
	level.LastOrigin = undefined;
	
	level.mission_state = "zero";
	
	// "zero"
	// "virus1"
	// "virus2"
	// "virus3"
	// "wait_heli"
	// "heli"
	// "retreat"	
}

onStartGameType()
{
	// inicia clock pra salvar tempo exato
	level.CompleteClock = 0;
	
	IniciaVirus();

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

	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_VIRUS_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_VIRUS_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_VIRUS_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_VIRUS_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_VIRUS_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_VIRUS_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// inicia com landing zone da defesa!
	level.landing_zone_secured = false;
	
	// posição spawns para marcar spawns da defesa/ataque!
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	
	// define pos Zulu
	level.EscapeZone = level.attack_spawn;
	
	// diz que Zulu ainda não foi marcada
	level.ZuluRevealed = false;
	level.ZuluRevealedStartou = false;
	
	// carrega fumaça
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");	
	
	// calcular spawns chão!
	CalculaSpawnsAtaque();
	CalculaSpawnsDefesa();
	
    // Nuke FX
    level.nuke			= loadfx("explosions/nuke_explosion");
    level.nuke_flash	= loadfx("explosions/nuke_flash");		

	level.nuke_exploded = false;
	level.nuke_started = false;

	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();
	
	allowed = [];
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";	
	allowed[3] = "hq";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	level.iconoffset = (0,0,32);
	
	SetupLab();

	if ( level.tem_koth == false )
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
	
	TerminaisAttack();
	
	AmmoMaleta();
	
	SetaMensagens();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );	
}

// ==================================================================================================================
//   Lab Computers
// ==================================================================================================================

SetupLab()
{
	level.MaxRadios = 3;

	maperrors = [];

	radios = getentarray( "hq_hardpoint", "targetname" );
	
	if ( radios.size < 3 )
	{
		maperrors[maperrors.size] = "There are not at least 3 entities with targetname \"radio\"";
	}
	else
	{
		trigs = getentarray("radiotrigger", "targetname");

		for ( i = 0; i < radios.size; i++ )
		{
			errored = false;
			
			radio = radios[i];
			radio.trig = undefined;
			for ( j = 0; j < trigs.size; j++ )
			{
				if ( radio istouching( trigs[j] ) )
				{
					if ( isdefined( radio.trig ) )
					{
						maperrors[maperrors.size] = "Radio at " + radio.origin + " is touching more than one \"radiotrigger\" trigger";
						errored = true;
						break;
					}
					radio.trig = trigs[j];
					break;
				}
			}
			
			if ( !isdefined( radio.trig ) )
			{
				if ( !errored )
				{
					maperrors[maperrors.size] = "Radio at " + radio.origin + " is not inside any \"radiotrigger\" trigger";
					continue;
				}
			}
			
			assert( !errored );
		}
	}
	
	if (maperrors.size > 0)
	{
		logPrint("^1------------ Map Errors ------------\n");
		for(i = 0; i < maperrors.size; i++)
			logPrint(maperrors[i] + "\n");
		logPrint("^1------------------------------------\n");
		
		level.tem_koth = false;
		
		maps\mp\_utility::error("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );
		
		return;
	}
	
	level.radios = radios;
	
	for ( i = 0; i < level.radios.size; i++ )
	{
		level.radios[i].used = false;
		level.radios[i].on = false;
	}
	
	return true;
}

TerminaisAttack()
{
	level.ActiveRadios = [];

	// define qual é o mais perto	
	level.radio_one = undefined;
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		if ( i == 0 )
			level.radio_one = radio;
			
		if ( i != 0 )
		{
			if ( distance(level.radio_one.origin,level.attack_spawn) > distance(radio.origin,level.attack_spawn) )
				level.radio_one = radio;
		}
	}
	
	// testa se custom map com muitos HQs para tirar o mais perto do escolhido
	if ( level.radios.size > 5 )
	{
		for ( i = 0; i < level.radios.size; i++ )
		{
			radio = level.radios[i];

			if ( i == 0 )
				level.radio_two = radio;
			
			if ( level.radio_one != radio )
			{
				if ( i != 0 )
				{
					if ( distance(level.radio_two.origin,level.radio_one.origin) > distance(radio.origin,level.radio_one.origin) )
						level.radio_two = radio;
				}
			}		
		}	
	}
	
	terminais = 0;
	
	// seta os flags pra cada um deles fazendo eles ficarem visíveis
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		if ( radio != level.radio_one && terminais < 5 )
		{
			if ( isDefined(level.radio_two) && radio == level.radio_two )
				continue;
		
			radio.trigorigin = radio.trig.origin;
			
			visuals = [];
			visuals[0] = radio;
			
			otherVisuals = getEntArray( radio.target, "targetname" );
			for ( j = 0; j < otherVisuals.size; j++ )
			{
				visuals[visuals.size] = otherVisuals[j];
			}		
		
			radio.gameObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], radio.trig, visuals, (radio.origin - radio.trigorigin) + level.iconoffset );
			radio.gameObject maps\mp\gametypes\_gameobjects::disableObject();		
			radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
			radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
			radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
			//radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
			//radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
			radio.trig.useObj = radio.gameObject;
			level.radios[i].on = true;	
			
			level.ActiveRadios[level.ActiveRadios.size] = i;
					
			terminais++;				
		}
	}	

	if ( terminais < 3 )
	{
		logPrint("Not Enough Terminals to Play!" + "\n");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );		
	}
}

MostraTerminais()
{
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		if ( level.radios[i].on == true )
		{
			radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
			radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );		
		}
	}

}


TerminalViolated( origin ) //origin, zone
{
	wait 5;
	
	thread maps\mp\gametypes\_globallogic::HajasPlay3D ( game["hack_alarm"], origin, 7.0 );
	wait 2;
	maps\mp\gametypes\_globallogic::leaderDialog( "move_to_new",  game["defenders"] );
}

TerminalLostIntel()
{
	wait 3;
	maps\mp\gametypes\_globallogic::leaderDialog( "obj_lost",  game["defenders"] );
	wait 2;
	maps\mp\gametypes\_globallogic::leaderDialog( "attack",  game["defenders"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "boost",  game["defenders"] );
}


// ==================================================================================================================
//   Ammo
// ==================================================================================================================

AmmoMaleta()
{
	level.bomb_pos = [];
	
	novos_sd_init();
	if ( level.novos_objs )
		novos_sd();		

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}

	precacheModel( "prop_suitcase_bomb" );	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	level.sdBomb = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,32) );
	
	if ( level.Type == 0 )
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );
	else
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "any" );
	level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_captureneutral" );
	level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_targetneutral" );
	level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
	level.sdBomb maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	level.sdBomb.allowWeapons = true;
	level.sdBomb.onPickup = ::onPickup;
	level.sdBomb.onDrop = ::onDrop;
		
	level.bombZones = [];
	
	level.NotebookOrigin = trigger.origin;
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	for ( index = 0; index < bombZones.size; index++ )
	{
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );
		
		level.bomb_pos[level.bomb_pos.size] = trigger.origin;
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::disableObject();
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_captureneutral" );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_targetneutral" );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		
		for ( i = 0; i < visuals.size; i++ )
		{
			if ( isDefined( visuals[i].script_exploder ) )
			{
				bombZone.exploderIndex = visuals[i].script_exploder;
				break;
			}
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
		
		bombZone.bombDefuseTrig = getent( visuals[0].target, "targetname" );
		assert( isdefined( bombZone.bombDefuseTrig ) );
		bombZone.bombDefuseTrig.origin += (0,0,-10000);
	}
	
	for ( index = 0; index < level.bombZones.size; index++ )
	{
		array = [];
		for ( otherindex = 0; otherindex < level.bombZones.size; otherindex++ )
		{
			if ( otherindex != index )
				array[ array.size ] = level.bombZones[otherindex];
		}
		level.bombZones[index].otherBombZones = array;
	}
}

ControlaRPG()
{
	level endon( "game_ended" );
	
	if ( level.mission_state == "heli" || level.mission_state == "wait_heli" )
		RPGAmmo( true );
	else
		RPGAmmo( false );
}

RPGAmmo( liga )
{
	for ( index = 0; index < level.bombZones.size; index++ )
	{
		if ( liga == true )
		{
			level.bombZones[index] maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			maps\mp\gametypes\_globallogic::leaderDialog( "attack",  game["attackers"] );
			thread IniciaRPG();
		}
		else
			level.bombZones[index] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	}
}

IniciaRPG()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["defenders"] )
			player thread ProcuraRPG();
	}
}

ProcuraRPG()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while( level.mission_state == "heli" || level.mission_state == "wait_heli" )
	{
		for ( i = 0; i < level.bombZones.size; i++ )
		{
			bombzone = level.bomb_pos[i];
			
			if ( distance(self.origin,bombzone) < 100 )
			{
				thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "weap_pickup" );
				if ( self HasWeapon( "rpg_mp" ) )
				{
					self maps\mp\gametypes\_class::setWeaponAmmoOverall( "rpg_mp", 3 );
					self switchToWeapon( "rpg_mp" );
				}
				else
				{
					maps\mp\gametypes\_weapons::HajasMedicdropWeapon( self );
					self giveWeapon( "rpg_mp" );
					self giveMaxAmmo( "rpg_mp" );
					self switchToWeapon( "rpg_mp" );				
				}
				wait 10;
			}
		}
		wait 1;
	}
}

// ==================================================================================================================
//   Maleta
// ==================================================================================================================

onPickup( player )
{
	level notify ( "bomb_picked_up" );
	
	player.statusicon = "hud_suitcase_bomb";
	player.docs = true;
	
	self.autoResetTime = 60.0;
	
	level.useStartSpawns = false;
	
	team = player.pers["team"];
	
	if ( team == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";

	if ( team == game["attackers"] )
	{
		if ( level.mission_state == "virus3" )
		{
			player thread PlayerEscaped();
			if ( level.SidesMSG == 1 )
				player iPrintLnBold( level.mission_escape );
		}
		else
		{
			player thread PlayerHacker();
			if ( level.SidesMSG == 1 && level.PriPegada == false )
				player iPrintLnBold( level.mission_stole );			
		}
	}
	
	level.PriPegada = false;

	player playLocalSound( "mp_suitcase_pickup" );
	player logString( "bomb taken" );

	excludeList[0] = player;
	maps\mp\gametypes\_globallogic::leaderDialog( "obj_defend", team, "bomb", excludeList );

	// recovered the bomb before abandonment timer elapsed
	if ( team == self maps\mp\gametypes\_gameobjects::getOwnerTeam() )
	{
		printOnTeamArg( &"HAJAS_VIRUS_RECOVERED_BY", team, player );
		playSoundOnPlayers( game["bomb_recovered_sound"], team );
	}
	else
	{
		printOnTeamArg( &"HAJAS_VIRUS_RECOVERED_BY", team, player );
		playSoundOnPlayers( game["bomb_recovered_sound"] );
	}
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	
   	// localizador apenas pro ataque
   	if ( team == game["defenders"] )
   	{
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_kill" );   	
   	}
   	else
   	{
   		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
   	}
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );

	if ( team == "allies" )
	{
		if ( team == game["attackers"] )
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "goodtogo", "bomb" );
		else
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "boost", "bomb" );
	}
	else
	{
		if ( team == game["attackers"] )
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "ready_to_move", "bomb" );
		else
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "move_to_new", "bomb" );
	}
	
	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}
}


onDrop( player )
{
	if ( isDefined( player ) )
	{
		printOnTeamArg( &"HAJAS_VIRUS_DROPPED_BY", self maps\mp\gametypes\_gameobjects::getOwnerTeam(), player );
		// remove icon se player perde a bomba
        if ( isAlive( player ) ) 
		{
			player.statusicon = "";
			player.docs = false;
		}			
	}

	playSoundOnPlayers( game["bomb_dropped_sound"], self maps\mp\gametypes\_gameobjects::getOwnerTeam() );
	if ( isDefined( player ) )
		player logString( "bomb dropped" );
	else
		logString( "bomb dropped" );

	playSoundOnPlayers( game["bomb_dropped_sound"], game["attackers"] );

	// quando cai só o ataque pode ver!
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( game["attackers"] );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_captureneutral" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_targetneutral" );
}

NovoReset(nova_origin)
{
	if ( level.mission_state == "heli" )
		nova_origin = level.NotebookOrigin;

	level.sdBomb.trigger.baseOrigin = nova_origin;
	level.sdBomb.visuals[0].baseOrigin = nova_origin;
}

PlayerHacker()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
	
	hacked = false;
	
	while(1)
	{
		if ( TestaHacking( self ) == true )
		{
			hacked = Hacking();
			
			if ( level.gameEnded == true )
				return;
			
			if ( hacked == true )
			{
				level.virus_samples++;
				
				Pontua( 10 );
				
				msg_ata = level.mission_virus1;
				msg_def = level.mission_enemy_stole;
				
				if ( level.virus_samples == 1 )
				{
					level.mission_state = "virus1";
					NovoReset(self.origin);
					thread MostraTerminais();
				}
				else if ( level.virus_samples == 2 )
				{
					msg_ata = level.mission_virus2;
					msg_def = level.mission_enemy_stole_again;
					level.mission_state = "virus2";
					NovoReset(self.origin);
				}
				else if ( level.virus_samples == 3 )
				{
					msg_ata = level.mission_virus3;
					msg_def = level.mission_enemy_gotall;
					level.mission_state = "virus3";
					NovoReset(self.origin);
					level.LastOrigin = self.origin;
					thread TocaAlarme();
					thread ZuluSmoke();
					self thread PlayerEscaped();
					self iPrintLnBold( level.mission_escape );	
				}
				
				LockRadio( level.labcomputerID );
				
				maps\mp\gametypes\_globallogic::givePlayerScore( "plant", self );
				self thread [[level.onXPEvent]]( "plant" );						
				
				for ( i = 0; i < level.players.size; i++ )
				{
					player = level.players[i];
					if ( player.pers["team"] == game["attackers"] )
						player iPrintLn( msg_ata );
					else if ( player.pers["team"] == game["defenders"] )
						player iPrintLn( msg_def );
				}
				wait 1;
				maps\mp\gametypes\_globallogic::leaderDialog( "obj_taken",  game["attackers"] );
				thread TerminalLostIntel(); // avisa a defesa que conseguiram roubar os dados
			}
		}	
		wait 1;
	} 
}

Hacking()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	if ( level.HelpMode == 1 && isDefined(self.lastStand) )		
		return false;
	
	hack_msg = "";
	
	hack_msg = level.virus_hacking;
	if ( TestaHacking( self ) == false )
		return false;
	thread TerminalViolated( self.origin ); //origin, zone

	
	// dropa arma
	self disableWeapons();
	if(isDefined(self.bIsBot) && self.bIsBot)
	{
		//nada
	}
	else
		self thread maps\mp\gametypes\_weapons::MonitoraWeapon();
	
	self.computing = true;
	
	// cria texto
	self.link_msg = newClientHudElem(self);
	self.link_msg.x = 320;
	self.link_msg.alignX = "center";
 	self.link_msg.y = 454;
	self.link_msg.alignY = "bottom";
	self.link_msg.sort = -3;
	self.link_msg setPulseFX( 100, 10000, 1000 );
	self.link_msg.alpha = 1;
	self.link_msg.fontScale = 1.4;
	self.link_msg.hideWhenInMenu = true;
	self.link_msg.archived = true;		
	self.link_msg setText( hack_msg );	
	
	// Background HUD Element (First, because of Z-Ordering)
	self.linkingBG = newClientHudElem(self);
	self.linkingBG.horzAlign = "center";
	self.linkingBG.vertAlign = "bottom";
	self.linkingBG.x = -52;
	self.linkingBG.y = -22;
	self.linkingBG.archived = true;
	self.linkingBG.alpha = 0.75; // Transparent
	self.linkingBG.color = (0.0, 0.0, 0.0); // Black
	self.linkingBG setShader("black", 104, 14); // Set the Shader
	   
	// Initialize the HUD Element
	self.linkingInfo = newClientHudElem(self);
	self.linkingInfo.horzAlign = "center";
	self.linkingInfo.vertAlign = "bottom";
	self.linkingInfo.x = -50;
	self.linkingInfo.y = -20; 
	self.linkingInfo.archived = true;
	self.linkingInfo.alpha = 0.75; // Transparent
	self.linkingInfo.color = (1.0, 1.0, 1.0); // White
	self.linkingInfo setShader("white", 1, 10); // Set the Shader
	
	temp = 1;

	tempo_espera = randomIntRange(10, 20);
	tempo_espera = 1 + tempo_espera;
	
	if ( self.pers["rank"] >= 20 && self.pers["rank"] < 40 )
		tempo_espera--;
	if ( self.pers["rank"] >= 40 && self.pers["rank"] < 60 )
		tempo_espera--;
	if ( self.pers["rank"] >= 60 && self.pers["rank"] < 100 )
		tempo_espera--;
	if ( self.pers["rank"] >= 100 && self.pers["rank"] < 150 )
		tempo_espera--;
	if ( self.pers["rank"] >= 150 )
		tempo_espera--;	
	
	bar_parte = int ( 100 / tempo_espera + 1 );
	bar_inc = 0;

	self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
	
	thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_1" );
	
	wait 1;
	
	while ( temp <= tempo_espera + 1)
	{
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		// atualiza barra
		bar_inc = temp * bar_parte;
		
		// garante q barra não vai estourar
		if ( bar_inc > 100 )
		{
			bar_inc = 100;
		}
		self.linkingInfo setShader("white", bar_inc, 10);	
		
		if ( TestaHacking( self ) == false )
		{
			// se distanciou dos controles
			self iprintln ( level.mission_abort );
			
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
			return false;		
		}
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if ( level.HelpMode == 1 && isDefined(self.lastStand) )
		{
			// ferido
			self iprintln ( level.mission_abort );
			
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
			return false;			
		}
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if(isDefined(self.bIsBot) && self.bIsBot)
		{
		}
		else
		{	
			uav_arma = self getCurrentWeapon();
			if ( uav_arma != "none" )
			{
				// se distanciou dos controles
				self iprintln ( level.mission_abort );
				
				self.linkingBG destroy();
				self.linkingInfo destroy();
				self enableWeapons();
				self.computing = false;
				thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
				return false;		
			}
		}
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if ( level.gameEnded == true )
		{
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			return false;
		}		
		temp++;
		wait 1;
	}
	
	self.linkingBG destroy();
	self.linkingInfo destroy();
	self enableWeapons();
	self.computing = false;
	thread playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	return true;	
}

TestaHacking( player )
{
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		if ( distance(player.origin,radio.origin) < 50 )
		{
			if ( radio.on == false )
			{
				player iPrintLn(level.virus_damaged);
				thread maps\mp\gametypes\_globallogic::HajasPlay3D ( "som_uav_2" , player.origin, 1.0 );
				wait 10;			
			}
			else
			{
				if ( radio.used == false )
				{
					level.labcomputerID = i; // id do radio usado
					return true;
				}
				else if ( radio.used == true )
				{
					player iPrintLn(level.virus_sampled);
					thread maps\mp\gametypes\_globallogic::HajasPlay3D ( "som_uav_2" , player.origin, 1.0 );
					wait 10;
				}
			
			}
		}
	}	
	// se passou por tudo e não retornou, diz que não achou nada, e retorna falso
	return false;
}

LockRadio( id )
{
	level.radios[id].used = true;
	
	for ( i = 0; i < level.ActiveRadios.size; i++ )
	{
		if ( id == level.ActiveRadios[i] )
			level.ActiveRadios = removeArray( level.ActiveRadios, i );
	}
}

UnLockRadios()
{
	for ( i = 0; i < level.MaxRadios; i++ )
	{
		level.radios[i].used = false;
	}
}

// ==================================================================================================================
//   Player
// ==================================================================================================================

CalculaSpawnsDefesa()
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = 3000;

	// pega spawns tdm
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( game["defenders"] );
	assert( spawnPoints.size );	
	
	// loop control
	tudo_ok = false;	
	
	// spawn_count
	spawn_count = 0;	
	
	if ( level.script == "mp_beltot_2" )
	{
		spawnPoints = getEntArray( "mp_sd_spawn_defender", "classname" );
		assert( spawnPoints.size );
		
		for (i = 0; i < spawnpoints.size; i++)
		{
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
		}	
		return;			
	}		
	
	// calcula distancia ideal pra cada mapa
	while( tudo_ok == false )
	{
		if ( spawnpoints.size < 3 )
		{
			logPrint( "Warning! spawnPoints Extras with low Size = " + spawnPoints.size + "\n");
			tudo_ok = true;
		}
			
		for (i = 0; i < spawnpoints.size; i++)
		{
			dist = distance(level.defender_spawn, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
				spawn_count++;
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 500;
			spawn_count = 0;
		}
		else
			tudo_ok = true;
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(level.defender_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
	}	
}

CalculaSpawnsAtaque()
{
	// inicia spaws da defesa
	level.AtaqueSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = 2000;

	// pega spawns tdm
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( game["attackers"] );
	assert( spawnPoints.size );	
	
	// loop control
	tudo_ok = false;	
	
	// spawn_count
	spawn_count = 0;	
	
	if ( level.script == "mp_beltot_2" )
	{
		spawnPoints = getEntArray( "mp_sd_spawn_attacker", "classname" );
		assert( spawnPoints.size );
		
		for (i = 0; i < spawnpoints.size; i++)
		{
			level.AtaqueSpawns[level.AtaqueSpawns.size] = spawnpoints[i];
		}	
		return;			
	}	
	
	// calcula distancia ideal pra cada mapa
	while( tudo_ok == false )
	{
		if ( spawnpoints.size < 3 )
		{
			logPrint( "Warning! spawnPoints Extras with low Size = " + spawnPoints.size + "\n");
			tudo_ok = true;
		}
			
		for (i = 0; i < spawnpoints.size; i++)
		{
			dist = distance(level.attack_spawn, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
				spawn_count++;
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 500;
			spawn_count = 0;
		}
		else
			tudo_ok = true;
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(level.attack_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
		{
			level.AtaqueSpawns[level.AtaqueSpawns.size] = spawnpoints[i];
		}
	}	
}

onSpawnPlayer()
{
	// garante q nao é mais gunner (invisível e imortal)
	self.gunner = false;
	self show();

	// se tem maleta com os virus
	self.docs = false;
	
	// mata hud bomba
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();	
		
	if( isDefined( self.mira_overlay ) )
		self.mira_overlay destroy();			
		
	// mata statusicon
	self.statusicon = "";
	
	if ( level.inGracePeriod )
		MissionSpawnStart();
	else
		MissionSpawnMeio();
}
	
MissionSpawnStart()
{
	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";
		
	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );

	self spawn( spawnpoint.origin, spawnpoint.angles );

	level notify ( "spawned_player" );

	// remove hardpoints
	HajasRemoveHardpoints_player( self );			
	
	MsgPlayer( self );
}

MissionSpawnMeio()
{
	if(self.pers["team"] == game["defenders"])
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
		self spawn( spawnpoint.origin, spawnpoint.angles );
		self thread ProcuraRPG();
	}
	else
	{
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			assert( spawnPoints.size );
			
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		}
		else
		{
			// chão!
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.AtaqueSpawns );

			self spawn( spawnpoint.origin, spawnpoint.angles );
			
			if ( getDvarInt ( "frontlines_abmode" ) == 1 )
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
		}

		// se já ordenou retreat testa se se salvou
		if ( level.mission_state == "retreat" )	
			self thread	PlayerRetreat();
	}
	level notify ( "spawned_player" );	
	
	MsgPlayer( self );
}

onPlayerDisconnect()
{
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if( isDefined( self.mira_overlay ) )
		self.mira_overlay destroy();	
		
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();		
		
	if(isDefined(self.overheat_bg)) self.overheat_bg destroy();
	if(isDefined(self.overheat_status)) self.overheat_status destroy();		
}


// ==================================================================================================================
//   Escape Zone - Zulu
// ==================================================================================================================

ZuluSmoke() 
{
	// se já foi revelada aborta!
	if ( level.ZuluRevealedStartou == true )
		return;
		
	level.ZuluRevealedStartou = true;

	wait 2;
	
	level.ZuluRevealed = true;
	
	level.zulu_mark = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", level.EscapeZone + (0,0,70), game["attackers"], "waypoint_targetneutral" );
	level.zulu_mark setWayPoint( true, "waypoint_targetneutral" );	

	thread playSoundinSpace( "smokegrenade_explode_default", level.EscapeZone );

	rot = randomfloat(360);
	level.zulupoint = spawnFx( level.zulu_point_smoke, level.EscapeZone, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( level.zulupoint );

	thread ZuluRevealed();
}

ZuluDelete()
{
	level.zulu_mark setWayPoint( false );
	level.zulupoint delete();
}

ZuluRevealed()
{
	if ( level.SidesMSG == 1 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( isDefined(player) )
			{
				if ( player.pers["team"] == game["attackers"] && !player.docs )
					player iPrintLn( level.mission_retreat );
			}
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
}

PlayerEscaped()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.EscapeZone) < 100 )
			{
				level.virus_heroi = self;
				level.mission_state = "wait_heli";
				thread ControlaRPG();
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 50 );
				if ( level.starstreak > 0 )
					self.fl_stars_pts = self.fl_stars_pts + 3;
				Pontua( 10 );
				thread maps\mp\gametypes\_hardpoints::VirusHeli( game["attackers"], self );
				self thread VaiProHeli();
				return;
			} 
		}
		wait 1;
	}
}

PlayerRetreat()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.EscapeZone) < 100 )
			{
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 30 );
				self thread Salvo();
				return;
			} 
		}
		wait 1;
	}
}

// ==================================================================================================================
//  Heli
// ==================================================================================================================

VaiProHeli()
{
	level endon( "game_ended" );
	self endon("death");
	self endon("disconnect");
	
	while ( !isDefined(level.chopper) )
		wait 0.1;
	
	while ( distance(self.origin,level.EscapeZone) > 300 )
	{
		self iPrintLn( level.mission_escape_now );
		wait 1;
	}
	
	level.mission_state = "heli";
	self.statusicon = "death_helicopter";
	
	// cria MG no Heli
	level.HeliGunVirus = spawn ("script_model",(0,0,0));
	if ( self.team == "allies" )
		level.HeliGunVirus.origin = level.chopper.origin + (0,0,-250);
	else
		level.HeliGunVirus.origin = level.chopper.origin + (0,0,-200);
	level.HeliGunVirus.angles = level.chopper.angles;
	level.HeliGunVirus linkto (level.chopper);

	// move e linka soldado na MG
	self setorigin(level.HeliGunVirus.origin);
	self setplayerangles(level.HeliGunVirus.angles);
	self linkto (level.HeliGunVirus);		
		
	self.gunner = true;
	self hide();
	self takeAllWeapons();	

	// arma heli
	self giveWeapon( "mp44_mp" );
	
	if (isDefined(self.bIsBot) && self.bIsBot)
		self.weaponPrefix = "mp44_mp";	
		
	self switchToWeapon( "mp44_mp" );
	self SetActionSlot( 1, "nightvision" );
	
	self thread Gunner();
	thread executaOverlay( "ac130_overlay_25mm");
	thread FazFX();		
}

Gunner()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );	

	self thread GunnerWeapon();
	
	while ( isDefined(self.gunner) && self.gunner )
		wait 0.5;
	
	self OverheatRemoveHUD();
}

GunnerWeapon()
{
	self endon("disconnect");
	self endon("death");

	level.overheat_heatrate = 4;
	level.overheat_coolrate = 6;
	
	self.heat_rate = level.overheat_heatrate / 2;
	self.heat_status = 1;
	self.heat_danger = 80;
	self.heat_max = 114;
	self.cool_rate = level.overheat_coolrate;
	self thread OverheatDrain();
	
	self.heat = false;

	while( isDefined(self.gunner) && self.gunner )
	{
		self thread OverheatShowHUD();

		while(self useButtonPressed()) wait 0.05;

		for(;;)
		{
			wait 0.05;

			// turret overheating
			if(isDefined(self) && self attackButtonPressed())
			{
				if(self.heat_status < self.heat_max)
				{
					self.heat_status = self.heat_status + self.heat_rate;
					if(self.heat_status > self.heat_max) self.heat_status = self.heat_max;
				}

				if(self.heat_status == self.heat_max)
				{
					self thread CyborgHeatAlarm();
					self thread maps\mp\gametypes\_globallogic::ExecClientCommand("-attack; +activate; wait 10; -activate");
				}
			}
			self thread OverheatUpdateHUD();
		}
	}
}

CyborgHeatAlarm()
{
	self endon("disconnect");
	self endon("death");
	
	if ( self.heat == false )
	{
		self.heat = true;
		self playLocalSound(game["cyborg_alarm"]);
		//self iprintlnbold("^1Overheat Warning!");
		wait 10;
		self.heat = false;
	}
}

OverheatDrain()
{
	self endon("disconnect");
	self endon("death");

	frames = getDvarInt("sv_fps");

	for(;;)
	{
		wait 0.05;

		if(self.heat_status > 1)
		{
			difference = self.heat_status - (self.heat_status - self.cool_rate);
			frame_difference = (difference / frames);

			for(i = 0; i < frames; i++)
			{
				self.heat_status -= frame_difference;
				if(self.heat_status < 1)
				{
					self.heat_status = 1;
					break;
				}
				wait 0.05;
			}
		}
	}
}

OverheatUpdateHUD()
{
	self endon("disconnect");
	self endon("death");

	if(isDefined(self.overheat_status) && self.heat_status > 1)
	{
		self.overheat_status scaleovertime( 0.1, 10, int(self.heat_status));
		self.overheat_status.color = OverheatSetColor();
		wait 0.1;
	}
}

OverheatSetColor()
{
	self endon("disconnect");
	self endon("death");

	// define what colors to use
	color_cold = [];
	color_cold[0] = 1.0;
	color_cold[1] = 1.0;
	color_cold[2] = 0.0;
	color_warm = [];
	color_warm[0] = 1.0;
	color_warm[1] = 0.5;
	color_warm[2] = 0.0;
	color_hot = [];
	color_hot[0] = 1.0;
	color_hot[1] = 0.0;
	color_hot[2] = 0.0;

	// default color
	SetValue = [];
	SetValue[0] = color_cold[0];
	SetValue[1] = color_cold[1];
	SetValue[2] = color_cold[2];

	// define where the non blend points are
	cold = 0;
	warm = (self.heat_max / 2);
	hot = self.heat_max;
	value = self.heat_status;

	iPercentage = undefined;
	difference = undefined;
	increment = undefined;

	if( (value > cold) && (value <= warm) )
	{
		iPercentage = int(value * (100 / warm));
		for( colorIndex = 0 ; colorIndex < SetValue.size ; colorIndex++ )
		{
			difference = (color_warm[colorIndex] - color_cold[colorIndex]);
			increment = (difference / 100);
			SetValue[colorIndex] = color_cold[colorIndex] + (increment * iPercentage);
		}
	}
	else if( (value > warm) && (value <= hot) )
	{
		iPercentage = int( (value - warm) * (100 / (hot - warm) ) );
		for( colorIndex = 0 ; colorIndex < SetValue.size ; colorIndex++ )
		{
			difference = (color_hot[colorIndex] - color_warm[colorIndex]);
			increment = (difference / 100);
			SetValue[colorIndex] = color_warm[colorIndex] + (increment * iPercentage);
		}
	}

	return (SetValue[0], SetValue[1], SetValue[2]);
}

OverheatShowHUD()
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(self.overheat_bg))
	{
		self.overheat_bg = newclienthudelem(self);
		self.overheat_bg.alignX = "right";
		self.overheat_bg.alignY = "bottom";
		self.overheat_bg.horzAlign = "right";
		self.overheat_bg.vertAlign = "bottom";
		self.overheat_bg.x = -18;
		self.overheat_bg.y = -170;
		self.overheat_bg.alpha = 0.75; // Transparent
		self.overheat_bg setShader("black", 25, 120);
		self.overheat_bg.sort = 2;
	}

	// status bar
	if(!isDefined(self.overheat_status))
	{
		self.overheat_status = newclienthudelem(self);
		self.overheat_status.alignX = "right";
		self.overheat_status.alignY = "bottom";
		self.overheat_status.horzAlign = "right";
		self.overheat_status.vertAlign = "bottom";
		self.overheat_status.x = -25;
		self.overheat_status.y = -172;
		self.overheat_status setShader("white", 10, int(self.heat_status));
		self.overheat_status.color = OverheatSetColor();
		self.overheat_status.alpha = 1;
		self.overheat_status.sort = 1;
	}
}

OverheatRemoveHUD()
{
	self endon("disconnect");

	if(isDefined(self.overheat_bg)) self.overheat_bg destroy();
	if(isDefined(self.overheat_status)) self.overheat_status destroy();
}


executaOverlay(overlay)
{
	self endon("disconnect");
	self endon("death");
	
	if(!isDefined(self.mira_overlay))
	{
		self.mira_overlay = newClientHudElem( self );
		self.mira_overlay.x = 0;
		self.mira_overlay.y = 0;
		self.mira_overlay.alignX = "center";
		self.mira_overlay.alignY = "middle";
		self.mira_overlay.horzAlign = "center";
		self.mira_overlay.vertAlign = "middle";
		self.mira_overlay.foreground = true;
	}
	self.mira_overlay setshader(overlay, 640, 480);
}

FazFX()
{
	self endon("disconnect");
	self endon("death");

	for(;;)
	{
		self waittill("projectile_impact", weapon, position, radius);
		thread TirosTremor();
		thread TirosFX(position, weapon);
		wait 0.05;
	}
}

TirosTremor()
{
	earthquake( .35, .05, self.origin, 100);
}

TirosFX(center, weapon)
{
	wait 0.1;
	physicsExplosionSphere(center, 200, 200 / 2, 0.5);
}

HeliFudeuTremor()
{
	self endon("disconnect");
	self endon("death");
	
	self thread HeliAlarm();
	
	for(;;)
	{
		if ( self.gunner == false )
			return;
			
		if (isDefined(self.bIsBot) && self.bIsBot)
			return;
						
		earthquake( .75, .05, self.origin, 200);
		wait 0.05;
	}
}

HeliAlarm()
{
	self endon("disconnect");
	self endon("death");
	
	wait 1.5;
	
	self.health = 10;
	
	self freezeControls( true );

	if ( isDefined(self.team) && self.team == "allies" )
		self playLocalSound( game["alarm_blue"] );
	else
		self playLocalSound( game["alarm_red"] );
	
	wait 5;
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		self unlink();
		self.gunner = false;
		self show();
		self takeAllWeapons();
		self giveWeapon( "colt45_mp" );
		self giveMaxAmmo( "colt45_mp" );
		self freezeControls( false );

		if (isDefined(self.bIsBot) && self.bIsBot)
		{
			self.weaponPrefix = "colt45_mp";
			self switchToWeapon( "colt45_mp" );
		}		
		
		if( isDefined( self.mira_overlay ) )
			self.mira_overlay destroy();		
		
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );		
		maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, true );
	}
	else
		self.health = 1;
}

HeliDead( chopper_down )
{
	level.endtext = "";
	
	level notify("chopper_end");
	
	while ( isDefined(level.chopper) )
		wait 0.1;
	
	if ( chopper_down == true )
	{
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		{
			// se airborne - gunner pula de paraquedas com a maleta sem precisar fazer tudo de novo.
			level.mission_state = "virus3"; //volta status pra chamar heli
			thread ControlaRPG();
			level.JahResetou = true;
			level.virus_heroi.statusicon = "hud_suitcase_bomb"; // diz que ele tá com a maleta e não mais no heli
			level.virus_heroi thread PlayerEscaped(); // reinicia teste pra escapar
		}	
		else if ( getDvarInt ( "frontlines_abmode" ) != 1 )
		{
			// derrubaram o Heli - spawn nova maleta e começa tudo de novo!
			//NovoReset(level.virus_heroi);
			//thread UnLockRadios();
			//IniciaVirus();
			//thread ZuluDelete();
			//level.PriPegada = false;

			if ( isDefined( level.virus_heroi.carryIcon ) )
				level.virus_heroi.carryIcon destroyElem();
				
			level.virus_heroi.statusicon = "";
			
			level.mission_state = "virus3"; //volta status pra chamar heli
			thread ControlaRPG();			
			level.JahResetou = true;

			while ( level.sdBomb.trigger.origin != level.LastOrigin )
			{
				wait 0.1;
				NovoReset(level.LastOrigin);
				level.sdBomb maps\mp\gametypes\_gameobjects::returnHome();
			}
		}
	}
	else
	{
		// heli foge com o virus
		Pontua( 10 );
		// ordena retreat + nuke strike
		thread Retreat( level.virus_heroi );
		// poe o heroi em spec
		level.virus_heroi thread Salvo();
	}	
}

KillGunner( player, attacker )
{
	if ( isDefined(attacker) )
		player.HeliAttacker = attacker;

	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		return;
	
	player suicide();
}

// ==================================================================================================================
//   Retreat - Nuke
// ==================================================================================================================

Retreat( player )
{
	level endon ( "game_ended" );
	
	level.mission_state = "retreat";
	thread ControlaRPG();

	for ( index = 0; index < level.players.size; index++ )
	{
		if ( player != level.players[index] )
			level.players[index] notify("force_spawn");
	
		if ( level.players[index].team == game["attackers"] )
		{
			level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( level.mission_retreat, level.mission_hurry, undefined, (1, 0, 0), "mp_last_stand" );
			if ( player != level.players[index] )
			{
				level.players[index] thread	PlayerRetreat();
				MsgPlayer( level.players[index] );
			}
		}
	}

	maps\mp\gametypes\_globallogic::leaderDialog( "mission_success", game["attackers"] );
	maps\mp\gametypes\_globallogic::leaderDialog( "mission_failure", game["defenders"] );
	
	thread TocaAlarme();
		
	thread NukeStrike( player );
}

NukeStrike( player )
{
	level endon ( "game_ended" );
	
	level.CompleteClock = maps\mp\gametypes\_globallogic::getTimePassed();

	level.timeLimitOverride = true;
	level.inOvertime = true;

	espera = randomIntRange ( 40, 60 );
	
	waitTime = 0;
	while ( waitTime < 90 )
	{
		// clock
		waitTime += 1;
		setGameEndTime( getTime() + ((90-waitTime)*1000) );
		wait ( 1.0 );		
		
		// se tempo da bomba, executa bomba!
		if ( espera == waitTime )
			thread maps\mp\gametypes\_hardpoints::Nuke_doArtillery( level.defender_spawn, player, game["attackers"] );
	}	
}

Nuke( tempo )
{
	level endon( "game_ended" );
	
	wait tempo;
	
	level.nuke_started = true;
	
	rot = randomfloat(360);
	
	maps\mp\_utility::playSoundOnPlayers( game["nuke_incoming"] );
	setExpFog(0, 17000, 0.678352, 0.498765, 0.372533, 0.5);
	wait 1.5;
	level.chopperNuke = true;
	maps\mp\_utility::playSoundOnPlayers( game["nuke_01"] );
	maps\mp\_utility::playSoundOnPlayers( game["nuke_02"] );

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( isDefined(player.carryIcon) )
			player.carryIcon.alpha = 0;
	}
	
	thread nuke_earthquake();

	// Nuke FX
	nuke = spawnFx( level.nuke, level.defender_spawn, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( nuke );

	// Flash FX
	flash = spawnFx( level.nuke_flash, level.defender_spawn, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( flash );
		
	// stun
	wait 3;

	// diz q explodiu pra nao dar som de morte do Engineer e pra parar sabotagem		
	level.nuke_exploded = true;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		player shellShock( "concussion_grenade_mp", 10 );
		player.concussionEndTime = getTime() + (10 * 1000);		
	}
	
	// morte
	wait 3;
	thread NukeDestruction(level.defender_spawn, 50000, 500, 400);	
	wait 5;

	level.nuke_started = false;
	
	MissionComplete();
}

NukeDestruction( alvo, radius, max, min )
{
	// origin dos alvos
	alvos = [];

	// players
	players = level.players;
	for (i = 0; i < players.size; i++)
	{
		if (!isalive(players[i]) || players[i].sessionstate != "playing")
			continue;
		
		playerpos = players[i].origin + (0,0,32);
		dist = distance(alvo, playerpos);
		if (dist < radius )
			alvos[alvos.size] = playerpos;
	}
	
	// carros e barris
	destructibles = getentarray("destructible", "targetname");
	for (i = 0; i < destructibles.size; i++)
	{
		entpos = destructibles[i].origin;
		dist = distance(alvo, entpos);
		if (dist < radius)
			alvos[alvos.size] = entpos;
	}

	destructables = getentarray("destructable", "targetname");
	for (i = 0; i < destructables.size; i++)
	{
		entpos = destructables[i].origin;
		dist = distance(alvo, entpos);
		if (dist < radius)
			alvos[alvos.size] = entpos;
	}		
	
	//logPrint("alvos.size = " + alvos.size + "\n");
	
	raio_ant = 0;
	raio = 1000;
	
	while(1)
	{
		for (i = 0; i < alvos.size; i++)
		{
			dist = distance(alvo, alvos[i]);
			
			if ( (dist >= raio_ant) && (dist <= raio) )
				radiusDamage( alvos[i], 512, max, min );
		}	
		
		wait 0.5;
		
		if ( raio == 1000 )
		{
			raio_ant = 0;
			raio = 3000;
		}
		else if ( raio == 3000 )
		{
			raio_ant = 3000;
			raio = 7000;
		}		
		else if ( raio == 7000 )
		{
			raio_ant = 7000;
			raio = 15000;
		}			
		else if ( raio == 15000 )
		{
			raio_ant = 15000;
			raio = 30000;
		}		
		else if ( raio == 30000 )
		{
			raio_ant = 30000;
			raio = 50000;
		}
		else if ( raio == 50000 )
		{
			return;
		}
	}
}

nuke_earthquake()
{
	tempo = 0;
	while ( int(tempo) < 2 )
	{
		earthquake( .08, .05, level.defender_spawn, 80000);
		wait(.05);
		tempo = tempo + 0.1;
	}
	while( level.nuke_started == true )
	{
		earthquake( .5, 1, level.defender_spawn, 80000);
		wait(.05);
		earthquake( .25, .05, level.defender_spawn, 80000);
	}
}

Salvo()
{
	wait 0.5;
	
	if( isDefined( self.mira_overlay ) )
		self.mira_overlay destroy();
		
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();			
		
	[[level.spawnSpectator]]();
	
	Pontua( 1 );
	self allowSpectateTeam( "freelook", true );
	if ( level.starstreak > 0 )
		self.fl_stars_pts = self.fl_stars_pts + 3;
	
	self.statusicon = "specialty_longersprint";
}

free_spec()
{
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		player allowSpectateTeam( "allies", true );
		player allowSpectateTeam( "axis", true );
		player allowSpectateTeam( "freelook", true );
		player allowSpectateTeam( "none", true );
	}
}

// ==================================================================================================================
//   Game Over
// ==================================================================================================================

MissionComplete()
{
	// controle tempo
	if( game["roundsplayed"] == 0 )
	{
		SetDvar( "mission_time_A", Int( level.CompleteClock  / 1000) );
		SetDvar( "mission_time_A_full", ( level.CompleteClock / 1000) );
	}	
	else if( game["roundsplayed"] == 1 )
		SetDvar( "mission_time_B", Int( level.CompleteClock  / 1000) );
	
	setGameEndTime( 0 );
	sd_endGame( game["attackers"], level.mission_succeed + RelogioInt( level.CompleteClock  ) );
}

sd_endGame( winningTeam, endReasonText )
{
	setDvar( "ui_bomb_timer", 0 );
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
		
	if( getDvarInt("mission_time_A") > 0 && getDvarInt("mission_time_B") > 0 )	
	{
		Amin = Int(getDvarInt("mission_time_A")/60); 
		Bmin = Int(getDvarInt("mission_time_B")/60);
	
		if ( getDvarInt("mission_time_A") > getDvarInt("mission_time_B") )
		{
			bonus = 1 + Amin - Bmin;
			[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + bonus );
		}
		else if ( getDvarInt("mission_time_A") < getDvarInt("mission_time_B") )
		{
			bonus = 1 + Bmin - Amin;
			[[level._setTeamScore]]( level.otherTeam[winningTeam], [[level._getTeamScore]]( level.otherTeam[winningTeam] ) + bonus );
		}
	}

	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onTimeLimit()
{
	sd_endGame( game["defenders"], level.mission_failed );
}

onDeadEvent( team )
{
	if ( level.mission_state != "retreat" )
	{		
		if ( team == "all" )
			sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
		else if ( team == game["attackers"] )
			sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
		else if ( team == game["defenders"] )
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
	else
	{
		thread free_spec();
		return;		
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
	
	self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "last_alive" );
	
	self maps\mp\gametypes\_missions::lastManSD();
}

smokeFX( alvo, rot )
{
	alvo = alvo + (0,0,-100);
	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke );
	earthquake( 1, 1.5, alvo, 8000 );
}

// ==================================================================================================================
//   Score
// ==================================================================================================================

Pontua( ponto )
{
	pontua = true;
	if ( level.JahResetou == true )
	{
		if ( level.mission_state == "heli" || level.mission_state == "retreat" )
			pontua = true;
		else
			pontua = false;
	}
	
	if ( pontua == true )
		[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) + ponto );
}

// ==================================================================================================================
//   Sound
// ==================================================================================================================

DizScore( team )
{	
	statusDialog( "obj_taken", team );
	statusDialog( "obj_lost", level.otherTeam[team] );
}

TocaAlarme()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	wait 2;
		
	maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
}

playSoundinSpace( alias, origin )
{
	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 10; // MP doesn't have "sounddone" notifies =(
	org delete();
}

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

// ==================================================================================================================
//   Relogio
// ==================================================================================================================

RelogioInt ( tempo )
{
	tempo = Int(tempo / 1000);
	minutos = int(tempo / 60);
	segundos = tempo - (minutos * 60);
	if ( segundos < 10 )
		segundos = "0" + segundos;

	relogio = minutos + ":" + segundos;
	return relogio;
}

Relogio( tempo )
{
	minutos = int(tempo / 60);
	segundos = tempo - (minutos * 60);
	if ( segundos < 10 )
		segundos = "0" + segundos;

	relogio = minutos + ":" + segundos;
	return relogio;
}

HajasRemoveHardpoints()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if( player HasWeapon( "radar_mp" ) ) 
		{
			player takeWeapon( "radar_mp" );
			player setActionSlot( 4, "" );
			player.pers["hardPointItem"] = undefined;	
		}
		if( player HasWeapon( "airstrike_mp" ) ) 
		{
			player takeWeapon( "airstrike_mp" );
			player setActionSlot( 4, "" );
			player.pers["hardPointItem"] = undefined;	
		}
		if( player HasWeapon( "helicopter_mp" ) ) 
		{
			player takeWeapon( "helicopter_mp" );
			player setActionSlot( 4, "" );
			player.pers["hardPointItem"] = undefined;	
		}									
	}	
}

HajasRemoveHardpoints_player( player )
{
	if( player HasWeapon( "radar_mp" ) ) 
	{
		player takeWeapon( "radar_mp" );
		player setActionSlot( 4, "" );
		player.pers["hardPointItem"] = undefined;	
	}
	if( player HasWeapon( "airstrike_mp" ) ) 
	{
		player takeWeapon( "airstrike_mp" );
		player setActionSlot( 4, "" );
		player.pers["hardPointItem"] = undefined;	
	}
	if( player HasWeapon( "helicopter_mp" ) ) 
	{
		player takeWeapon( "helicopter_mp" );
		player setActionSlot( 4, "" );
		player.pers["hardPointItem"] = undefined;	
	}									
}


// ==================================================================================================================
//   Mensagens
// ==================================================================================================================

MsgPlayer( player )
{
	if ( level.SidesMSG == 1 )
	{
		team = player.team;
		
		if ( level.mission_state == "zero" || level.mission_state == "virus1" || level.mission_state == "virus2" )
		{
			if ( team == game["attackers"] )
				player iPrintLnbold( level.mission_stole );
			else if ( team == game["defenders"] )
				player iPrintLnbold( level.mission_lab );
		}
		else if ( level.mission_state == "virus3" || level.mission_state == "wait_heli" )
		{
			if ( team == game["attackers"] )
				player iPrintLnbold( level.mission_protect );
			else if ( team == game["defenders"] )
				player iPrintLnbold( level.mission_recover );		
		}
		else if ( level.mission_state == "heli" )
		{
			if ( team == game["attackers"] )
				player iPrintLnbold( level.mission_chopper );
			else if ( team == game["defenders"] )
				player iPrintLnbold( level.mission_shoot_chopper );		
		}		
		else if ( level.mission_state == "retreat" )
		{
			if ( team == game["attackers"] )
				player iPrintLnbold( level.mission_retreat );
		}
	}
}

SetaMensagens()
{
	// Attackers
	
	if ( getDvar( "scr_virus_1" ) == "" )
		level.mission_virus1 =  "^7We got the first ^9Virus^7 sample!";
	else
		level.mission_virus1 = getDvar( "scr_virus_1" );
		
	if ( getDvar( "scr_virus_2" ) == "" )
		level.mission_virus2 =  "^7We got another ^9Virus^7 sample!";
	else
		level.mission_virus2 = getDvar( "scr_virus_2" );
		
	if ( getDvar( "scr_virus_3" ) == "" )
		level.mission_virus3 =  "^7We got all the ^9Virus^7 samples!";
	else
		level.mission_virus3 = getDvar( "scr_virus_3" );				

	if ( getDvar( "scr_virus_get" ) == "" )
		level.mission_stole =  "^7Get the ^9Virus^7 from the Computers!";
	else
		level.mission_stole = getDvar( "scr_virus_get" );
	
	if ( getDvar( "scr_virus_protect" ) == "" )
		level.mission_protect =  "^7Protect the ^9Virus^7 carrier!";
	else
		level.mission_protect = getDvar( "scr_virus_protect" );

	if ( getDvar( "scr_virus_escape" ) == "" )
		level.mission_escape =  "^7Escape with the ^9Virus^7 samples!";
	else
		level.mission_escape = getDvar( "scr_virus_escape" );
		
	if ( getDvar( "scr_virus_escape_now" ) == "" )
		level.mission_escape_now =  "^1Warning ^0: ^7Go to the ^9Extraction Point^7 right now!";
	else
		level.mission_escape_now = getDvar( "scr_virus_escape_now" );		
	
	if ( getDvar( "scr_virus_succeed" ) == "" )
		level.mission_succeed =  "Mission Succeed in";
	else
		level.mission_succeed = getDvar( "scr_virus_succeed" ) + " ";
	
	if ( getDvar( "scr_virus_failed" ) == "" )
		level.mission_failed =  "Mission Failed";
	else
		level.mission_failed = getDvar( "scr_virus_failed" );

	if ( getDvar( "scr_virus_chopper" ) == "" )
		level.mission_chopper =  "^7Protect the ^9Chopper^7!";
	else
		level.mission_chopper = getDvar( "scr_virus_chopper" );
		
	if ( getDvar( "scr_virus_chopper_wait" ) == "" )
		level.mission_chopper_wait =  "^7Wait for the ^9Chopper^7 pickup!";
	else
		level.mission_chopper_wait = getDvar( "scr_virus_chopper_wait" );		
	
	if ( getDvar( "scr_virus_retreat" ) == "" )
		level.mission_retreat =  "Retreat!";
	else
		level.mission_retreat = getDvar( "scr_virus_retreat" );

	if ( getDvar( "scr_virus_hurry" ) == "" )
		level.mission_hurry =  "Go Go Go! Move Out!";
	else
		level.mission_hurry = getDvar( "scr_virus_hurry" );
		
	if ( getDvar( "scr_virus_abort" ) == "" )
		level.mission_abort = "^1Warning ^0: ^7You didn't finished your task!";
	else
		level.mission_abort = getDvar( "scr_virus_abort" );
		
	if ( getDvar( "scr_virus_sampled" ) == "" )
		level.virus_sampled = "^1Warning ^0: ^7We Already have this Sample! Find another one!";
	else
		level.virus_sampled = getDvar( "scr_virus_sampled" );
		
	if ( getDvar( "scr_virus_damaged" ) == "" )
		level.virus_damaged = "^1Warning ^0: ^7This Terminal is Damaged! Find another one!";
	else
		level.virus_damaged = getDvar( "scr_virus_damaged" );
	
	if ( getDvar( "scr_virus_hacking" ) == "" )
		level.virus_hacking = "Downloading...";
	else
		level.virus_hacking = getDvar( "scr_virus_hacking" );		
		
	// Defenders		
		
	if ( getDvar( "scr_virus_lab" ) == "" )
		level.mission_lab =  "^7Defend the ^9Lab Computers^7!";
	else
		level.mission_lab = getDvar( "scr_virus_lab" );
	
	if ( getDvar( "scr_virus_recover" ) == "" )
		level.mission_recover =  "^7Recover the ^9Virus^7 notebook!";
	else
		level.mission_recover = getDvar( "scr_virus_recover" );
	
	if ( getDvar( "scr_virus_shoot_chopper" ) == "" )
		level.mission_shoot_chopper =  "^7Shoot down the ^9Chopper^7! Get an ^1RPG^7!";
	else
		level.mission_shoot_chopper = getDvar( "scr_virus_shoot_chopper" );	
		
	if ( getDvar( "scr_virus_enemy_stole" ) == "" )
		level.mission_enemy_stole =  "^7The Enemy stole one ^9Sample^7 of the ^9Virus^7!";
	else
		level.mission_enemy_stole = getDvar( "scr_virus_enemy_stole" );
		
	if ( getDvar( "scr_virus_enemy_stole_again" ) == "" )
		level.mission_enemy_stole_again =  "^7The Enemy stole another ^9Sample^7 of the ^9Virus^7!";
	else
		level.mission_enemy_stole_again = getDvar( "scr_virus_enemy_stole_again" );		
		
	if ( getDvar( "scr_virus_enemy_gotall" ) == "" )
		level.mission_enemy_gotall =  "^7The Enemy got ^1ALL SAMPLES^7 of the ^9Virus^7!";
	else
		level.mission_enemy_gotall = getDvar( "scr_virus_enemy_gotall" );					
}

// remove elemento do array e reorganiza.
removeArray( array, index )
{
    novoArray = [];

    for(i = 0; i < array.size; i++)
    {
        if(i < index)
			novoArray[i] = array[i];
        else if(i > index) 
			novoArray[i - 1] = array[i];
    }
    return novoArray;
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