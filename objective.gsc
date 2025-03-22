#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "objective", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "objective", 6, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "objective", 6, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "objective", 10, 0, 30 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "objective", 0, 0, 100 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( "objective", 0, 0, 3 );
	
	// 0 = Random
	// 1 = A
	// 2 = B
	// 3 = Sab Bomb	
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "searchdestroy";
	game["dialog"]["offense_obj"] = "obj_destroy";
	game["dialog"]["defense_obj"] = "obj_defend";
}


onPrecacheGameType()
{
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";

	precacheShader("waypoint_bomb");
	precacheShader("hud_suitcase_bomb");
	precacheShader("waypoint_target");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defuse");
	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defuse");
	precacheShader( "waypoint_escort" );
	
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
	
	game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
	game["strings"]["bomb_defused"] = &"MP_BOMB_DEFUSED";
	
	precacheString( game["strings"]["target_destroyed"] );
	precacheString( game["strings"]["bomb_defused"] );

	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_OBJ_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_OBJ_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_OBJ_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_OBJ_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_OBJ_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_OBJ_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_OBJ_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_OBJ_DEFENDER_HINT" );

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
	allowed[2] = "blocker";
	allowed[3] = "sab";
	
	maps\mp\gametypes\_gameobjects::main(allowed);

	thread updateGametypeDvars();
	
	novos_sd_init();
	
	if ( level.novos_objs )
	{
		thread DeleteSabBombs();
		thread bombs();
	}
	else
		thread bombsRELOAD();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}


onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;

	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";

	if ( level.multiBomb && !isDefined( self.carryIcon ) && self.pers["team"] == game["attackers"] && !level.bombPlanted )
	{
		if ( level.splitscreen )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -10, -50 );
			self.carryIcon.alpha = 0.75;
		}
		else
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 50, 50 );
			self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
			self.carryIcon.alpha = 0.75;
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
}


onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	thread checkAllowSpectating();
}


checkAllowSpectating()
{
	wait ( 0.05 );
	
	update = false;
	if ( !level.aliveCount[ game["attackers"] ] )
	{
		level.spectateOverride[game["attackers"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( !level.aliveCount[ game["defenders"] ] )
	{
		level.spectateOverride[game["defenders"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( update )
		maps\mp\gametypes\_spectating::updateSpectateSettings();
}


sd_endGame( winningTeam, endReasonText )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	

	if ( isdefined( winningTeam ) )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	if ( level.bombExploded || level.bombDefused )
		return;
	
	if ( team == "all" )
	{
		if ( level.bombPlanted )
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
		else
			sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		if ( level.bombPlanted )
			return;
		
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}


onOneLeftEvent( team )
{
	if ( level.bombExploded || level.bombDefused )
		return;
	
	//if ( team == game["attackers"] )
	warnLastPlayer( team );
}


onTimeLimit()
{
	if ( level.teamBased )
		sd_endGame( game["defenders"], game["strings"]["time_limit_reached"] );
	else
		sd_endGame( undefined, game["strings"]["time_limit_reached"] );
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

updateGametypeDvars()
{
	level.plantTime = GetDvarFloat( "scr_objective_planttime" );

	if ( level.plantTime < 0 )
		level.plantTime = 5;
	if ( level.plantTime > 20 )
		level.plantTime = 5;
	
	level.defuseTime = GetDvarFloat( "scr_objective_defusetime" );
	
	if ( level.defuseTime < 0 )
		level.defuseTime = 10;
	if ( level.defuseTime > 20 )
		level.defuseTime = 10;
	
	level.bombTimer = GetDvarFloat( "scr_objective_bombtimer" );
	
	if ( level.bombTimer < 1 )
		level.bombTimer = 45;
	if ( level.bombTimer > 60 )
		level.bombTimer = 45;	
		
	level.multiBomb = GetDvarFloat( "scr_objective_multibomb" );

	if ( level.multiBomb < 0 )
		level.multiBomb = 0;
	if ( level.multiBomb > 1 )
		level.multiBomb = 1;		
}


bombs()
{
	// controles
	level.bombPlanted = false;
	level.bombDefused = false;
	level.bombExploded = false;
	
	novos_sd();	
	
	sab_bomb_target = undefined;
	sab_bomb_visuals = undefined;	

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

	precacheModel( "prop_suitcase_bomb" );	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	if ( !level.multiBomb )
	{
		level.sdBomb = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,32) );
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );
		level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
		level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
		level.sdBomb.allowWeapons = true;
		level.sdBomb.onPickup = ::onPickup;
		level.sdBomb.onDrop = ::onDrop;
	}
	else
	{
		trigger delete();
		visuals[0] delete();
	}	
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	obj_trigger = [];
	
	obj_index = randomInt ( bombZones.size );
	
	// A e B	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{
		if ( index == obj_index )
		{
			trigger = bombZones[index];
			visuals = getEntArray( bombZones[index].target, "targetname" );    
				
			bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
			bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
			bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
			bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
			if ( !level.multiBomb )
					bombZone maps\mp\gametypes\_gameobjects::setKeyObject( level.sdBomb );
			//label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
			//bombZone.label = label;
			bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
			bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
			bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
			bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" );
			bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			bombZone.onBeginUse = ::onBeginUse;
			bombZone.onEndUse = ::onEndUse;
			bombZone.onUse = ::onUsePlantObject;
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
			//bombZone.bombDefuseTrig.label = label;
			
			// seta a bomba obj
			obj_trigger = trigger;
		}
		else
		{
			// destroi outra bomba

			trigger = bombZones[index];
			visuals = getEntArray( bombZones[index].target, "targetname" );    
	
			//logPrint("visuals.size = " + visuals.size + "\n");
			
			// deleta visual
			for ( i = 0; i < visuals.size; i++ )
			{
				visuals[i] delete();
			}
			
			// deleta trigger
			trigger delete();
		}
	}	

	// deleta clips longe do trigger
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{
			if( clips[i].script_gameobjectname == "bombzone" )
			{	
				if( distance( clips[i].origin , obj_trigger.origin ) > 100 )
						clips[i] delete();
			}
		}
	}	
}

bombsRELOAD()
{
	level.bombPlanted = false;
	level.bombDefused = false;
	level.bombExploded = false;
	
	sab_bomb_target = undefined;
	sab_bomb_visuals = undefined;	

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

	// inicia dizendo que tem sab
	level.sab_ok = true;
	
	// testa se tem sab
	testa_sab = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( testa_sab ) ) 
	{
		level.sab_ok = false;
	}

	if ( level.sab_ok == true )
	{
		// adiciona a origem da bomba do SAB correta
		sab_bomb_target = DefineSabBomb( maleta ) GetOrigin();		
	}

	precacheModel( "prop_suitcase_bomb" );	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	if ( !level.multiBomb )
	{
		level.sdBomb = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,32) );
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );
		level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
		level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
		level.sdBomb.allowWeapons = true;
		level.sdBomb.onPickup = ::onPickup;
		level.sdBomb.onDrop = ::onDrop;
	}
	else
	{
		trigger delete();
		visuals[0] delete();
	}
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	if ( level.sab_ok == true )
	{
		// define posição final da bomba
		sab_bomb_visuals = SabBombPosFinal ( sab_bomb_target );
		//logPrint("sab_bomb_target = " + sab_bomb_target + "\n");
	}	
	
	// depois de pegar posição, deleta todos os objs do sab
	thread DeleteSabBombs();	
	
	switch( level.Type )
	{
		case 0:
			obj_index = randomInt ( bombZones.size + 1 );
			break;
		case 1:
			obj_index = 0;
			break;
		case 2:
			obj_index = 1;
			break;
		case 3:
			obj_index = 2;
			break;
		default:
			obj_index = randomInt ( bombZones.size + 1 );
			break;
	}
	
	//logPrint("obj_index = " + obj_index + "\n");
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	obj_trigger = [];
	
	if ( level.sab_ok == false )
	{
		if ( level.Type == 0  || level.Type == 3 )
		{
			obj_index = randomInt ( bombZones.size );
		}
	}
		
	// sab bomb	
	if ( obj_index == 2 )
	{
		trigger_a = bombZones[0];
		trigger_b = bombZones[1];
		a_bomb = randomInt(bombZones.size);

		trigger = bombZones[a_bomb];
		visuals = getEntArray( bombZones[a_bomb].target, "targetname" );    

		if ( distance(trigger_a.origin,sab_bomb_target) > 100 && distance(trigger_b.origin,sab_bomb_target) > 100 )
		{
			// se distancia > 50, temos novo bombsite = move bomba
			
			// move clip
			novo_obj = undefined;
			for(i=0 ; i<clips.size ; i++)
			{
				if ( isDefined ( clips[i].script_gameobjectname ) )
				{
					if( clips[i].script_gameobjectname == "bombzone" )
					{
						if( distance( clips[i].origin , trigger.origin ) <= 100 )
							novo_obj = clips[i];
					}
				}
			}
			novo_obj.origin = sab_bomb_target + (0, 0, 30);
			
			// move explosão FX
			nova_explo = undefined;
			for( i=0 ; i<destroyed_models.size ; i++ )
			{
				if( distance( destroyed_models[i].origin , trigger.origin ) <= 200 )
					nova_explo = destroyed_models[i];
			}
			if (destroyed_models.size != 0)
			{
				nova_explo.origin = sab_bomb_visuals;
			}
			
			// move visuals
			novo_visual = undefined;
			for( i=0 ; i<visuals.size ; i++ )
			{
				if( distance( visuals[i].origin , trigger.origin ) <= 100 )
					novo_visual = visuals[i];
			}
			novo_visual.origin = sab_bomb_visuals;
			
			// move trigger
			trigger.origin = sab_bomb_target;
		}
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
		if ( !level.multiBomb )
				bombZone maps\mp\gametypes\_gameobjects::setKeyObject( level.sdBomb );
		//label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		//bombZone.label = label;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		bombZone.onBeginUse = ::onBeginUse;
		bombZone.onEndUse = ::onEndUse;
		bombZone.onUse = ::onUsePlantObject;
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
		//bombZone.bombDefuseTrig.label = label;
		
		// seta a bomba obj
		obj_trigger = trigger;

		// destroi outra bomba

		trigger_del = bombZones[!a_bomb];
		visuals_del = getEntArray( bombZones[!a_bomb].target, "targetname" );    

		//logPrint("visuals_del.size = " + visuals_del.size + "\n");
		
		// deleta visual
		for ( i = 0; i < visuals_del.size; i++ )
		{
			if( distance( visuals_del[i].origin , obj_trigger.origin ) > 100 )
				visuals_del[i] delete();
		}
		
		// deleta trigger
		trigger_del delete();
	}
	else
	{
		// sd bombs
		for ( index = 0; index < bombZones.size; index++ )
		{	
			if ( index == obj_index )
			{
				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );    
					
				bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
				bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
				bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
				bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
				bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
				if ( !level.multiBomb )
						bombZone maps\mp\gametypes\_gameobjects::setKeyObject( level.sdBomb );
				//label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
				//bombZone.label = label;
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" );
				bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
				bombZone.onBeginUse = ::onBeginUse;
				bombZone.onEndUse = ::onEndUse;
				bombZone.onUse = ::onUsePlantObject;
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
				//bombZone.bombDefuseTrig.label = label;
				
				// seta a bomba obj
				obj_trigger = trigger;
			}
			else
			{
				// destroi outra bomba

				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );    
		
				//logPrint("visuals.size = " + visuals.size + "\n");
				
				// deleta visual
				for ( i = 0; i < visuals.size; i++ )
				{
					visuals[i] delete();
				}
				
				// deleta trigger
				trigger delete();
			}
		}	
	}

	// deleta clips longe do trigger
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{
			if( clips[i].script_gameobjectname == "bombzone" )
			{	
				if( distance( clips[i].origin , obj_trigger.origin ) > 100 )
						clips[i] delete();
			}
		}
	}
	
}

DefineSabBomb( maleta )
{
	sab_bomb_al = getEnt( "sab_bomb_allies", "targetname" );
	sab_bomb_ax = getEnt( "sab_bomb_axis", "targetname" );

	if ( distance(maleta.origin,sab_bomb_al.origin) > distance(maleta.origin,sab_bomb_ax.origin) )
	{
		return sab_bomb_al;
	}
	else
	{
		return sab_bomb_ax;		
	}
}

DeleteSabBombs()
{
	allowed = [];
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	allowed[3] = "objective";

	maps\mp\gametypes\_gameobjects::main(allowed);
}

SabBombPosFinal( bomb )
{
	nova_origem = PhysicsTrace( bomb , bomb + ( 0, 0, -100 ) );
	
	//logPrint("distance = " + distance(nova_origem, bomb ) + "\n");
	
	if ( distance(nova_origem, bomb ) > 80 )
	{
		return bomb;
	}
	else
	{
		return nova_origem;
	}
}

onBeginUse( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		
		if ( isDefined( level.sdBombModel ) )
			level.sdBombModel hide();
	}
	else
	{
		player.isPlanting = true;
		
	}
}

onEndUse( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel ) && !result )
		{
			level.sdBombModel show();
		}
	}
}

onCantUse( player )
{
	player iPrintLnBold( &"MP_CANT_PLANT_WITHOUT_BOMB" );
}

onUsePlantObject( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted( self, player );
		player logString( "bomb planted!" );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
		
		// remove icon se player planta a bomba
		if ( isDefined( player ) )
		{
            if ( isAlive( player ) ) 
			{
				player.statusicon = "";
			}
		}		
	}
}

onUseDefuseObject( player )
{
	wait .05;
	
	player notify ( "bomb_defused" );
	player logString( "bomb defused!" );
	level thread bombDefused();
	
	// disable this bomb zone
	self maps\mp\gametypes\_gameobjects::disableObject();
	
	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );
	maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}


onDrop( player )
{
	if ( !level.bombPlanted )
	{
		if ( isDefined( player ) && isDefined( player.name ) )
			printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", game["attackers"], player );

		// remove icon se player perde a bomba
		if ( isDefined( player ) )
		{
            if ( isAlive( player ) ) 
			{
				player.statusicon = "";
			}
		}
			
//		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_lost", player.pers["team"] );
		if ( isDefined( player ) )
		 	player logString( "bomb dropped" );
		 else
		 	logString( "bomb dropped" );
	}

	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
	
	maps\mp\_utility::playSoundOnPlayers( game["bomb_dropped_sound"], game["attackers"] );
}


onPickup( player )
{
	player.isBombCarrier = true;

	player.statusicon = "hud_suitcase_bomb";
	
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_escort" );

	if ( !level.bombDefused )
	{
		if ( isDefined( player ) && isDefined( player.name ) )
			printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", game["attackers"], player );
			
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_taken", player.pers["team"] );
		player logString( "bomb taken" );
	}		
	maps\mp\_utility::playSoundOnPlayers( game["bomb_recovered_sound"], game["attackers"] );
	
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


bombPlanted( destroyedObj, player )
{
	maps\mp\gametypes\_globallogic::pauseTimer();
	level.bombPlanted = true;
	
	destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject = destroyedObj.visuals[0];

	level.timeLimitOverride = true;
	setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
	setDvar( "ui_bomb_timer", 1 );
	
	if ( !level.multiBomb )
	{
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setDropped();
		level.sdBombModel = level.sdBomb.visuals[0];
	}
	else
	{
		
		for ( index = 0; index < level.players.size; index++ )
		{
			if ( isDefined( level.players[index].carryIcon ) )
				level.players[index].carryIcon destroyElem();
		}

		trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
		
		tempAngle = randomfloat( 360 );
		forward = (cos( tempAngle ), sin( tempAngle ), 0);
		forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
		dropAngles = vectortoangles( forward );
		
		level.sdBombModel = spawn( "script_model", trace["position"] );
		level.sdBombModel.angles = dropAngles;
		level.sdBombModel setModel( "prop_suitcase_bomb" );
	}
	destroyedObj maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	/*
	destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );
	*/
	//label = destroyedObj maps\mp\gametypes\_gameobjects::getLabel();
	
	// create a new object to defuse with.
	trigger = destroyedObj.bombDefuseTrig;
	trigger.origin = level.sdBombModel.origin;
	visuals = [];
	defuseObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,32) );
	defuseObject maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );
	//defuseObject.label = label;
	defuseObject.onBeginUse = ::onBeginUse;
	defuseObject.onEndUse = ::onEndUse;
	defuseObject.onUse = ::onUseDefuseObject;
	defuseObject.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.defuseObject = defuseObject;
	
	BombTimerWait();
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded || level.bombDefused )
		return;
	
	level.bombExploded = true;
	
	explosionOrigin = level.sdBombModel.origin;
	level.sdBombModel hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	earthquake( 1, 1.5, explosionOrigin, 8000 );
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );
	
	for ( index = 0; index < level.bombZones.size; index++ )
		level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
	defuseObject maps\mp\gametypes\_gameobjects::disableObject();
	
	setGameEndTime( 0 );
	
	wait 3;
	
	sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
}

BombTimerWait()
{
	level endon("game_ended");
	level endon("bomb_defused");
	wait level.bombTimer;
}

playSoundinSpace( alias, origin )
{
	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 10; // MP doesn't have "sounddone" notifies =(
	org delete();
}

bombDefused()
{
	level.tickingObject maps\mp\gametypes\_globallogic::stopTickingSound();
	level.bombDefused = true;
	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused");
	
	wait 1.5;
	
	setGameEndTime( 0 );
	
	sd_endGame( game["defenders"], game["strings"]["bomb_defused"] );
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