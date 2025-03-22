#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "unity", 30, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "unity", 300, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "unity", 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "unity", 0, 0, 10 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "unity", 1, 0, 1 );
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	level.onPlayerDisconnect = ::onPlayerDisconnect;	

	game["dialog"]["gametype"] = "capturehold";
	game["dialog"]["offense_obj"] = "capture_objs";
	game["dialog"]["defense_obj"] = "capture_objs";
	
	game["dialog"]["ourflag"] = "ourflag";
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	game["dialog"]["enemyflag"] = "enemyflag";
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";
	
	// sounds
	// ourflag "the enemy has our flag!"
	// ourflag_capt "the enemy captured our flag!"
	// enemyflag "we have the enemy flag!"
	// enemyflag_capt "we captured the enemy flag!"		
	
	level.LiveVIP_axis = false;
	level.LiveVIP_allies = false;
}


onPrecacheGameType()
{
	// Commander
	thread defineIcons();
	precacheShader(level.hudcommander_allies);
	precacheShader(level.hudcommander_axis);
	precacheStatusIcon( "faction_128_usmc" );
	precacheStatusIcon( "faction_128_sas" );
	precacheStatusIcon( "faction_128_arab" );
	precacheStatusIcon( "faction_128_ussr" );
	
	// Commander Sounds
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";

	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "compass_waypoint_captureneutral_a" );
	precacheShader( "compass_waypoint_capture_a" );
	precacheShader( "compass_waypoint_defend_a" );
	precacheShader( "compass_waypoint_captureneutral_b" );
	precacheShader( "compass_waypoint_capture_b" );
	precacheShader( "compass_waypoint_defend_b" );
	precacheShader( "compass_waypoint_captureneutral_c" );
	precacheShader( "compass_waypoint_capture_c" );
	precacheShader( "compass_waypoint_defend_c" );
	precacheShader( "compass_waypoint_captureneutral_d" );
	precacheShader( "compass_waypoint_capture_d" );
	precacheShader( "compass_waypoint_defend_d" );
	precacheShader( "compass_waypoint_captureneutral_e" );
	precacheShader( "compass_waypoint_capture_e" );
	precacheShader( "compass_waypoint_defend_e" );

	precacheShader( "waypoint_captureneutral" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_escort" );
	precacheShader( "waypoint_captureneutral_a" );
	precacheShader( "waypoint_capture_a" );
	precacheShader( "waypoint_defend_a" );
	precacheShader( "waypoint_captureneutral_b" );
	precacheShader( "waypoint_capture_b" );
	precacheShader( "waypoint_defend_b" );
	precacheShader( "waypoint_captureneutral_c" );
	precacheShader( "waypoint_capture_c" );
	precacheShader( "waypoint_defend_c" );
	precacheShader( "waypoint_captureneutral_d" );
	precacheShader( "waypoint_capture_d" );
	precacheShader( "waypoint_defend_d" );
	precacheShader( "waypoint_captureneutral_e" );
	precacheShader( "waypoint_capture_e" );
	precacheShader( "waypoint_defend_e" );
	
	precacheShader( "waypoint_escort" );	
	
	flagBaseFX = [];
	flagBaseFX["marines"] = "misc/ui_flagbase_silver";
	flagBaseFX["sas"    ] = "misc/ui_flagbase_black";
	flagBaseFX["russian"] = "misc/ui_flagbase_red";
	flagBaseFX["opfor"  ] = "misc/ui_flagbase_gold";
	
	//if ( !isDefined(flagBaseFX[ game[ "allies" ] ]) )
	//	return;	
	
	//level.flagBaseFXid[ "allies" ] = loadfx( flagBaseFX[ game[ "allies" ] ] );
	//level.flagBaseFXid[ "axis"   ] = loadfx( flagBaseFX[ game[ "axis"   ] ] );	
}


onStartGameType()
{	
	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_UNITY_OBJ" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_UNITY_OBJ" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_UNITY_OBJ" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_UNITY_OBJ" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_UNITY_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_UNITY_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_UNITY_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_UNITY_HINT" );

	setClientNameMode("auto_change");

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dom_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dom_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	level.spawn_all = getentarray( "mp_dom_spawn", "classname" );
	level.spawn_axis_start = getentarray("mp_dom_spawn_axis_start", "classname" );
	level.spawn_allies_start = getentarray("mp_dom_spawn_allies_start", "classname" );
	
	level.startPos["allies"] = level.spawn_allies_start[0].origin;
	level.startPos["axis"] = level.spawn_axis_start[0].origin;
	
	dist_spawns = distance( level.startPos["allies"] , level.startPos["axis"] );
	level.dist_inicial = dist_spawns / 5;	
	if ( level.script == "mp_cdi_mision_bunker" )
		level.dist_inicial = dist_spawns / 8;	
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "dom";
//	allowed[1] = "hardpoint";
	maps\mp\gametypes\_gameobjects::main(allowed);

	SetaMensagens();
		
	novos_flag_init();
		
	thread domFlags();
	thread updateDomScores();	
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "dom,tdm" );	
}


// ========================================================================
//		Spawn Captain/Soldier
// ========================================================================

onSpawnPlayer()
{
	flagsOwned = 0;
	enemyFlagsOwned = 0;
	myTeam = self.pers["team"];
	enemyTeam = getOtherTeam( myTeam );
	for ( i = 0; i < level.flags.size; i++ )
	{
		team = level.flags[i] getFlagTeam();
		if ( team == myTeam )
			flagsOwned++;
		else if ( team == enemyTeam )
			enemyFlagsOwned++;
	}

	// ------------- calcula spawns -------------
	
	spawnpoint = undefined;
	
	if ( !level.useStartSpawns )
	{
		if ( flagsOwned == level.flags.size )
		{
			// own all flags! pretend we don't own the last one we got, so enemies can spawn there
			enemyBestSpawnFlag = level.bestSpawnFlag[ getOtherTeam( self.pers["team"] ) ];
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, getSpawnsBoundingFlag( enemyBestSpawnFlag ) );
		}
		else if ( flagsOwned > 0 )
		{
			// spawn near any flag we own that's nearish something we can capture
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, getBoundaryFlagSpawns( myTeam ) );
		}
		else
		{
			// own no flags!
			bestFlag = undefined;
			if ( enemyFlagsOwned > 0 && enemyFlagsOwned < level.flags.size )
			{
				// there should be an unowned one to use
				bestFlag = getUnownedFlagNearestStart( myTeam );
			}
			if ( !isdefined( bestFlag ) )
			{
				// pretend we still own the last one we lost
				bestFlag = level.bestSpawnFlag[ self.pers["team"] ];
			}
			level.bestSpawnFlag[ self.pers["team"] ] = bestFlag;
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, bestFlag.nearbyspawns );
		}
	}
	
	if ( !isdefined( spawnpoint ) )
	{
		if (self.pers["team"] == "axis")
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_axis_start);
		else
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_allies_start);
	}
	
	//spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all );
	

	// ------------- captain/soldado -------------	
	

	// deleta skin do commander se sobrou do round anterior
	if ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP" )
		VIPloadModelBACK();
	
	if (self.pers["team"] == "axis")	
	{
		if ( level.LiveVIP_axis == false )
		{
			level.LiveVIP_axis = true;	
			SpawnVIP( "axis" );
		}
		else
			SpawnSoldado();
	}
	else
	{
		if ( level.LiveVIP_allies == false )
		{
			level.LiveVIP_allies = true;	
			SpawnVIP( "allies" );
		}
		else
			SpawnSoldado();
	}
	
	// ------------- spawn -------------
	
	assert( isDefined(spawnpoint) );

	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( flagsOwned < enemyFlagsOwned )
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_all);
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		}
		else
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn(spawnpoint.origin, spawnpoint.angles);
		}
	}
	else
		self spawn(spawnpoint.origin, spawnpoint.angles);	
}

SpawnVIP( team )
{
	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
		self iPrintLnbold( level.unity_captain );
	
	self thread createVipIcon( self.team );

	// troca a skin pra VIP/Commander
	VIPloadModel();
	
	// icone defend!
	thread CriaTriggers( team, self );		
}

CriaTriggers( team, player )
{
	while ( !self.hasSpawned )
		wait ( 0.1 );

	wait ( 0.1 );
	pos = player.origin + (0,0,-60);

	if ( team == "axis" )
	{
		if ( !isDefined ( level.Docs_ax ) )
		{
			docs["pasta_trigger"] = spawn( "trigger_radius", pos, 0, 20, 100 );
			docs["pasta"][0] = spawn( "script_model", pos);
			docs["zone_trigger"] = spawn( "trigger_radius", pos, 0, 50, 100 );	
			level.Docs_ax = SpawnDocs_ax( docs["pasta_trigger"], docs["pasta"] );	
		}
		else
		{
			level.Docs_ax.trigger.origin = pos;
			level.Docs_ax maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
			level.Docs_ax maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );		
		}		
		level.Docs_ax maps\mp\gametypes\_gameobjects::setPickedUp( player );
	}	
	else
	{
		if ( !isDefined ( level.Docs_al ) )
		{
			docs["pasta_trigger"] = spawn( "trigger_radius", pos, 0, 20, 100 );
			docs["pasta"][0] = spawn( "script_model", pos);
			docs["zone_trigger"] = spawn( "trigger_radius", pos, 0, 50, 100 );	
			level.Docs_al = SpawnDocs_al( docs["pasta_trigger"], docs["pasta"] );	
		}
		else
		{
			level.Docs_al.trigger.origin = pos;
			level.Docs_al maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
			level.Docs_al maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );		
		}	
		level.Docs_al maps\mp\gametypes\_gameobjects::setPickedUp( player );	
	}
	
	if( isDefined(player.bIsBot) && player.bIsBot) 
	{
		wait 2;
		player TakeAllWeapons();
		player.weaponPrefix = "m4_reflex_mp";
		player.pers["weapon"] = "m4_reflex_mp";
	}		
}

SpawnDocs_ax( trigger, visuals )
{
	pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( "axis", trigger, visuals, (0,0,100) );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_escort" );
	pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
	pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );

	pastaObject.onPickup = ::onPickupDocs;	   
	pastaObject.onDrop = ::onDropDocs_ax;
	pastaObject.allowWeapons = true;
	   
	return pastaObject;	
}

onDropDocs_ax( player )
{
	level.Docs_ax maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	level.Docs_ax maps\mp\gametypes\_gameobjects::allowCarry( "none" );
}

SpawnDocs_al( trigger, visuals )
{
	pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( "allies", trigger, visuals, (0,0,100) );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_escort" );
	pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
	pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );

	pastaObject.onPickup = ::onPickupDocs;		   
	pastaObject.onDrop = ::onDropDocs_al;
	pastaObject.allowWeapons = true;
	   
	return pastaObject;	
}

onDropDocs_al( player )
{
	level.Docs_al maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	level.Docs_al maps\mp\gametypes\_gameobjects::allowCarry( "none" );
}

onPickupDocs( player )
{
	team = player.pers["team"];
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
}


SpawnSoldado()
{
	self.isCommander = false;

	if ( self.pers["team"] == "axis" )
	{
		if ( level.SidesMSG == 1 )
		{
			if ( getTeamFlagCount( "axis" ) == level.flags.size )
				self iPrintLnbold( level.unity_kill );
			else
				self iPrintLnbold( level.unity_escort );
		}
	}
	else if ( self.pers["team"] == "allies" )
	{
		if ( level.SidesMSG == 1 )
		{
			if ( getTeamFlagCount( "allies" ) == level.flags.size )
				self iPrintLnbold( level.unity_kill );
			else
				self iPrintLnbold( level.unity_escort );
		}			
	}
}

VIPloadModel()
{
	// salva classe original
	self.class_original = self.pers["class"];

	self.pers["class"] = "CLASS_COMMANDER";
	self.class = "CLASS_COMMANDER";
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
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

CommanderDead()
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		temp_win = "";
		seu_time = self.pers["team"];

		// deixa de ser vip/commander
		self.isCommander = false;
		
		if ( isDefined( self.carryIcon ) )
			self.carryIcon destroyElem();		

		// diz q nao tem mais vip/Commander vivo
		if ( seu_time == "axis" )
		{
			level.LiveVIP_axis = false;
			numFlags = getTeamFlagCount( "allies" );
			temp_win = "allies";
		}
		else
		{
			level.LiveVIP_allies = false;
			numFlags = getTeamFlagCount( "axis" );
			temp_win = "axis";
		}
		
		// se seu time está sem bandeiras, já era!
		if ( numFlags == level.flags.size )
		{
			if ( temp_win == "allies" )
			{
				[[level._setTeamScore]]( "allies", [[level._getTeamScore]]( "allies" ) + [[level._getTeamScore]]( "axis" ) );
				[[level._setTeamScore]]( "axis", 0 );
			}
			else
			{
				[[level._setTeamScore]]( "axis", [[level._getTeamScore]]( "axis" ) + [[level._getTeamScore]]( "allies" ) );
				[[level._setTeamScore]]( "allies", 0 );
			}
			
			// sounds
			maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], level.otherTeam[seu_time] );
			maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], seu_time );
	
			level notify("vip_is_dead");
			setGameEndTime( 0 );
			thread maps\mp\gametypes\_globallogic::endGame( temp_win, level.unity_dead );
		}
	}
}

onPlayerDisconnect()
{
	// o prox a dar respawn será o novo Commander
	if ( isDefined( self.isCommander ) )
	{
		if ( self.isCommander == true )
		{
			if ( self.pers["team"] == "axis" )
				level.LiveVIP_axis = false;
			else
				level.LiveVIP_allies = false;
			
			self.isCommander = false;
		}
	}
}

defineIcons()
{
	// seta commander icons
	if( game["allies"] == "marines" )
	{
		level.hudcommander_allies = "faction_128_usmc";
	}
	else
	{
		level.hudcommander_allies = "faction_128_sas";
	}
	
	if( game["axis"] == "russian" )
	{
		level.hudcommander_axis = "faction_128_ussr";
	}
	else
	{
		level.hudcommander_axis = "faction_128_arab";
	}
}

createVipIcon( team )
{
	if( team == "allies" )
	{
		self.carryIcon = createIcon( level.hudcommander_allies, 50, 50 );
		status_icon = level.hudcommander_allies;
	}
	else
	{
		self.carryIcon = createIcon( level.hudcommander_axis, 50, 50 );
		status_icon = level.hudcommander_axis;
	}				
	
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
	
	// carrega icon no placar
	self.statusicon = status_icon;	
}


// ========================================================================
//		Flags
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
	

	
	precacheString( &"MP_CAPTURING_FLAG" );
	precacheString( &"MP_LOSING_FLAG" );
	//precacheString( &"MP_LOSING_LAST_FLAG" );
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
		
	if ( level.novos_objs )
		move_flag();		
	
	level.domFlags = [];
	for ( index = 0; index < level.flags.size; index++ )
	{
		trigger = level.flags[index];
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

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( 10.0 );
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
		label = domFlag maps\mp\gametypes\_gameobjects::getLabel();
		domFlag.label = label;
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_captureneutral" + label );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_captureneutral" + label );
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
		
//		makeDvarServerInfo( "scr_obj" + label, "neutral" );
//		makeDvarServerInfo( "scr_obj" + label + "_flash", 0 );
//		setDvar( "scr_obj" + label, "neutral" );
//		setDvar( "scr_obj" + label + "_flash", 0 );

		// legacy spawn code support
		level.flags[index].useObj = domFlag;
		level.flags[index].adjflags = [];
		level.flags[index].nearbyspawns = [];
		
		domFlag.levelFlag = level.flags[index];
		
		level.domFlags[level.domFlags.size] = domFlag;
	}
	
	// level.bestSpawnFlag is used as a last resort when the enemy holds all flags.
	level.bestSpawnFlag = [];
	level.bestSpawnFlag[ "allies" ] = getUnownedFlagNearestStart( "allies", undefined );
	level.bestSpawnFlag[ "axis" ] = getUnownedFlagNearestStart( "axis", level.bestSpawnFlag[ "allies" ] );
	
	flagSetup();
}

getUnownedFlagNearestStart( team, excludeFlag )
{
	best = undefined;
	bestdistsq = undefined;
	for ( i = 0; i < level.flags.size; i++ )
	{
		flag = level.flags[i];
		
		if ( flag getFlagTeam() != "neutral" )
			continue;
		
		distsq = distanceSquared( flag.origin, level.startPos[team] );
		if ( (!isDefined( excludeFlag ) || flag != excludeFlag) && (!isdefined( best ) || distsq < bestdistsq) )
		{
			bestdistsq = distsq;
			best = flag;
		}
	}
	return best;
}

onBeginUse( player )
{
	while ( level.inPrematchPeriod )
		wait 1;
		
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 1 );	
	self.didStatusNotify = false;

	if ( ownerTeam == "neutral" )
	{
		if ( self.label != "_d" && self.label != "_e" )
		{
			statusDialog( "securing"+self.label, player.pers["team"] );
		}
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
	while ( level.inPrematchPeriod )
		wait 1;
		
	if ( progress > 0.05 && change && !self.didStatusNotify )
	{
		ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
		if ( ownerTeam == "neutral" )
		{
			if ( self.label != "_d" && self.label != "_e" )
				statusDialog( "securing"+self.label, team );
			else
				statusDialog( "enemyflag", team );	
		}
		else
		{
			if ( self.label != "_d" && self.label != "_e" )
			{
				statusDialog( "losing"+self.label, ownerTeam );
				statusDialog( "securing"+self.label, team );
			}
			else
			{
				statusDialog( "ourflag", ownerTeam );
				statusDialog( "enemyflag", team );			
			}
		}

		self.didStatusNotify = true;
	}
}


statusDialog( dialog, team )
{
	time = getTime();
	if ( getTime() < level.lastStatus[team] + 6000 )
		return;
		
	thread delayedLeaderDialog( dialog, team );
	level.lastStatus[team] = getTime();	
}


onEndUse( team, player, success )
{
	while ( level.inPrematchPeriod )
		wait 1;
		
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 0 );

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
}


resetFlagBaseEffect()
{
	if ( isdefined( self.baseeffect ) )
		self.baseeffect delete();
	
	team = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	
	if ( team != "axis" && team != "allies" )
		return;
	
	fxid = level.flagBaseFXid[ team ];

	self.baseeffect = spawnFx( fxid, self.baseeffectpos, self.baseeffectforward, self.baseeffectright );
	triggerFx( self.baseeffect );
}

onUse( player )
{
	while ( level.inPrematchPeriod )
		wait 1;
		
	team = player.pers["team"];
	oldTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	label = self maps\mp\gametypes\_gameobjects::getLabel();
	
	player logString( "flag captured: " + self.label );
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
	self.visuals[0] setModel( game["flagmodels"][team] );
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel(), team );	
	
	//self resetFlagBaseEffect();
	
	level.useStartSpawns = false;
	
	assert( team != "neutral" );
	
	if ( oldTeam == "neutral" )
	{
		otherTeam = getOtherTeam( team );
		thread printAndSoundOnEveryone( team, otherTeam, &"MP_NEUTRAL_FLAG_CAPTURED_BY", &"MP_NEUTRAL_FLAG_CAPTURED_BY", "mp_war_objective_taken", undefined, player );
		
		if ( self.label != "_d" && self.label != "_e" )
		{
			statusDialog( "secured"+self.label, team );
			statusDialog( "enemy_has"+self.label, otherTeam );
		}		
		else
		{
			statusDialog( "enemyflag_capt", team );
			statusDialog( "ourflag_capt", otherTeam );			
		}
	}
	else
	{
		thread printAndSoundOnEveryone( team, oldTeam, &"MP_ENEMY_FLAG_CAPTURED_BY", &"MP_FRIENDLY_FLAG_CAPTURED_BY", "mp_war_objective_taken", "mp_war_objective_lost", player );
		
//		thread delayedLeaderDialogBothTeams( "obj_lost", oldTeam, "obj_taken", team );

		if ( getTeamFlagCount( team ) == level.flags.size )
		{
			statusDialog( "secure_all", team );
			statusDialog( "lost_all", oldTeam );
		}
		else
		{	
			if ( self.label != "_d" && self.label != "_e" )
			{
				statusDialog( "secured"+self.label, team );
				statusDialog( "lost"+self.label, oldTeam );
			}
			else
			{
				statusDialog( "enemyflag_capt", team );
				statusDialog( "ourflag_capt", oldTeam );			
			}
		}
		
		level.bestSpawnFlag[ oldTeam ] = self.levelFlag;
	}

	thread giveFlagCaptureXP( self.touchList[team] );
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


updateDomScores()
{
	// disable score limit check to allow both axis and allies score to be processed
	level.endGameOnScoreLimit = false;

	while ( !level.gameEnded )
	{
		numFlags = getTeamFlagCount( "allies" );
		if ( numFlags )
			[[level._setTeamScore]]( "allies", [[level._getTeamScore]]( "allies" ) + numFlags );

		numFlags = getTeamFlagCount( "axis" );
		if ( numFlags )
			[[level._setTeamScore]]( "axis", [[level._getTeamScore]]( "axis" ) + numFlags );

		level.endGameOnScoreLimit = true;
		maps\mp\gametypes\_globallogic::checkScoreLimit();
		level.endGameOnScoreLimit = false;
		wait ( 5.0 );
	}
}


onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( self.touchTriggers.size && isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] )
	{
		triggerIds = getArrayKeys( self.touchTriggers );
		ownerTeam = self.touchTriggers[triggerIds[0]].useObj.ownerTeam;
		team = self.pers["team"];
		
		if ( team == ownerTeam )
		{
			attacker thread [[level.onXPEvent]]( "assault" );
			maps\mp\gametypes\_globallogic::givePlayerScore( "assault", attacker );
		}
		else
		{
			attacker thread [[level.onXPEvent]]( "defend" );
			maps\mp\gametypes\_globallogic::givePlayerScore( "defend", attacker );
		}
	}
	
	// testa captain!
	CommanderDead();
}



getTeamFlagCount( team )
{
	score = 0;
	for (i = 0; i < level.flags.size; i++) 
	{
		if ( level.domFlags[i] maps\mp\gametypes\_gameobjects::getOwnerTeam() == team )
			score++;
	}	
	return score;
}

getFlagTeam()
{
	return self.useObj maps\mp\gametypes\_gameobjects::getOwnerTeam();
}

getBoundaryFlags()
{
	// get all flags which are adjacent to flags that aren't owned by the same team
	bflags = [];
	for (i = 0; i < level.flags.size; i++)
	{
		for (j = 0; j < level.flags[i].adjflags.size; j++)
		{
			if (level.flags[i].useObj maps\mp\gametypes\_gameobjects::getOwnerTeam() != level.flags[i].adjflags[j].useObj maps\mp\gametypes\_gameobjects::getOwnerTeam() )
			{
				bflags[bflags.size] = level.flags[i];
				break;
			}
		}
	}
	
	return bflags;
}

getBoundaryFlagSpawns(team)
{
	spawns = [];
	
	bflags = getBoundaryFlags();
	for (i = 0; i < bflags.size; i++)
	{
		if (isdefined(team) && bflags[i] getFlagTeam() != team)
			continue;
		
		for (j = 0; j < bflags[i].nearbyspawns.size; j++)
			spawns[spawns.size] = bflags[i].nearbyspawns[j];
	}
	
	return spawns;
}

getSpawnsBoundingFlag( avoidflag )
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		flag = level.flags[i];
		if ( flag == avoidflag )
			continue;
		
		isbounding = false;
		for (j = 0; j < flag.adjflags.size; j++)
		{
			if ( flag.adjflags[j] == avoidflag )
			{
				isbounding = true;
				break;
			}
		}
		
		if ( !isbounding )
			continue;
		
		for (j = 0; j < flag.nearbyspawns.size; j++)
			spawns[spawns.size] = flag.nearbyspawns[j];
	}
	
	return spawns;
}

// gets an array of all spawnpoints which are near flags that are
// owned by the given team, or that are adjacent to flags owned by the given team.
getOwnedAndBoundingFlagSpawns(team)
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		if ( level.flags[i] getFlagTeam() == team )
		{
			// add spawns near this flag
			for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
				spawns[spawns.size] = level.flags[i].nearbyspawns[s];
		}
		else
		{
			for (j = 0; j < level.flags[i].adjflags.size; j++)
			{
				if ( level.flags[i].adjflags[j] getFlagTeam() == team )
				{
					// add spawns near this flag
					for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
						spawns[spawns.size] = level.flags[i].nearbyspawns[s];
					break;
				}
			}
		}
	}
	
	return spawns;
}

// gets an array of all spawnpoints which are near flags that are
// owned by the given team
getOwnedFlagSpawns(team)
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		if ( level.flags[i] getFlagTeam() == team )
		{
			// add spawns near this flag
			for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
				spawns[spawns.size] = level.flags[i].nearbyspawns[s];
		}
	}
	
	return spawns;
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
	
	if (maperrors.size == 0)
	{
		// find adjacent flags
		for (i = 0; i < flags.size; i++)
		{
			if (isdefined(flags[i].descriptor.script_linkto))
				adjdescs = strtok(flags[i].descriptor.script_linkto, " ");
			else
				adjdescs = [];
			for (j = 0; j < adjdescs.size; j++)
			{
				otherdesc = descriptorsByLinkname[adjdescs[j]];
				if (!isdefined(otherdesc) || otherdesc.targetname != "flag_descriptor") {
					maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + flags[i].descriptor.script_linkname + "\" linked to \"" + adjdescs[j] + "\" which does not exist as a script_linkname of any other entity with a targetname of flag_descriptor (or, if it does, that flag_descriptor has not been assigned to a flag)";
					continue;
				}
				adjflag = otherdesc.flag;
				if (adjflag == flags[i]) {
					maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + flags[i].descriptor.script_linkname + "\" linked to itself";
					continue;
				}
				flags[i].adjflags[flags[i].adjflags.size] = adjflag;
			}
		}
	}
	
	// assign each spawnpoint to nearest flag
	spawnpoints = getentarray("mp_dom_spawn", "classname");
	for (i = 0; i < spawnpoints.size; i++)
	{
		if (isdefined(spawnpoints[i].script_linkto)) {
			desc = descriptorsByLinkname[spawnpoints[i].script_linkto];
			if (!isdefined(desc) || desc.targetname != "flag_descriptor") {
				maperrors[maperrors.size] = "Spawnpoint at " + spawnpoints[i].origin + "\" linked to \"" + spawnpoints[i].script_linkto + "\" which does not exist as a script_linkname of any entity with a targetname of flag_descriptor (or, if it does, that flag_descriptor has not been assigned to a flag)";
				continue;
			}
			nearestflag = desc.flag;
		}
		else {
			nearestflag = undefined;
			nearestdist = undefined;
			for (j = 0; j < flags.size; j++)
			{
				dist = distancesquared(flags[j].origin, spawnpoints[i].origin);
				if (!isdefined(nearestflag) || dist < nearestdist)
				{
					nearestflag = flags[j];
					nearestdist = dist;
				}
			}
		}
		nearestflag.nearbyspawns[nearestflag.nearbyspawns.size] = spawnpoints[i];
	}
	
	if (maperrors.size > 0)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");
		
		maps\mp\_utility::error("Map errors. See above");
		//SetDvar( "fl", "war" );
		
		//return;
	}
}

// ========================================================================
//		Mensagens
// ========================================================================

SetaMensagens()
{
	if ( getDvar( "scr_unity_captain" ) == "" )
	{
		level.unity_captain =  "^7You are the ^9Captain^7!";
	}
	else
	{
		level.unity_captain = getDvar( "scr_unity_captain" );
	}
	
	if ( getDvar( "scr_unity_escort" ) == "" )
	{
		level.unity_escort =  "^7Escort the ^9Captain^7!";
	}
	else
	{
		level.unity_escort = getDvar( "scr_unity_escort" );
	}	

	if ( getDvar( "scr_unity_kill" ) == "" )
	{
		level.unity_kill =  "^7Kill the ^9Captain^7!";
	}
	else
	{
		level.unity_kill = getDvar( "scr_unity_kill" );
	}

	if ( getDvar( "scr_unity_dead" ) == "" )
	{
		level.unity_dead =  "^7The ^3Captain ^7is Dead!";
	}
	else
	{
		level.unity_dead = getDvar( "scr_unity_dead" );
	}
}

// ============ RANDOM =======================

novos_flag_init()
{
	level.novos_objs = true;

	temp = GetDvar ( "xflag_" + 0 );
	if ( temp == "" )
	{
		level.novos_objs = false;	
		return;
	}
	
	xflag(); // cria listas com pos
		
	StartNewFlags(); //	cria novas flags
}

xflag()
{
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
		
	level.NumFlagsOri = level.flags.size;
		
	level.xflag_a = [];
	level.xflag_b = [];
	level.xflag_c = [];
	if ( level.NumFlagsOri > 3 )
		level.xflag_d = [];
	if ( level.NumFlagsOri > 4 )
		level.xflag_e = [];	
			
	level.xflag_selected = [];
	
	flag_a = level.flags[0];
	flag_b = level.flags[1];
	flag_c = level.flags[2];
	if ( level.NumFlagsOri > 3 )
		flag_d = level.flags[3];
	else
		flag_d = undefined;		
	if ( level.NumFlagsOri > 4 )	
		flag_e = level.flags[4];
	else
		flag_e = undefined;		
		
	
	level.xflag_a[0] = flag_a.origin + (0, 0, 60);
	level.xflag_b[0] = flag_b.origin + (0, 0, 60);
	level.xflag_c[0] = flag_c.origin + (0, 0, 60);
	if ( level.NumFlagsOri > 3 && isDefined(flag_d) )
		level.xflag_d[0] = flag_d.origin + (0, 0, 60);
	if ( level.NumFlagsOri > 4 && isDefined(flag_e) )
		level.xflag_e[0] = flag_e.origin + (0, 0, 60);

	level.flags = [];

	gerando = true;
	index = 0;
	
	// 3 flags
	if ( level.NumFlagsOri == 3 )	
	{
		while (gerando)
		{
			temp = GetDvar ( "xflag_" + index );
			if ( temp == "eof" )
				gerando = false;
			else
			{
				temp = strtok( temp, "," );
				pos = (int(temp[0]),int(temp[1]),int(temp[2]));
							
				if ( ( distance( pos, flag_a.origin) < distance( pos, flag_b.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_c.origin) )
				)
					level.xflag_a[level.xflag_a.size] = pos;
				else if ( ( distance( pos, flag_b.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_c.origin) )
						)
						level.xflag_b[level.xflag_b.size] = pos;
				else 
					level.xflag_c[level.xflag_c.size] = pos;
					
			}	
			index++;
		}
	}
	// 4 flags
	else if ( level.NumFlagsOri == 4 )	
	{
		while (gerando)
		{
			temp = GetDvar ( "xflag_" + index );
			if ( temp == "eof" )
				gerando = false;
			else
			{
				temp = strtok( temp, "," );
				pos = (int(temp[0]),int(temp[1]),int(temp[2]));
							
				if ( ( distance( pos, flag_a.origin) < distance( pos, flag_b.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_c.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_d.origin) )
				)
					level.xflag_a[level.xflag_a.size] = pos;
				else if ( ( distance( pos, flag_b.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_c.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_d.origin) )
						)
						level.xflag_b[level.xflag_b.size] = pos;
				else if ( ( distance( pos, flag_c.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_b.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_d.origin) )
						)
						level.xflag_c[level.xflag_c.size] = pos;
				else 
					level.xflag_d[level.xflag_d.size] = pos;					
					
			}	
			index++;
		}
	}	
	// 5 flags
	else if ( level.NumFlagsOri == 5 )	
	{
		while (gerando)
		{
			temp = GetDvar ( "xflag_" + index );
			if ( temp == "eof" )
				gerando = false;
			else
			{
				temp = strtok( temp, "," );
				pos = (int(temp[0]),int(temp[1]),int(temp[2]));
							
				if ( ( distance( pos, flag_a.origin) < distance( pos, flag_b.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_c.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_d.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_e.origin) )
				)
					level.xflag_a[level.xflag_a.size] = pos;
				else if ( ( distance( pos, flag_b.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_c.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_d.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_e.origin) )
						)
						level.xflag_b[level.xflag_b.size] = pos;
				else if ( ( distance( pos, flag_c.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_b.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_d.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_e.origin) )
						)
						level.xflag_c[level.xflag_c.size] = pos;
				else if ( ( distance( pos, flag_d.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_d.origin) < distance( pos, flag_b.origin) ) &&
			     		( distance( pos, flag_d.origin) < distance( pos, flag_c.origin) ) &&
			     		( distance( pos, flag_d.origin) < distance( pos, flag_e.origin) )
						)
						level.xflag_d[level.xflag_d.size] = pos;
				else 
					level.xflag_e[level.xflag_e.size] = pos;								
			}	
			index++;
		}
	}	
	
	// escolhe flags ABC
	
	if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
	{
		id_a = RandomInt(level.xflag_a.size);
		while ( ObjValido(level.xflag_a[id_a]) == false )
		{
			id_a = RandomInt(level.xflag_a.size);
			logprint( "======================== Não Válido A!!! " + "\n");
		}
		level.xflag_selected[0] = level.xflag_a[id_a];
		level.xflag_a = removeFlagArray(level.xflag_a, id_a);	
		
		id_b = RandomInt(level.xflag_b.size);
		while ( ObjValido(level.xflag_b[id_b]) == false )
		{
			id_b = RandomInt(level.xflag_b.size);
			logprint( "======================== Não Válido B!!! " + "\n");
		}
		level.xflag_selected[1] = level.xflag_b[id_b];
		level.xflag_b = removeFlagArray(level.xflag_b, id_b);	
		
		id_c = RandomInt(level.xflag_c.size);
		while ( ObjValido(level.xflag_c[id_c]) == false )
		{
			id_c = RandomInt(level.xflag_c.size);
			logprint( "======================== Não Válido C!!! " + "\n");
		}
		level.xflag_selected[2] = level.xflag_c[id_c];
		level.xflag_c = removeFlagArray(level.xflag_c, id_c);
		
		if ( level.NumFlagsOri > 3 )
		{
			id_d = RandomInt(level.xflag_d.size);
			while ( ObjValido(level.xflag_d[id_d]) == false )
			{
				id_d = RandomInt(level.xflag_d.size);
				logprint( "======================== Não Válido D!!! " + "\n");
			}			
			level.xflag_selected[3] = level.xflag_d[id_d];
			level.xflag_d = removeFlagArray(level.xflag_d, id_d);	
		}	
		if ( level.NumFlagsOri > 4 )
		{
			id_e = RandomInt(level.xflag_e.size);
			while ( ObjValido(level.xflag_e[id_e]) == false )
			{
				id_e = RandomInt(level.xflag_e.size);
				logprint( "======================== Não Válido E!!! " + "\n");
			}			
			level.xflag_selected[4] = level.xflag_e[id_e];
			level.xflag_e = removeFlagArray(level.xflag_e, id_e);	
		}							
		
	}		
	else
	{
		id_a = RandomInt(level.xflag_a.size);
		level.xflag_selected[0] = level.xflag_a[id_a];
		level.xflag_a = removeFlagArray(level.xflag_a, id_a);
		
		id_b = RandomInt(level.xflag_b.size);
		level.xflag_selected[1] = level.xflag_b[id_b];
		level.xflag_b = removeFlagArray(level.xflag_b, id_b);
		
		id_c = RandomInt(level.xflag_c.size);
		level.xflag_selected[2] = level.xflag_c[id_c];
		level.xflag_c = removeFlagArray(level.xflag_c, id_c);	
		
		if ( level.NumFlagsOri > 3 )
		{
			id_d = RandomInt(level.xflag_d.size);
			level.xflag_selected[3] = level.xflag_d[id_d];
			level.xflag_d = removeFlagArray(level.xflag_d, id_d);	
		}
		
		if ( level.NumFlagsOri > 4 )
		{
			id_e = RandomInt(level.xflag_e.size);
			level.xflag_selected[4] = level.xflag_e[id_e];
			level.xflag_e = removeFlagArray(level.xflag_e, id_e);	
		}
	}
}

StartNewFlags()
{
	thread update_linkName();	
	
	level.labels = [];
	level.labels[0] = "a";
	level.labels[1] = "b";
	level.labels[2] = "c";
	level.labels[3] = "d";
	level.labels[4] = "e";
		
	thread update_linkTo();


	NewFlags = randomInt(3); // decide se vão ter +3 flags
	
	if ( level.NumFlagsOri == 4 )
		NewFlags = randomInt(2); // fica com 4 ou vai pra 5
	else if ( level.NumFlagsOri == 5 )
		NewFlags = 0; // com 5 fica com 5 sempre!
	
	//NewFlags = 2; // teste forçar sempre 2
	
	if ( NewFlags > 0 )
	{
		level.newFlags = [];
		DecideFlagsEF(NewFlags);
	
		exec_add( NewFlags );
	}
}

DecideFlagsEF(num)
{
	while ( num > 0 )
	{
		level.newFlags[level.newFlags.size] = CalculaDist();	
		num--;
	}
}

CalculaDist()
{
	while(1)
	{
		Lista = randomInt(3);
		
		pode = true;

		if ( Lista == 0 ) // A
		{
			id_a = RandomInt(level.xflag_a.size);

			nova =  level.xflag_a[id_a];		
			//nova = (int(nova[0]),int(nova[1]),int(nova[2]));		
			
			for ( i = 0; i < level.xflag_selected.size; i++ )
			{			
				velha = level.xflag_selected[i];
				//velha = (int(velha[0]),int(velha[1]),int(velha[2]));	
					
				if ( distance( nova, velha ) < level.dist_inicial )
					pode = false;
				if ( isDefined(level.newFlags[0]) )
				{
					flag_E = level.newFlags[0];
					if ( distance( nova, flag_E ) < level.dist_inicial )
						pode = false;
				}
			}
			
			if ( pode == true )
			{
				level.xflag_a = removeFlagArray(level.xflag_a, id_a);
				return nova;
			}
		}
		else if ( Lista == 1 ) // B
		{
			id_b = RandomInt(level.xflag_b.size);

			nova =  level.xflag_b[id_b];		
			//nova = (int(nova[0]),int(nova[1]),int(nova[2]));		

			for ( i = 0; i < level.xflag_selected.size; i++ )
			{			
				velha = level.xflag_selected[i];
				//velha = (int(velha[0]),int(velha[1]),int(velha[2]));
						
				if ( distance( nova, velha ) < level.dist_inicial )
					pode = false;
				if ( isDefined(level.newFlags[0]) )
				{
					flag_E = level.newFlags[0];
					if ( distance( nova, flag_E ) < level.dist_inicial )
						pode = false;
				}					
			}
			if ( pode == true )
			{
				level.xflag_b = removeFlagArray(level.xflag_b, id_b);
				return nova;
			}					
		}
		else if ( Lista == 2 ) // C
		{
			id_c = RandomInt(level.xflag_c.size);
			
			nova =  level.xflag_c[id_c];		
			//nova = (int(nova[0]),int(nova[1]),int(nova[2]));		
			
			for ( i = 0; i < level.xflag_selected.size; i++ )
			{			
				velha = level.xflag_selected[i];
				//velha = (int(velha[0]),int(velha[1]),int(velha[2]));			

				if ( distance( nova, velha ) < level.dist_inicial )
					pode = false;
				if ( isDefined(level.newFlags[0]) )
				{
					flag_E = level.newFlags[0];
					if ( distance( nova, flag_E ) < level.dist_inicial )
						pode = false;
				}					
			}				
			if ( pode == true )
			{
				level.xflag_c = removeFlagArray(level.xflag_c, id_c);
				return nova;
			}			
		}
	}
}

exec_add( num )
{
	label = [];
	if ( num  == 1 )
	{
		label[0] = "d";
	}
	else if ( num  == 2 )
	{
		label[0] = "d";
		label[1] = "e";
	}
	
	flags = getentarray( "flag_primary", "targetname" );
	
	count = 4;
	for(i=0 ; i<label.size ; i++)
	{
			if ( !isDefined(level.newFlags[i]) )
				continue;

			pos = level.newFlags[i];
			pos = (int(pos[0]),int(pos[1]),int(pos[2]));				
	
			new_origin = pos + (0, 0, -60);
			new_angles = (0,-90,0);
			
			flag = spawn( "trigger_radius", new_origin, count, 160, 128 );
			flag.origin = new_origin;
			flag.angles = new_angles;
			flag.script_gameobjectname = "dom onslaught";
			flag.targetname = "flag_primary";
			
			new_label = label[i];
	
			flag.script_label = "_"+new_label;
			
			descriptor = spawn( "script_origin", new_origin, count );
			descriptor.origin = new_origin;
			descriptor.script_linkName = "flag"+(i+(flags.size+1));
			descriptor.script_linkTo = "flag"+((i+(flags.size+1))-1);
			descriptor.targetname = "flag_descriptor";
			count++;
	}
}

move_flag()
{
	exeflag( level.xflag_selected[0], 0 );
	exeflag( level.xflag_selected[1], 1 );
	exeflag( level.xflag_selected[2], 2 );
	if ( level.NumFlagsOri > 3 )
		exeflag( level.xflag_selected[3], 3 );
	if ( level.NumFlagsOri > 4 )
		exeflag( level.xflag_selected[4], 4 );
	
	/*
	if ( NewFlags == 0 ) // não tem +3, mapas com +3 tem q ser removidas!
	{
		if ( level.flags.size == 5 )
			level.flags = removeFlagArray(level.flags, 4);
		if ( level.flags.size == 4 )
			level.flags = removeFlagArray(level.flags, 3);
	}
	*/
}

exeflag( pos, flag )
{
	trig_a = undefined;
	trig_b = undefined;
	trig_c = undefined;
	trig_d = undefined;
	trig_e = undefined;
	
	pos = (int(pos[0]),int(pos[1]),int(pos[2]));
	
	for(i=0 ; i<level.flags.size ; i++)
	{
		if ( i == 0 )
			trig_a = level.flags[i];
		else if ( i == 1 ) 
			trig_b = level.flags[i];
		else if ( i == 2 ) 
			trig_c = level.flags[i];
		else if ( i == 3 ) 
			trig_d = level.flags[i];
		else if ( i == 4 ) 
			trig_e = level.flags[i];
		
		/*			
		if( level.flags[i].script_label == "_a" )
			trig_a = level.flags[i];
		else if( level.flags[i].script_label == "_b" )
			trig_b = level.flags[i];
		else if( level.flags[i].script_label == "_c" )
			trig_c = level.flags[i];
		else if( level.flags[i].script_label == "_d" )
			trig_d = level.flags[i];
		else if( level.flags[i].script_label == "_e" )
			trig_e = level.flags[i];			
		*/
	}
	
	if ( flag == 0 ) // a
	{
		obj_a_origin = pos + (0, 0, -60);
	
		trig_a.origin = obj_a_origin;
		
		if ( isDefined( trig_a.target ) )
		{
			a_obj_entire = getent( trig_a.target, "targetname" );
			a_obj_entire.origin = obj_a_origin;
		}
	}
	else if ( flag == 1 ) // b
	{
		obj_b_origin = pos + (0, 0, -60);
	
		trig_b.origin = obj_b_origin;
		
		if ( isDefined( trig_b.target ) )
		{
			b_obj_entire = getent( trig_b.target, "targetname" );
			b_obj_entire.origin = obj_b_origin;		
		}
	}
	else if ( flag == 2 ) // c
	{
		obj_c_origin = pos + (0, 0, -60);
	
		trig_c.origin = obj_c_origin;
		
		if ( isDefined( trig_c.target ) )
		{
			c_obj_entire = getent( trig_c.target, "targetname" );
			c_obj_entire.origin = obj_c_origin;		
		}
	}	
	else if ( flag == 3 ) // d
	{
		obj_d_origin = pos + (0, 0, -60);
	
		trig_d.origin = obj_d_origin;
		
		if ( isDefined( trig_d.target ) )
		{
			d_obj_entire = getent( trig_d.target, "targetname" );
			d_obj_entire.origin = obj_d_origin;		
		}
	}		
	else if ( flag == 4 ) // e
	{
		obj_e_origin = pos + (0, 0, -60);
	
		trig_e.origin = obj_e_origin;
		
		if ( isDefined( trig_e.target ) )
		{
			e_obj_entire = getent( trig_e.target, "targetname" );
			e_obj_entire.origin = obj_e_origin;		
		}
	}		
}




update_linkName()
{
	label = level.labels;
	
	flags = getentarray( "flag_primary", "targetname" );
	descriptors = getentarray( "flag_descriptor", "targetname" );
	
	for(i=0 ; i<flags.size ; i++)
	{
		for(j=0 ; j<descriptors.size ; j++)
		{
			if( distance( flags[i].origin, descriptors[j].origin ) <= 200 )
			{
				descriptors[j].script_linkName = get_flag_number( flags[i].script_label );
				break;
			}
		}
	}
}

get_flag_number( label )
{
	switch( label )
	{
		case "_a" : num = "flag1"; break;
		case "_b" : num = "flag2"; break;
		case "_c" : num = "flag3"; break;
		case "_d" : num = "flag4"; break;
		case "_e" : num = "flag5"; break;
		default : num = "flag9";
	}
	
	return num;
}

update_linkTo()
{
	descriptors = getentarray( "flag_descriptor", "targetname" );
	dist = [];
	
	for(i=0 ; i<descriptors.size ; i++)
	{
		for(j=0 ; j<descriptors.size ; j++)
		{
			if( j != i )
				dist[i][j] = distance( descriptors[i].origin, descriptors[j].origin );
			else
				dist[i][j] = 100000;
		}
		
		nearest = undefined;
		
		for(j=0 ; j<dist[i].size ; j++)
		{
			if( isdefined( dist[i][j] ) )
			{
				if( !isdefined( nearest ) )
					nearest = (dist[i][j], 0, 100);
				
				if( dist[i][j] < nearest[0] )
					nearest = (dist[i][j], j, 100);		
			}
		}
		
		for(j=0 ; j<dist[i].size ; j++)
		{
			if( isdefined( dist[i][j] ) && j != nearest[1] )
			{
				if( dist[i][j] <= (110*nearest[0]/100) )
					nearest = (nearest[0], nearest[1], j);
			}
		}
		
		linkto = "";
		
		if( nearest[2] == 100 )
			linkto = descriptors[int(nearest[1])].script_linkName;
		
		else if( nearest[2] < 100 )
			linkto = descriptors[int(nearest[1])].script_linkName+" "+descriptors[int(nearest[2])].script_linkName;
			
		descriptors[i].script_linkTo = linkto;
	}
}

removeFlagArray( array, index )
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
