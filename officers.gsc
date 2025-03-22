#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "officers", 20, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "officers", 00, 0, 500000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "officers", 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "officers", 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "officers", 1, 0, 1 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	// controlar morte Oficial
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;	

	game["dialog"]["gametype"] = "hardcore_tm_death";
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
	precacheModel( "body_complete_mp_zack_woodland" );

	// Commander Sounds
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";

	precacheShader( "compass_waypoint_defend" );
	precacheShader( "waypoint_defend" );
}

onStartGameType()
{
	// Início como Pilot
	level.officers_ax = 0;
	level.officers_al = 0;
	
	level.LiveVIP_ax = false;
	level.LiveVIP_al = false;	

	setClientNameMode("auto_change");

	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_OFFICERS_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_OFFICERS_HINT" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_OFFICERS_HINT" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_OFFICERS_HINT" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_OFFICERS_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_OFFICERS_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_OFFICERS_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_OFFICERS_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "war";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	level.displayRoundEndText = false;
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	SetaMensagens();
	
	// elimination style
	if ( level.roundLimit != 1 && level.numLives )
	{
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		level.onEndGame = ::onEndGame;
	}
	
	if ( level.HajasWeap != 4 )
		maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );
}

// ==================================================================================================================
//   Officers
// ==================================================================================================================

defineIcons()
{
	// seta commander icons
	if( game["allies"] == "marines" )
	{
		level.hudcommander_allies = "faction_128_usmc";
		level.nome_allies = "Marines";
	}
	else
	{
		level.hudcommander_allies = "faction_128_sas";
		level.nome_allies = "SAS";
	}
	
	if( game["axis"] == "russian" )
	{
		level.hudcommander_axis = "faction_128_ussr";
		level.nome_axis = "Spetsnaz";
	}
	else
	{
		level.hudcommander_axis = "faction_128_arab";
		level.nome_axis = "OpFor";
	}
}

createVipIcon( team )
{
	if( team == "allies" )
	{
		self.carryIcon = createIcon( level.hudcommander_allies, 50, 50 );
		level.status_icon_al = level.hudcommander_allies;
	}
	else
	{
		self.carryIcon = createIcon( level.hudcommander_axis, 50, 50 );
		level.status_icon_ax = level.hudcommander_axis;
	}				
	
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
}

SpawnVIP( team )
{
	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
	{
		//"^7You are the ^9General^7!"
		msg = level.text1 + " ^9" + DefineOfficer( team ) + "^7!";
		self iPrintLnbold( msg );
	}
	
	self thread defineIcons();
	self thread createVipIcon( team );

	// troca a skin pra VIP/Commander
	VIPloadModel( team ); 	
	
	// diz q o mapa já tem um vip/commander vivo
	if ( team == "axis" )
		level.LiveVIP_ax = true;
	else if ( team == "allies" )
		level.LiveVIP_al = true;
	
	// seta nome do Commander para mostrar na tela
	if ( team == "axis" )
		level.ShowName_ax = self.name;
	else if ( team == "allies" )
		level.ShowName_al = self.name;
	
	// carrega icon no placar
	if ( team == "axis" )
		self.statusicon = level.status_icon_ax;
	else if ( team == "allies" )
		self.statusicon = level.status_icon_al;
		
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
}

SpawnDocs_ax( trigger, visuals )
{
	pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( "axis", trigger, visuals, (0,0,100) );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
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
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
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

DefineOfficer( team )
{
	officer = "";
	officer_status = "";
	
	if ( team == "axis" )
		officer_status = level.officers_ax;
	else if ( team == "allies" )
		officer_status = level.officers_al;
	
	switch ( officer_status )
	{		
		case 0:
			officer = level.officer0;
			break;
					
		case 1:
			officer = level.officer1;
			break;
			
		case 2:
			officer = level.officer2;
			break;

		case 3:
			officer = level.officer3;
			break;
			
		case 4:
			officer = level.officer4;
			break;

		case 5:
			officer = level.officer5;
			break;

		case 6:
			officer = level.officer6;
			break;
															
		default:
			officer = level.officer0;
	}
	
	return officer;
}

DefineOfficerPoints( team )
{
	officer = 0;
	officer_status = "";
	
	if ( team == "axis" )
		officer_status = level.officers_ax;
	else if ( team == "allies" )
		officer_status = level.officers_al;	
	
	switch ( officer_status )
	{	
		case 0:
			officer = 25;
			break;
						
		case 1:
			officer = 50;
			break;
			
		case 2:
			officer = 100;
			break;

		case 3:
			officer = 200;
			break;
			
		case 4:
			officer = 400;
			break;

		case 5:
			officer = 800;
			break;

		case 6:
			officer = 1600;
			break;
															
		default:
			officer = 25;
	}
	
	return officer;
}

CommanderDead( attacker )
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["attackers"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["defenders"] );

		// deixa de ser vip/commander
		self.isCommander = false;
		
		// pontua!
		pontos = DefineOfficerPoints( self.team );
		Pontua( self.team, pontos );
		
		if ( isDefined(attacker.team) && attacker.team != self.team )
		{
			attacker thread [[level.onXPEvent]]( "assault" );
			maps\mp\gametypes\_globallogic::givePlayerScore( "assault", attacker );
		}
		
		if ( level.SidesMSG == 1 )
			OfficerDead( self.team );
		
		// sobe rank!
		if ( self.team == "axis" )
			level.officers_ax++;
		else
			level.officers_al++;

		// diz q nao tem mais vip/Commander vivo
		if ( self.team == "axis" )
			level.LiveVIP_ax = false;
		else
			level.LiveVIP_al = false;
	}
}

Pontua( team, ponto )
{
	team_final = level.otherTeam[team];

	[[level._setTeamScore]]( team_final, [[level._getTeamScore]]( team_final ) + ponto );
}

OfficerDead( team )
{
	//"^9General ^7is ^1Dead^7!"
	msg = "^9" + DefineOfficer( team ) + " ^7" + level.text3 + "^7!";

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		player iPrintLn( msg );
	}
}

SpawnSoldado()
{
	self.isCommander = false;
	
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();	

	if ( self.team == "axis" && level.officers_ax <= 6 )
		thread ShowVipName("axis");
	else if ( self.team == "allies" && level.officers_al <= 6 )
		thread ShowVipName("allies");
}

ShowVipName( team )
{
	self endon ("disconnect");
	self endon ("death");
	self endon ( "game_ended" );
	
	ShowName = "";
	
	wait 5;

	if ( team == "axis" )
		ShowName = level.ShowName_ax;
	else if ( team == "allies" )
		ShowName = level.ShowName_al;		
	
	if ( !isDefined( ShowName ) )
		wait 5;
		
	if ( team == "axis" )
		ShowName = level.ShowName_ax;
	else if ( team == "allies" )
		ShowName = level.ShowName_al;			

	if ( isDefined( ShowName ) )
	{
		msg_info = "^9" + ShowName + "^7 " + level.text2 + " ^9" + DefineOfficer( team ) + "^7!" ;
		self iPrintLn( msg_info );
	}
}

VIPloadModel( team )
{
	// salva classe original
	//game["original_class_atual"] = self.pers["class"];
	self.class_original = self.pers["class"];

	self.pers["class"] = "CLASS_COMMANDER";
	self.class = "CLASS_COMMANDER";
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
	
	// Pilot
	if ( team == "axis" && level.officers_ax == 0 )
		thread Pilot();
	else if ( team == "allies" && level.officers_al == 0 )
		thread Pilot();
}

Pilot()
{
	wait 0.1;
	self detachAll();
	self setModel( "body_complete_mp_zack_woodland" );
	self takeAllWeapons();
	self giveWeapon( "colt45_mp" );
	self giveMaxAmmo( "colt45_mp" );
	self switchToWeapon( "colt45_mp" );
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

onPlayerDisconnect()
{
	// o prox a dar respawn será o novo Commander, sem alterar ranks ou pontos.
	if ( isDefined( self.isCommander ) )
	{
		if ( self.isCommander == true )
		{
			self.isCommander = false;
			
			if( self.team == "axis" )
				level.LiveVIP_ax = false;
			else
				level.LiveVIP_al = false;
		}
	}
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();

	self thread CommanderDead( attacker );
}

onSpawnPlayer()
{
	self.usingObj = undefined;
	spawnPoints   = undefined;
	spawnPoint    = undefined;
	
	self.isCommander = false;
	
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();	
		
	// deleta skin do commander se sobrou do round anterior
	if ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP" )
		VIPloadModelBACK();				

	if ( level.inGracePeriod )
	{
		spawnPoints = getentarray("mp_tdm_spawn_" + self.pers["team"] + "_start", "classname");
		
		if ( !spawnPoints.size )
			spawnPoints = getentarray("mp_sab_spawn_" + self.pers["team"] + "_start", "classname");
			
		if ( !spawnPoints.size )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
		}
		else
		{
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
		}		
	}
	else
	{
		if ( level.LiveVIP_ax == false && self.pers["team"] == "axis" && level.officers_ax <= 6 )
			SpawnVIP( "axis" );
		else if ( level.LiveVIP_al == false && self.pers["team"] == "allies" && level.officers_al <= 6 )
			SpawnVIP( "allies" );
		else
			SpawnSoldado();	
	
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
	}
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( self.isCommander == true ) // oficiais sao PQD
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		}
		else
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn( spawnPoint.origin, spawnPoint.angles );
		}
	}
	else
		self spawn( spawnPoint.origin, spawnPoint.angles );
		
	// remove hardpoints
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints_player( self );		
}

onEndGame( winningTeam )
{
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
}

// ==================================================================================================================
//   Mensagens
// ==================================================================================================================

SetaMensagens()
{
	if ( getDvar( "scr_officers_officer0" ) == "" )
		level.officer0 =  "Pilot";
	else
		level.officer0 = getDvar( "scr_officers_officer0" );
			
	if ( getDvar( "scr_officers_officer1" ) == "" )
		level.officer1 =  "2nd Lieutenant";
	else
		level.officer1 = getDvar( "scr_officers_officer1" );
	
	if ( getDvar( "scr_officers_officer2" ) == "" )
		level.officer2 =  "1st Lieutenant";
	else
		level.officer2 = getDvar( "scr_officers_officer2" );

	if ( getDvar( "scr_officers_officer3" ) == "" )
		level.officer3 =  "Captain";
	else
		level.officer3 = getDvar( "scr_officers_officer3" );

	if ( getDvar( "scr_officers_officer4" ) == "" )
		level.officer4 =  "Major";
	else
		level.officer4 = getDvar( "scr_officers_officer4" );

	if ( getDvar( "scr_officers_officer5" ) == "" )
		level.officer5 =  "Colonel";
	else
		level.officer5 = getDvar( "scr_officers_officer5" );
	
	if ( getDvar( "scr_officers_officer6" ) == "" )
		level.officer6 =  "General";
	else
		level.officer6 = getDvar( "scr_officers_officer6" );
	
	// ------------------------------------------------------------------------------------------------

	if ( getDvar( "scr_officers_text1" ) == "" )
		level.text1 =  "You are the";
	else
		level.text1 = getDvar( "scr_officers_text1" );
	
	if ( getDvar( "scr_officers_text2" ) == "" )
		level.text2 =  "is the";
	else
		level.text2 = getDvar( "scr_officers_text2" );
	
	if ( getDvar( "scr_officers_text3" ) == "" )
		level.text3 =  "is ^1Dead";
	else
		level.text3 = getDvar( "scr_officers_text3" );
}
