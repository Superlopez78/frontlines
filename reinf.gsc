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


registerScoreLimitDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_scorelimit");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	level.scoreLimitDvar = dvarString;	
	level.scorelimitMin = minValue;
	level.scorelimitMax = maxValue;
	level.scoreLimit = getDvarInt( level.scoreLimitDvar );
	
	setDvar( "ui_scorelimit", level.scoreLimit );
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

// funcao pra registrar scr_GAMETYPE_type
registerTypeDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_type");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	
	level.TypeDvar = dvarString;
	level.TypeMin = minValue;
	level.TypeMax = maxValue;
	level.Type = getDvarInt( level.TypeDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerRoundSwitchDvar( "reinf", 1, 0, 9 );
	registerTimeLimitDvar( "reinf", 8, 0, 1440 );
	registerScoreLimitDvar( "reinf", 4, 0, 500 );
	registerRoundLimitDvar( "reinf", 6, 0, 30 );
	registerNumLivesDvar( "reinf", 0, 0, 0 );
	registerTypeDvar( "reinf", 0, 0, 3 );

	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	
	level.onRespawnDelay = ::getRespawnDelay;
	level.onPlayerKilled = ::onPlayerKilled;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "searchdestroy";
	game["dialog"]["offense_obj"] = "objs_destroy";
	game["dialog"]["defense_obj"] = "objs_defend";
}

onPrecacheGameType()
{
	precacheShader("waypoint_target");
	precacheShader("waypoint_target_a");
	precacheShader("waypoint_target_b");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defend_a");
	precacheShader("waypoint_defend_b");
	precacheShader("waypoint_defuse");

	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_target_a");
	precacheShader("compass_waypoint_target_b");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defend_a");
	precacheShader("compass_waypoint_defend_b");
	precacheShader("compass_waypoint_defuse");

	precacheShader("hud_suitcase_bomb");
	precacheStatusIcon( "hud_suitcase_bomb" );	
	
	precacheString( &"MP_PLANTING_EXPLOSIVE" );	
	precacheString( &"MP_DEFUSING_EXPLOSIVE" );	
	
	// airborne
	maps\mp\gametypes\_airborne::init();	
}

onStartGameType()
{
	level.tocaalarme = true;

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
	
	// targets_destroyed
	if ( getDvar( "scr_targets_endtext" ) == "" )
		level.targets_destroyed = "Targets Destroyed";
	else
		level.targets_destroyed = getDvar( "scr_targets_endtext" );

	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_REINF_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_REINF_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_REINF_ATTACKER_SCORE" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_REINF_DEFENDER_SCORE" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_REINF_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_REINF_DEFENDER_HINT" );

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
	
	//maps\mp\gametypes\_gameobjects::main(allowed);
	main_gameobjects(allowed);
	
	thread updateGametypeDvars();
	
	novos_sd_init();
	
	if ( level.novos_objs )
	{
		thread DeleteSabBombs();
		thread bombs();
	}
	else
		thread bombsRELOAD();
	
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
		
	thread CalculaReinf();	
		
	// zera/inicia kills pros 2 lados
	level.ax_reinf = 0;
	level.al_reinf = 0;
	
	//maps\mp\gametypes\_globallogic::
	DeletaOutrosSpawns( "sd,tdm" );
}

updateGametypeDvars()
{
	level.plantTime = dvarFloatValue( "planttime", 5, 0, 20 );
	level.defuseTime = dvarFloatValue( "defusetime", 10, 0, 20 );
	level.bombTimer = dvarFloatValue( "bombtimer", 45, 1, 300 );
}


bombs()
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
	
	novos_sd();	
	
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	sab_bomb_target = undefined;
	sab_bomb_visuals = undefined;	

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		Rerror("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	// salva trigger da maleta pra achar bomba correta
	maleta = trigger;
	
	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		Rerror("No sd_bomb script_model found in map.");
		return;
	}	

	precacheModel( "prop_suitcase_bomb" );	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();	
	
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
			
			bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
			bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
			bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
			bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
			label = bombZone getLabel();
			bombZone.label = label;
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
			}
			else
			{
				bombZone.onUse = ::onUsePlantObject_B;
				bombZone.onBeginUse = ::onBeginUse_B;
				bombZone.onEndUse = ::onEndUse_B;
			}
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

bombsRELOAD()
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
	
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	sab_bomb_target = undefined;
	sab_bomb_visuals = undefined;	

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		//maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	// salva trigger da maleta pra achar bomba correta
	maleta = trigger;

	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		//maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}

	// inicia dizendo que tem sab
	level.sab_ok = true;
	
	// testa se tem sab
	testa_sab = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( testa_sab ) ) 
		level.sab_ok = false;

	if ( level.sab_ok == true ) // adiciona a origem da bomba do SAB correta
		sab_bomb_target = DefineSabBomb( maleta ) GetOrigin();		
	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	if ( level.sab_ok == true ) // define posição final da bomba
		sab_bomb_visuals = SabBombPosFinal ( sab_bomb_target );
	
	// depois de pegar posição, deleta todos os objs do sab
	thread DeleteSabBombs();	
	
	switch( level.Type )
	{
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
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	if ( level.sab_ok == false )
		obj_index = 0;
	
	if ( obj_index == 0 )
	{	
		// A e B	// sd bombs
		for ( index = 0; index < bombZones.size; index++ )
		{
			trigger = bombZones[index];
			visuals = getEntArray( bombZones[index].target, "targetname" );
			
			bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
			bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
			bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
			label = bombZone getLabel();
			bombZone.label = label;
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
			}
			else
			{
				bombZone.onUse = ::onUsePlantObject_B;
				bombZone.onBeginUse = ::onBeginUse_B;
				bombZone.onEndUse = ::onEndUse_B;
			}
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
	else if ( obj_index == 1 )
	{
		// B e C	// SD B + SAB
		
		trigger_a = bombZones[0];
		trigger_b = bombZones[1];
		
		for ( index = 0; index < bombZones.size; index++ )
		{
			if ( index == 1 )
			{
				// sab bomb
				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );    

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
						nova_explo.origin = sab_bomb_visuals;
					
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
				label = bombZone getLabel();
				bombZone.label = label;
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
				bombZone.onBeginUse = ::onBeginUse_A;
				bombZone.onEndUse = ::onEndUse_A;	
				bombZone.onUse = ::onUsePlantObject_A;
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
			else
			{
				// B bomb
				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );
				
				bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
				bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
				bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
				bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
				label = bombZone getLabel();
				bombZone.label = label;
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
				bombZone.onBeginUse = ::onBeginUse_B;
				bombZone.onEndUse = ::onEndUse_B;
				bombZone.onUse = ::onUsePlantObject_B;
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
	else if ( obj_index == 2 )
	{
		//A e C  // SD A + Sab Bomb
		
		trigger_a = bombZones[0];
		trigger_b = bombZones[1];
		
		for ( index = 0; index < bombZones.size; index++ )
		{
			if ( index == 0 )
			{
				// sab bomb
				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );    

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
						nova_explo.origin = sab_bomb_visuals;
					
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
				label = bombZone getLabel();
				bombZone.label = label;
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
				bombZone.onBeginUse = ::onBeginUse_B;
				bombZone.onEndUse = ::onEndUse_B;
				bombZone.onUse = ::onUsePlantObject_B;
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
			else
			{
				// A bomb
				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );
				
				bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
				bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
				bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
				bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
				label = bombZone getLabel();
				bombZone.label = label;
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
				bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
				bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
				bombZone.onBeginUse = ::onBeginUse_A;
				bombZone.onEndUse = ::onEndUse_A;
				bombZone.onUse = ::onUsePlantObject_A;
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
}

DefineSabBomb( maleta )
{
	sab_bomb_al = getEnt( "sab_bomb_allies", "targetname" );
	sab_bomb_ax = getEnt( "sab_bomb_axis", "targetname" );

	if ( distance(maleta.origin,sab_bomb_al.origin) > distance(maleta.origin,sab_bomb_ax.origin) )
		return sab_bomb_al;
	else
		return sab_bomb_ax;		
}

DeleteSabBombs()
{
	allowed = [];
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";

	//maps\mp\gametypes\_gameobjects::
	main_gameobjects(allowed);
}

main_gameobjects(allowed)
{
	entitytypes = getentarray();
	for(i = 0; i < entitytypes.size; i++)
	{
		if(isdefined(entitytypes[i].script_gameobjectname))
		{
			dodelete = true;
			
			// allow a space-separated list of gameobjectnames
			gameobjectnames = strtok(entitytypes[i].script_gameobjectname, " ");
			
			for(j = 0; j < allowed.size; j++)
			{
				for (k = 0; k < gameobjectnames.size; k++)
				{
					if(gameobjectnames[k] == allowed[j])
					{	
						dodelete = false;
						break;
					}
				}
				if (!dodelete)
					break;
			}
			
			if(dodelete)
			{
				entitytypes[i] delete();
			}
		}
	}
}

SabBombPosFinal( bomb )
{
	nova_origem = PhysicsTrace( bomb , bomb + ( 0, 0, -100 ) );
	
	if ( distance(nova_origem, bomb ) > 80 )
		return bomb;
	else
		return nova_origem;
}

isFriendlyTeam( team )
{
	if ( self.ownerTeam == "any" )
		return true;
	
	if ( self.ownerTeam == team )
		return true;

	return false;
}

onBeginUse_A( player )
{
	if ( self isFriendlyTeam( player.pers["team"] ) )
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
	if ( self isFriendlyTeam( player.pers["team"] ) )
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

	if ( self isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_A ) && !result )
			level.sdBombModel_A show();
	}
}

onEndUse_B( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_B ) && !result )
			level.sdBombModel_B show();
	}
}

onUsePlantObject_A( player )
{
	// planted the bomb
	if ( !self isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_A( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba A
		level thread VoltaBomb_A( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );

		leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

onUsePlantObject_B( player )
{
	// planted the bomb
	if ( !self isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_B( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba B
		level thread VoltaBomb_B( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );

		leaderDialog( "bomb_planted" );

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

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

// --------------------------------------- DEFUSING ONLY - FIM --------------------------------------------

bombPlanted_A( destroyedObj_A, player, label )
{
	level.planted_A = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_A.visuals[0] thread playTickingSound(); //maps\mp\gametypes\_globallogic::
	level.tickingObject_A = destroyedObj_A.visuals[0];

	if ( (getTimeRemaining() / 1000) < level.bombTimer )
	{
		pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
		thread ExecProrroga();
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
	
	destroyedObj_A.visuals[0] stopTickingSound();
	
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
	
	if ( level.bombExploded == 2 )
	{
		setGameEndTime( 0 );
		wait 2;
		sd_endGame( game["attackers"], level.targets_destroyed );
	}	
}

bombPlanted_B( destroyedObj_B, player, label )
{
	level.planted_B = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_B.visuals[0] thread playTickingSound(); //maps\mp\gametypes\_globallogic::
	level.tickingObject_B = destroyedObj_B.visuals[0];
	
	if ( (getTimeRemaining() / 1000) < level.bombTimer )
	{
		pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
		thread ExecProrroga();
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
	
	destroyedObj_B.visuals[0] stopTickingSound();
	
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
	
	if ( level.bombExploded == 2 )
	{
		setGameEndTime( 0 );
		wait 2;
		sd_endGame( game["attackers"], level.targets_destroyed );
	}	
}

ExecProrroga()
{
	wait 1;

	waitTime = 0;
	level.prorroga = true;
	
	// aguarda o tempo da bomba
	while ( waitTime < level.bombTimer )
	{
		waitTime += 1;
		wait ( 1.0 );
	}		

	// após o tempo termina o jogo se não tiver bombas plantadas
	if ( level.planted_A == false && level.planted_B == false )
	{
		wait 2;
		thread onTimeLimit();
	}
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

	level.tickingObject_A stopTickingSound();
	
	if ( level.sound_A == true )
		leaderDialog( "bomb_defused" );

	level.sound_A = false;

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_A");
}

bombDefused_B()
{
	level.planted_B = false; 

	level.tickingObject_B stopTickingSound();
	
	if ( level.sound_B == true )
		leaderDialog( "bomb_defused" );

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
			return;

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
			return;

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

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	
	if ( level.inGracePeriod || getDvarInt ( "frontlines_abmode" ) == 0 )
	{	
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_sd_spawn_attacker";
		else
			spawnPointName = "mp_sd_spawn_defender";

		if ( !isDefined( self.carryIcon ) && self.pers["team"] == game["attackers"] )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
			self.carryIcon.alpha = 0.75;
		}

		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		self spawn( spawnpoint.origin, spawnpoint.angles );
	}
	else	// airborne
	{
		if ( !isDefined( self.carryIcon ) && self.pers["team"] == game["attackers"] )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
			self.carryIcon.alpha = 0.75;
		}		
		
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		assert( spawnPoints.size );
		
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
	}
	level notify ( "spawned_player" );
}

CalculaReinf()
{
	// garante um mínimo!
	level.army = 3;
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	level.army = int(level.players.size / 4);
	
	if ( level.army < 3 )
		level.army = 3;
}

TestaReinf( team )
{
	if ( team == "axis" )
	{
		level.ax_reinf++;
		if ( level.ax_reinf >= level.army )
		{
			level.ax_reinf = 0;
			thread Reinforcements( team );
		}
		else
		{
			faltam = level.army - level.ax_reinf;
			printOnPlayers( "^1T-" + faltam + "^7 for Reinforcements!", team );
		}
	}
	else if ( team == "allies" )
	{
		level.al_reinf++;
		if ( level.al_reinf >= level.army )
		{
			level.al_reinf = 0;
			thread Reinforcements( team );
		}
		else
		{
			faltam = level.army - level.al_reinf;
			printOnPlayers( "^1T-" + faltam + "^7 for Reinforcements!", team );
		}
	}
}

Reinforcements( team )
{
	level endon ( "game_ended" );

	printOnPlayers( "^1Reinforcements ^7have arrived!", team );
	playSoundOnPlayers( "mp_suitcase_pickup", team );

	thread TocaAlarme();

	for ( index = 0; index < level.players.size; index++ )
	{
		if ( level.players[index].team == team && !isAlive( level.players[index] ) )
			level.players[index] notify("force_spawn");
	}
}

getRespawnDelay()
{
	self.lowerMessageOverride = undefined;
	self.lowerMessageOverride = &"HAJAS_WAVES_WAITING";
	
	timeRemaining = 1000;
	
	return (int(timeRemaining));
}


TocaAlarme()
{
	if ( level.tocaalarme == false )
		return;

	level.tocaalarme = false;
	maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
	wait 45;
	level.tocaalarme = true;
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	thread checkAllowSpectating();
	
	thread TestaReinf( level.otherTeam[self.team] );
	
	thread TestaTimeMorto( self.team );
}

TestaTimeMorto( team )
{
	wait 2; // dar tempo pra morte processar?
	
	if ( !isDefined(level.endlooptest) )
		level.endlooptest = false;

	if ( level.everExisted[team] && level.aliveCount[team] == 0 )
	{
		if ( team == game["attackers"] )
		{
			// já está no looping pra acabar round
			if ( level.endlooptest == true )
				return;
				
			while( level.everExisted[team] && level.aliveCount[team] == 0 )
			{
				level.endlooptest = true;
			
				if ( level.bombExploded == 1 && ( level.planted_A == false && level.planted_B == false ))
				{
					level.displayRoundEndText = true;
					sd_endGame( "tie", game["strings"]["round_draw"] );
					return;
				}
				else if ( level.bombExploded == 0 && ( level.planted_A == true || level.planted_B == true ) )
				{
					//
				}				
				else if ( level.bombExploded == 1 && ( level.planted_A == true || level.planted_B == true ) )
				{
					//
				}			
				else if ( level.bombExploded == 2 )
					return;
				else
				{
					level.displayRoundEndText = true;
					sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
					return;
				}
				wait 1;
			}
			level.endlooptest = false;
		}
		else if ( team == game["defenders"] )
		{
			level.displayRoundEndText = true;
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
		}
	}
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

onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = randomInt(2);
		if ( aheadTeam != 0 )
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

sd_endGame( winningTeam, endReasonText )
{
	if ( isdefined( winningTeam ) && winningTeam != "tie" )
	{
		if ( isdefined( [[level._getTeamScore]]( winningTeam ) ) )
			[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );
	}
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onTimeLimit()
{
	// 2 bombas explodiram = ataque vence
	// 1 bomba explodiu = empate
	// 0 bombas = defesa vence

	if ( level.bombExploded == 2 )
		sd_endGame( game["attackers"], game["strings"]["time_limit_reached"] );
	else if ( level.bombExploded == 1 )
		sd_endGame( "tie", game["strings"]["time_limit_reached"] );
	else
		sd_endGame( game["defenders"], game["strings"]["time_limit_reached"] );
}

onOneLeftEvent( team )
{
	if ( level.bombExploded == 2 )
		return;

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
	self leaderDialogOnPlayer( "last_alive" );
	
	self maps\mp\gametypes\_missions::lastManSD();
}

onDeadEvent( team )
{
	if ( level.bombExploded == 2 )
		return;

	if ( team == "all" )
	{
		if ( level.planted_A == true && level.planted_B == true )
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
		else if ( level.planted_A == true || level.planted_B == true )
			sd_endGame( "tie", game["strings"]["round_draw"] );
		else if ( level.exploded_A == true && level.planted_B == true )
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );			
		else if ( level.exploded_B == true && level.planted_A == true )
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );			
		else
			sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		while(1)
		{
			if ( level.bombExploded == 1 && ( level.planted_A == false && level.planted_B == false ))
			{
				sd_endGame( "tie", game["strings"]["round_draw"] );
				return;
			}
			else if ( level.bombExploded == 0 && ( level.planted_A == true || level.planted_B == true ) )
			{
				//
			}				
			else if ( level.bombExploded == 1 && ( level.planted_A == true || level.planted_B == true ) )
			{
				//
			}			
			else if ( level.bombExploded == 2 )
				return;
			else
			{
				sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
				return;
			}
			wait 1;
		}
	}
	else if ( team == game["defenders"] )
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
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
	WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialog( sound, team );
}

WaitTillSlowProcessAllowed()
{
	// wait only a few frames if necessary
	// if we wait too long, we might get too many threads at once and run out of variables
	// i'm trying to avoid using a loop because i don't want any extra variables
	if ( level.lastSlowProcessFrame == gettime() )
	{
		wait .05;
		if ( level.lastSlowProcessFrame == gettime() )
		{
		wait .05;
			if ( level.lastSlowProcessFrame == gettime() )
			{
				wait .05;
				if ( level.lastSlowProcessFrame == gettime() )
				{
					wait .05;
				}
			}
		}
	}
	
	level.lastSlowProcessFrame = gettime();
}

leaderDialog( dialog, team, group, excludeList )
{
	assert( isdefined( level.players ) );

	if ( level.splitscreen )
		return;
		
	if ( !isDefined( team ) )
	{
		leaderDialogBothTeams( dialog, "allies", dialog, "axis", group, excludeList );
		return;
	}
	
	if ( level.splitscreen )
	{
		if ( level.players.size )
			level.players[0] leaderDialogOnPlayer( dialog, group );
		return;
	}
	
	if ( isDefined( excludeList ) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( (isDefined( player.pers["team"] ) && (player.pers["team"] == team )) && !isExcluded( player, excludeList ) )
				player leaderDialogOnPlayer( dialog, group );
		}
	}
	else
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( isDefined( player.pers["team"] ) && (player.pers["team"] == team ) )
				player leaderDialogOnPlayer( dialog, group );
		}
	}
}

leaderDialogBothTeams( dialog1, team1, dialog2, team2, group, excludeList )
{
	assert( isdefined( level.players ) );
	
	if ( level.splitscreen )
		return;

	if ( level.splitscreen )
	{
		if ( level.players.size )
			level.players[0] leaderDialogOnPlayer( dialog1, group );
		return;
	}
	
	if ( isDefined( excludeList ) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			team = player.pers["team"];
			
			if ( !isDefined( team ) )
				continue;
			
			if ( isExcluded( player, excludeList ) )
				continue;
			
			if ( team == team1 )
				player leaderDialogOnPlayer( dialog1, group );
			else if ( team == team2 )
				player leaderDialogOnPlayer( dialog2, group );
		}
	}
	else
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			team = player.pers["team"];
			
			if ( !isDefined( team ) )
				continue;
			
			if ( team == team1 )
				player leaderDialogOnPlayer( dialog1, group );
			else if ( team == team2 )
				player leaderDialogOnPlayer( dialog2, group );
		}
	}
}

leaderDialogOnPlayer( dialog, group )
{
	if(isDefined(self.bIsBot) && self.bIsBot == true)
		return;

	team = self.pers["team"];

	if ( level.splitscreen )
		return;
	
	if ( !isDefined( team ) )
		return;
	
	if ( team != "allies" && team != "axis" )
		return;
	
	if ( isDefined( group ) )
	{
		// ignore the message if one from the same group is already playing
		if ( self.leaderDialogGroup == group )
			return;

		hadGroupDialog = isDefined( self.leaderDialogGroups[group] );

		self.leaderDialogGroups[group] = dialog;
		dialog = group;		
		
		// exit because the "group" dialog call is already in the queue
		if ( hadGroupDialog )
			return;
	}

	if ( !self.leaderDialogActive )
		self thread playLeaderDialogOnPlayer( dialog, team );
	else
		self.leaderDialogQueue[self.leaderDialogQueue.size] = dialog;
}

playLeaderDialogOnPlayer( dialog, team )
{
	self endon ( "disconnect" );
	
	if(isDefined(self.bIsBot) && self.bIsBot == true)
		return;	
	
	if( !isDefined(game["dialog"][dialog]) )
		return;
	
	self.leaderDialogActive = true;
	if ( isDefined( self.leaderDialogGroups[dialog] ) )
	{
		group = dialog;
		dialog = self.leaderDialogGroups[group];
		self.leaderDialogGroups[group] = undefined;
		self.leaderDialogGroup = group;
	}

	self playLocalSound( game["voice"][team]+game["dialog"][dialog] );

	wait ( 3.0 );
	self.leaderDialogActive = false;
	self.leaderDialogGroup = "";

	if ( self.leaderDialogQueue.size > 0 )
	{
		nextDialog = self.leaderDialogQueue[0];
		
		for ( i = 1; i < self.leaderDialogQueue.size; i++ )
			self.leaderDialogQueue[i-1] = self.leaderDialogQueue[i];
		self.leaderDialogQueue[i-1] = undefined;
		
		self thread playLeaderDialogOnPlayer( nextDialog, team );
	}
}

isExcluded( entity, entityList )
{
	for ( index = 0; index < entityList.size; index++ )
	{
		if ( entity == entityList[index] )
			return true;
	}
	return false;
}

// --- time ---

pauseTimer()
{
	if ( level.timerStopped )
		return;
	
	level.timerStopped = true;
	level.timerPauseTime = gettime();
}

getTimeRemaining()
{
	return level.timeLimit * 60 * 1000 - getTimePassed();
}

getTimePassed()
{
	if ( !isDefined( level.startTime ) )
		return 0;
	
	if ( level.timerStopped )
		return (level.timerPauseTime - level.startTime) - level.discardTime;
	else
		return (gettime()            - level.startTime) - level.discardTime;

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

DeletaOutrosSpawns( spawnlist )
{
	// deleta todos os spawns do mapa que não são usados para diminuir ents no jogo, assim tentando evitar o G_Spawn error
	
	if ( level.WarFX == 1 )
		maps\mp\gametypes\_warfx::init();
	
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

stopTickingSound()
{
	self notify("stop_ticking");
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

playTickingSound()
{
	self endon("death");
	self endon("stop_ticking");
	level endon("game_ended");
	
	while(1)
	{
		self playSound( "ui_mp_suitcasebomb_timer" );
		wait 1.0;
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