#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

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

	precacheShader("waypoint_bomb");
	precacheShader("hud_suitcase_bomb");
	precacheShader("waypoint_target");
	precacheShader("waypoint_target_a");
	precacheShader("waypoint_target_b");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defend_a");
	precacheShader("waypoint_defend_b");
	precacheShader("waypoint_defuse");
	precacheShader("waypoint_defuse_a");
	precacheShader("waypoint_defuse_b");
	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_target_a");
	precacheShader("compass_waypoint_target_b");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defend_a");
	precacheShader("compass_waypoint_defend_b");
	precacheShader("compass_waypoint_defuse");
	precacheShader("compass_waypoint_defuse_a");
	precacheShader("compass_waypoint_defuse_b");
	
	precacheStatusIcon( "hud_suitcase_bomb" );
	
	precacheString( &"MP_EXPLOSIVES_RECOVERED_BY" );
	precacheString( &"MP_EXPLOSIVES_DROPPED_BY" );
	precacheString( &"MP_EXPLOSIVES_PLANTED_BY" );
	precacheString( &"MP_EXPLOSIVES_DEFUSED_BY" );
	precacheString( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	precacheString( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	precacheString( &"MP_CANT_PLANT_WITHOUT_BOMB" );	
	precacheString( &"MP_PLANTING_EXPLOSIVE" );	
	precacheString( &"MP_DEFUSING_EXPLOSIVE" );	
	
	game["nuke_alarm"] = "nuke_alarm";
}

main()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "resist", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "resist", 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "resist", 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "resist", 4, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "resist", 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "resist", 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerKillCamDvar( "resist", 0, 0, 1 );
	
	// tem q setar fixo pro Resist
	SetDvar( "scr_resist_playerrespawndelay", -1 );
	SetDvar( "scr_resist_waverespawndelay", -1 );	
	
	// 1 = Flag
	maps\mp\gametypes\_globallogic::registerTypeDvar( "resist", 1, 0, 1 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;
	//level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.onTimeLimit = ::onTimeLimit; 
	level.endGameOnScoreLimit = false; //false
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
			setDvar( "scr_resist_roundswitch", 0 ); // não mudar de lado
			setDvar( "scr_resist_roundlimit", 1 ); // só um round
			if ( getDvar("resist_rec") == "" )
				setDvar( "resist_rec", 0 ); // se não tem record
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
	
	if ( getDvarInt ( "war_server" ) == 0 && getDvarInt("fl_bots") == 1 && getDvarInt("fl_bots_coop") > 0)
		[[level._setTeamScore]]( game["attackers"], getDvarInt("resist_rec") );		

	setClientNameMode("manual_change");

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_WAVES_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_WAVES_DEFENDER" );
	
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_WAVES_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_WAVES_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_WAVES_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_WAVES_DEFENDER_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );

	// inicializa spawn da defesa
	level.defend_spawn = undefined;
	level.attack_spawn = undefined;
		
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	
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
	allowed[1] = "sd";
	allowed[2] = "bombzone";
	allowed[3] = "blocker";	
	
	if ( getDvar( "scr_resist_striketime" ) == "" )
		level.ReinfTimeOri = 60;
	else
		level.ReinfTimeOri = getDvarInt( "scr_resist_striketime" );	

	level.ReinfTimeNum = 1;
	level.strike_wait = randomIntRange ( 45, 70 );
	level.chega_reinf = 10;
	level.ReinfTime = 0;
	
	CalculaTempoReinf();
	
	level.displayRoundEndText = true;
	maps\mp\gametypes\_gameobjects::main(allowed);

	// thread pra calcular os reforços
	thread ControlaReinf( game["defenders"], level.ReinfTime );
	thread ControlaDefesa( game["defenders"] );
	
	// seta mensagens
	SetaMensagens();
	
	if ( level.Type == 1 )
	{
		// cria flag
		thread defFlag();	
	}

	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
		
	level.plantTime = dvarFloatValue( "planttime", 10, 0, 20 );
	level.defuseTime = dvarFloatValue( "defusetime", 10, 0, 20 );
	level.bombTimer = dvarFloatValue( "bombtimer", 45, 1, 300 );	

	novos_sd_init();
	
	thread Ammo();
	
	thread WavesLiberaAtaque();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
	
	thread WavesLoop();
}

WavesLoop()
{
	level endon("game_ended");
	
	// só inicia após primeiro ataque
	while( level.strikefoi == false )
		wait 1;	
		
	while(1)
	{
		while ( level.reinf == false ) // aguarda iniciar o reinf
			wait 0.1;
			
		wait 3; // pra dar tempo de iniciar o reforço
		
		while ( level.reinf == true ) // aguarda acabar o reinf
			wait 0.1;		
	
		CalculaTempoReinf();
		//iprintlnbold("Reforços em " + level.ReinfTime );
		thread ControlaReinf( game["defenders"], level.ReinfTime );
	}
}

CalculaTempoReinf()
{
	//level.ReinfTime = level.ReinfTimeOri * level.ReinfTimeNum;
	
	level.ReinfTime = level.ReinfTime + level.ReinfTimeOri;
	
	if ( level.ReinfTimeNum == 1 )
		level.ReinfTime = level.ReinfTime + level.strike_wait;
		
	level.chega_reinf = gettime() + level.ReinfTime * 1000;
			
	level.ReinfTimeNum++;
}


// ========================================================================
//		Ammo
// ========================================================================

ProcuraAmmo()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while( level.bombExploded < 2 )
	{
		if ( level.bombExploded == 0 )
		{
			for ( i = 0; i < level.bombZones.size; i++ )
			{
				bombzone = level.bomb_pos[i];
			
				if ( distance(self.origin,bombzone) < 100 )
				{
					DaAmmo();
				}
			}	
		}
		else if ( level.bombExploded == 1 )
		{
			if ( level.exploded_A )
			{
				if ( distance(self.origin,level.Ammo_B) < 100 )
				{
					DaAmmo();
				}			
			}
			else if ( level.exploded_B )
			{
				if ( distance(self.origin,level.Ammo_A) < 100 )
				{
					DaAmmo();
				}			
			}
		}
		wait 1;
	}
}

DaAmmo()
{
	//self iprintlnbold ("Recarrega!");
	thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "weap_pickup" );

	weaponslist = self getweaponslist();
	for( i = 0; i < weaponslist.size; i++ )
	{
		weapon = weaponslist[i];
		self giveMaxAmmo( weapon );
	}
	thread maps\mp\gametypes\_class::ResistAmmo(self);
	wait 10;
}

Ammo()
{
	// controles
	level.bombExploded = 0;
	level.planted_A = false;
	level.planted_B = false;
	level.exploded_A = false;
	level.exploded_B = false;
	level.prorroga = false;
	level.sound_A = false;
	level.sound_B = false;
	
	if ( level.novos_objs )
		novos_sd();	
	
	level.bomb_pos = [];
	
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
		
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
	level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );
	level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
	level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
	level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
	level.sdBomb maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	level.sdBomb.allowWeapons = true;
	level.sdBomb.onPickup = ::onPickup;
	level.sdBomb.onDrop = ::onDrop;
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	// A e B	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );
		
		level.bomb_pos[level.bomb_pos.size] = trigger.origin;
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		bombZone.label = label;
		bombZone maps\mp\gametypes\_gameobjects::setKeyObject( level.sdBomb );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		if ( index == 0 )
		{
			bombZone.onUse = ::onUsePlantObject_A;
			bombZone.onBeginUse = ::onBeginUse_A;
			bombZone.onEndUse = ::onEndUse_A;		
			level.Ammo_A = trigger.origin;		
		}
		else
		{
			bombZone.onUse = ::onUsePlantObject_B;
			bombZone.onBeginUse = ::onBeginUse_B;
			bombZone.onEndUse = ::onEndUse_B;
			level.Ammo_B = trigger.origin;
		}
		bombZone.onCantUse = ::onCantUse;
		bombZone.useWeapon = "briefcase_bomb_mp";
		
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
		bombZone.bombDefuseTrig.label = label;
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

onBeginUse_A( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_A = true;

		if ( isDefined( level.sdBombModel_A ) )
			level.sdBombModel_A hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}

onBeginUse_B( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_B = true;
		
		if ( isDefined( level.sdBombModel_B ) )
			level.sdBombModel_B hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}

onEndUse_A( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_A ) && !result )
		{
			level.sdBombModel_A show();
		}
	}
}

onEndUse_B( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_B ) && !result )
		{
			level.sdBombModel_B show();
		}
	}
}

onCantUse( player )
{
	player iPrintLnBold( &"MP_CANT_PLANT_WITHOUT_BOMB" );
}

onUsePlantObject_A( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_A( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba A
		level thread VoltaBomb_A( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

onUsePlantObject_B( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_B( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba B
		level thread VoltaBomb_B( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

// --------------------------------------- DEFUSING ONLY - INICIO --------------------------------------------

onUseDefuseObject_A( player )
{
	wait .05;
	
	player notify ( "bomb_defused_A" );
	player logString( "bomb defused!" );
	level thread bombDefused_A();
	
	// disable this bomb zone
	self maps\mp\gametypes\_gameobjects::allowUse( "none" );
	self maps\mp\gametypes\_gameobjects::disableObject();
	
	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

onUseDefuseObject_B( player )
{
	wait .05;
	
	player notify ( "bomb_defused_B" );
	player logString( "bomb defused!" );
	level thread bombDefused_B();

	// disable this bomb zone
	self maps\mp\gametypes\_gameobjects::allowUse( "none" );
	self maps\mp\gametypes\_gameobjects::disableObject();
		
	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

// --------------------------------------- DEFUSING ONLY - FIM --------------------------------------------

onDrop( player )
{
		if ( isDefined( player ) && isDefined( player.name ) )
			printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", game["attackers"], player );
			
//		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_lost", player.pers["team"] );
		if ( isDefined( player ) )
		 	player logString( "bomb dropped" );
		 else
		 	logString( "bomb dropped" );

	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
}


onPickup( player )
{
	player.isBombCarrier = true;
	
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );

	if ( isDefined( player ) && isDefined( player.name ) )
		printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", game["attackers"], player );
			
	maps\mp\gametypes\_globallogic::leaderDialog( "bomb_taken", player.pers["team"] );
	player logString( "bomb taken" );

	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}
}


onReset()
{
}

bombPlanted_A( destroyedObj_A, player, label )
{
	level.planted_A = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_A.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_A = destroyedObj_A.visuals[0];

	// acerta o tempo / caso falte menos q o tempo da bomba explodir, tempo restante será o tempo da bomba.
	if ( (maps\mp\gametypes\_globallogic::getTimeRemaining() / 1000) < level.bombTimer )
	{
		maps\mp\gametypes\_globallogic::pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
	}
	setDvar( "ui_bomb_timer", 1 );

	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_A = spawn( "script_model", trace["position"] );
	level.sdBombModel_A.angles = dropAngles;
	level.sdBombModel_A setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_A maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj_A maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	
	// create a new object to defuse with.
	trigger = destroyedObj_A.bombDefuseTrig;
	trigger.origin = level.sdBombModel_A.origin;

	visuals = [];
	defuseObject_A = maps\mp\gametypes\_gameobjects::createUseObjectMission( game["defenders"], trigger, visuals, (0,0,32), "A" );
	defuseObject_A maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject_A maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject_A maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject_A maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject_A maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );
	defuseObject_A.onBeginUse = ::onBeginUse_A;
	defuseObject_A.onEndUse = ::onEndUse_A;
	defuseObject_A.onUse = ::onUseDefuseObject_A;
	defuseObject_A.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.defuseObject_A = defuseObject_A;
	
	BombTimerWait_A();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_A == false )
		return;
	
	level.exploded_A = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_A.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	explosionOrigin = level.sdBombModel_A.origin;
	level.sdBombModel_A hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj_A.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_A.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_A.exploderIndex ) )
		exploder( destroyedObj_A.exploderIndex );
	
	defuseObject_A maps\mp\gametypes\_gameobjects::disableObject();

	// diz q não tem mais nada plantado!
	level.planted_A = false;

	wait 1;	
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );
}

bombPlanted_B( destroyedObj_B, player, label )
{
	level.planted_B = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_B.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_B = destroyedObj_B.visuals[0];

	// acerta o tempo / caso falte menos q o tempo da bomba explodir, tempo restante será o tempo da bomba.
	if ( (maps\mp\gametypes\_globallogic::getTimeRemaining() / 1000) < level.bombTimer )
	{
		maps\mp\gametypes\_globallogic::pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
	}
	setDvar( "ui_bomb_timer", 1 );

	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_B = spawn( "script_model", trace["position"] );
	level.sdBombModel_B.angles = dropAngles;
	level.sdBombModel_B setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_B maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj_B maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	
	// create a new object to defuse with.
	trigger = destroyedObj_B.bombDefuseTrig;
	trigger.origin = level.sdBombModel_B.origin;

	visuals = [];
	defuseObject_B = maps\mp\gametypes\_gameobjects::createUseObjectMission( game["defenders"], trigger, visuals, (0,0,32), "B" );
	defuseObject_B maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject_B maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject_B maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject_B maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject_B maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );
	defuseObject_B.onBeginUse = ::onBeginUse_B;
	defuseObject_B.onEndUse = ::onEndUse_B;
	defuseObject_B.onUse = ::onUseDefuseObject_B;
	defuseObject_B.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.defuseObject_B = defuseObject_B;
	
	BombTimerWait_B();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_B == false )
		return;	
	
	level.exploded_B = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_B.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	explosionOrigin = level.sdBombModel_B.origin;
	level.sdBombModel_B hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj_B.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_B.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_B.exploderIndex ) )
		exploder( destroyedObj_B.exploderIndex );
	
	defuseObject_B maps\mp\gametypes\_gameobjects::disableObject();
	
	// diz q não tem mais nada plantado!
	level.planted_B = false;
	
	wait 1;
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );	
}

BombTimerWait_A()
{
	level endon("game_ended");
	level endon("bomb_defused_A");
	wait level.bombTimer;
}

BombTimerWait_B()
{
	level endon("game_ended");
	level endon("bomb_defused_B");
	wait level.bombTimer;
}


bombDefused_A()
{
	level.planted_A = false;

	level.tickingObject_A maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_A == true )
	{
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );
	}
	level.sound_A = false;

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_A");
}

bombDefused_B()
{
	level.planted_B = false; 

	level.tickingObject_B maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_B == true )
	{
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );
	}
	level.sound_B = false;

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_B");
}

VoltaBomb_A( bomb )
{
	level endon("game_ended");
	
	// disable this bomb zone
	bomb maps\mp\gametypes\_gameobjects::disableObject();
	
	while ( 1 )
	{
		if ( level.exploded_A == true )
		{
			return;
		}
		if ( level.planted_A == false )
		{
			// volta bomba
			bomb maps\mp\gametypes\_gameobjects::enableObject();
			bomb maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			return;
		}
		wait 1;
	}
}

VoltaBomb_B( bomb )
{
	level endon("game_ended");
	
	// disable this bomb zone
	bomb maps\mp\gametypes\_gameobjects::disableObject();
	
	while ( 1 )
	{
		if ( level.exploded_B == true )
		{
			return;
		}
		if ( level.planted_B == false )
		{
			// volta bomba
			bomb maps\mp\gametypes\_gameobjects::enableObject();
			bomb maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			return;
		}
		wait 1;
	}
}

smokeFX( alvo, rot )
{
	alvo = alvo + (0,0,-100);
	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke );
	earthquake( 1, 1.5, alvo, 8000 );
}

// ========================================================================
//		Weapons Attackers
// ========================================================================

ResistEquipaAttack()
{
	self endon("disconnect");
	
	while ( level.strikefoi == false )
		wait ( 0.05 );
	
	wait 0.5;
	
	self GiveWeapon( "frag_grenade_mp" );
	self SetWeaponAmmoClip( "frag_grenade_mp", 0 );
	self SwitchToOffhand( "frag_grenade_mp" );	
}


ResistArmaAttack( weapon )
{
	// rifles
	if ( isSubstr( weapon , "ak47" ) )
		weapon = "ak47_mp";
	if ( isSubstr( weapon , "g36c" ) )
		weapon = "g36c_mp";
	if ( isSubstr( weapon , "g3" ) && !isSubstr( weapon , "g36c" ) )
		weapon = "g3_mp";
	if ( isSubstr( weapon , "m14" ) )
		weapon = "m14_mp";
	if ( isSubstr( weapon , "m16" ) )
		weapon = "m16_mp";						
	if ( isSubstr( weapon , "m4" ) )
		weapon = "m4_mp";						
	
	// SMGs
	if ( isSubstr( weapon , "mp5" ) )
		weapon = "mp5_mp";
	if ( isSubstr( weapon , "skorpion" ) )
		weapon = "skorpion_mp";
	if ( isSubstr( weapon , "uzi" ) )
		weapon = "uzi_mp";
	if ( isSubstr( weapon , "ak74u" ) )
		weapon = "ak74u_mp";
	if ( isSubstr( weapon , "p90" ) )
		weapon = "p90_mp";

	light_infantry_list = "ak47_mp,g36c_mp,g3_mp,m14_mp,m16_mp,m4_mp,ak74u_mp,mp5_mp,p90_mp,skorpion_mp,uzi_mp";
	
	if( !isSubstr( light_infantry_list , weapon ) )
	{
		switch( randomInt(11) )
		{
			case 0:
				weapon = "ak47_mp";
				break;
			case 1:
				weapon = "g36c_mp";
				break;
			case 2:
				weapon = "g3_mp";
				break;
			case 3:
				weapon = "m14_mp";
				break;
			case 4:
				weapon = "m16_mp";
				break;
			case 5:									
				weapon = "m4_mp";						
				break;
			case 6:
				weapon = "p90_mp";									
				break;
			case 7:	
				weapon = "mp5_mp";
				break;
			case 8:
				weapon = "skorpion_mp";
				break;
			case 9:
				weapon = "uzi_mp";
				break;
			case 10:
				weapon = "ak74u_mp";
				break;
			default:
				weapon = "ak47_mp";
				break;
		}
	}				 

	return weapon;
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

WavesSound( player, sound )
{
	wait 3;
	player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( sound );
}

playSoundinSpace( alias, origin )
{
	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 10; // MP doesn't have "sounddone" notifies =(
	org delete();
}

// ========================================================================
//		Reforço
// ========================================================================


ControlaReinf( defenders, tempo )
{
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	wait tempo;
	
	level.reinf = true;
	//level.inOvertime = true;
	
	thread forceSpawnTeam( game["defenders"] );
	
	for ( index = 0; index < level.players.size; index++ )
	{
		if ( level.players[index].pers["team"] == game["defenders"] )
		{
			level.players[index] notify("force_spawn");
			level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( level.reinf_msg, level.hold_msg, undefined, (1, 0, 0), "mp_last_stand" );

			thread WavesSound( level.players[index], "keepfighting" );	
		}
		else
		{
			thread WavesSound( level.players[index], "losing" );	
		}
	}
	
	thread maps\mp\gametypes\_hardpoints::WavesReinf( game["defenders"] );
	
	[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) + 1 );		
	
	if ( [[level._getTeamScore]]( game["defenders"] ) > getDvarInt("resist_rec") ) // atualiza record
	{
		setDvar( "resist_rec", [[level._getTeamScore]]( game["defenders"] ) ); 
		logPrint("-=-=-= RESIST RECORD =-=-=- " + getDvarInt( "resist_rec" ) + "\n");
	}
	
	if ( getDvarInt ( "war_server" ) == 1 && getDvarInt ( "ws_start" ) == 2 && getDvarInt ( "ws_real") > 0 )
	{
		if ( [[level._getTeamScore]]( game["defenders"] ) >= getDvarInt ( "scr_resist_scorelimit" ) )
		{
			wait 10;
			onTimeLimit();
		}
	}	
	
	thread ControlaAtaque( game["attackers"] );
}

ControlaAtaque( attackers )
{
	level endon( "game_ended" );
	
	// tira respawn do ataque
	// com level.reinf == true o respawndelay aumenta!
	
	//aguarda Heli ir embora
	while ( isDefined(level.chopper) )
		wait 0.1;
	
	thread forceSpawnTeam( game["attackers"] );					// força respawn
	thread forceSpawnTeam( game["defenders"] );					// força respawn
	level.reinf = false;										// reverte respawn
	thread NotificaTodos();										// notifica todo mundo
	maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] ); // toca alarme
	//thread WavesProtection();									// spawn protect
}

NotificaTodos()
{
	for ( index = 0; index < level.players.size; index++ )
	{
		player = level.players[index];
		if ( isDefined(player) && player.notifica == false )
		{
			if ( player.team == game["attackers"] )
			{
				if ( level.SidesMSG == 1 )
					player iPrintLnbold( level.msg_attack );
				player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );		
			}
			else if ( player.team == game["defenders"] )
			{
				if ( level.SidesMSG == 1 )
					player iPrintLnbold( level.msg_defend );
				player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "defend" );			
			}
			player thread TempoNotifica();
		}
	}
}

TempoNotifica()
{
	self.notifica = true;
	wait 2;
	self.notifica = false;
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
		if ( level.reinf == false )
		{
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
}

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	self.notifica = false;
	
	self.usingObj = undefined;

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
			{
				self freezeControls( true );
			}
			else if ( self.notifica == false )
			{
				self thread TempoNotifica();
				if ( level.SidesMSG == 1 )
					self iPrintLnbold( level.msg_attack );
				self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
			}
		}
		else if ( self.pers["team"] == game["defenders"] )
		{
			if ( level.strikefoi == true && level.reinf == false )
			{
				if ( !isDefined(self.fl_1stSpawn) )
					thread mata_player( self );
			}
			else 
			{
				if ( self.notifica == false )
				{
					self thread TempoNotifica();
					if ( level.SidesMSG == 1 )
						self iPrintLnbold( level.msg_defend );
					self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "defend" );
				}
				if ( level.strikefoi == false )
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
				
				if ( self.notifica == false )
				{
					self thread TempoNotifica();
					if ( level.SidesMSG == 1 )
						self iPrintLnbold( level.msg_attack );
					self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
				}
			}
		}
		else if ( self.pers["team"] == game["defenders"] )
		{
			if ( level.strikefoi == true )
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

				if ( self.notifica == false )
				{
					self thread TempoNotifica();
					if ( level.SidesMSG == 1 )
						self iPrintLnbold( level.msg_defend );
					self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "defend" );
				}				

				if ( level.strikefoi == false )
					thread maps\mp\gametypes\_class::WavesArmasDefesa();
			}
		}	
	}
	
	if ( self.pers["team"] == game["defenders"] )
		self thread ProcuraAmmo();
	else if ( self.pers["team"] == game["attackers"] ) 
		self thread ResistEquipaAttack();
		
	if ( !isDefined(self.fl_1stSpawn) ) 
		self.fl_1stSpawn = false; // indica que não é mais o primeiro spawn
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

	//if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
	//	[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
	
	if ( getDvarInt ( "war_server" ) == 0 && getDvarInt("fl_bots") == 1 && getDvarInt("fl_bots_coop") > 0)
	{
		if ( [[level._getTeamScore]]( game["defenders"] ) > [[level._getTeamScore]]( game["attackers"] ) )
			winningTeam = game["defenders"];
		else if ( [[level._getTeamScore]]( game["attackers"] ) > [[level._getTeamScore]]( game["defenders"] ) )
			winningTeam = game["attackers"];
		else if ( [[level._getTeamScore]]( game["attackers"] ) == [[level._getTeamScore]]( game["defenders"] ) )
			winningTeam = "tie";
	}

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
	else if ( self.pers["team"] == game["attackers"] )
	{
		if ( level.reinf == true )
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
	if ( getDvar( "scr_resist_msg_reinf" ) == "" )
		level.reinf_msg = "Reinforcements have Arrived!";
	else
		level.reinf_msg = getDvar( "scr_resist_msg_reinf" );
	
	if ( getDvar( "scr_resist_msg_hold" ) == "" )
		level.hold_msg = "Resupply your Ammo! Secure our Defenses!";
	else
		level.hold_msg = getDvar( "scr_resist_msg_hold" );
	
	if ( getDvar( "scr_resist_msg_secured" ) == "" )
		level.zone_sec = "Zone Secured";
	else
		level.zone_sec = getDvar( "scr_resist_msg_secured" );

	if ( getDvar( "scr_resist_msg_attack" ) == "" )
		level.msg_attack = "^9Attack^7!";
	else
		level.msg_attack = getDvar( "scr_resist_msg_attack" );
	
	if ( getDvar( "scr_resist_msg_defend" ) == "" )
		level.msg_defend = "^9Resist^7!";
	else
		level.msg_defend = getDvar( "scr_resist_msg_defend" );
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

	dura_timer = int(( level.strike_wait - 5 )*1000);
	
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
	timerDisplay[game["attackers"]] setTimer( level.strike_wait );
	
	// deleta quando termina o jogo
	thread WavesRemoveClock( timerDisplay[game["attackers"]] );

	wait level.strike_wait;
	
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
			//level.players[index] thread ResistEquipaAttack();
			level.players[index] freezeControls( false );
			if ( getDvarInt ( "frontlines_abmode" ) == 0 )
				level.players[index] enableWeapons();
			if ( level.SidesMSG == 1 )
				level.players[index] iPrintLnbold( level.msg_attack );
			level.players[index] maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
		}
	}
	
	maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
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