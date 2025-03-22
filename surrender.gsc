#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerSurrenderArmyDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.SurrenderArmyDvar = dvarString;
	level.SurrenderArmyMin = minValue;
	level.SurrenderArmyMax = maxValue;
	level.SurrenderArmy = getDvarInt( level.SurrenderArmyDvar );
}

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "surrender", 15, 8, 120 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "surrender", 2, 1, 2 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "surrender", 0, 0, 200 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "surrender", 1, 0, 1 );

	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "surrender", 1, 1, 1 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "surrender", 0, 0, 0 );
	
	registerSurrenderArmyDvar( "scr_surrender_army", 15, 5, 50 );

	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	
	// controlar morte Commander
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["defense_obj"] = "security_complete";
	
	game["dialog"]["ourflag"] = "ourflag";
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	game["dialog"]["enemyflag"] = "enemyflag";
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";	
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

	precacheShader( "waypoint_captureneutral" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	
	maps\mp\gametypes\_airborne::init();
}

onStartGameType()
{
	level.LiveVIP = false;
	
	// inicio como 2nd tenente!
	level.officers = 1;
	
	// ninguém se rendeu ainda!
	level.serendeu = 0;
	
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

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_SURRENDER_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_SURRENDER_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_SURRENDER_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SURRENDER_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_SURRENDER_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SURRENDER_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_SURRENDER_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_SURRENDER_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// posição spawns para marcar spawns da defesa/ataque!
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_allies_start" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_axis_start" );
	
	level.spawn_all = getentarray( "mp_tdm_spawn", "classname" );
	level.spawn_axis_start = getentarray("mp_tdm_spawn_axis_start", "classname" );
	level.spawn_allies_start = getentarray("mp_tdm_spawn_allies_start", "classname" );
	
	level.startPos["allies"] = level.spawn_allies_start[0].origin;
	level.startPos["axis"] = level.spawn_axis_start[0].origin;
	
	allowed[0] = "dom";
//	allowed[1] = "hardpoint";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	novos_flag_init();
		
	thread domFlags();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );	

	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();

	// calcula spawns da defesa!
	CalculaSpawns();
	
	SetaMensagens();
	
	thread CalculaArmy();
	
	// toca alarme
	thread TocaAlarme();
	
	// Smoke FX
	level.rot = randomfloat(360); // define angulos das fumaças!
	level.tamanho = distance( level.attack_spawn, level.defender_spawn );
	level.spread = int(level.tamanho/6);
	if ( level.spread < 1000 )
		level.spread = 1000;
	NumSmokesIniciais = int(level.spread/120);
	thread CriaSmoke(NumSmokesIniciais);
}

// ==================================================================================================================
//   Smoke FX
// ==================================================================================================================

CriaSmoke( num )
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	origem = level.flags[0].origin;
	
	thread EQInicial(origem);
	
	while(num > 0 )
	{
		thread seta_smoke( origem );
		num--;
	}
}

// de onde será o pulo
seta_smoke( origem )
{
	smoke = Gera_Smoke( origem );
	Smoking( smoke );		
}

Gera_Smoke( origem )
{
	// calcula ponto central pra fazer vento inicial para tirar das bordas
	x = randomIntRange ( (level.spread * -1), level.spread );
	y = randomIntRange ( (level.spread * -1), level.spread );
	x_centro = int(origem[0] + x );
	y_centro = int(origem[1] + y );
	z_centro = origem[2];
	
	smoke_final = PlayerPhysicsTrace( (x_centro,y_centro,z_centro), (x_centro,y_centro,z_centro) + (0,0,-500) );
		
	//smoke_final = (x_centro,y_centro,z_centro) ;

	return smoke_final;
}

Smoking( alvo )
{
	alvo = alvo + (0,0,-100);

	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(level.rot),sin(level.rot),0) );
	triggerFx( smoke );

	smoke_black = spawnFx( level.smoke_tm_black, alvo, (0,0,1), (cos(level.rot),sin(level.rot),0) );
	triggerFx( smoke_black );

	thread DeletaSmokes(smoke_black, 10);
}

DeletaSmokes(smoke, duracao)
{
	if( !isDefined(duracao))
		duracao = randomIntRange(20,30);
		
	wait duracao;
	
	if(isDefined(smoke))
		smoke delete();
}

EQInicial(origem)
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	thread playSoundinSpace( "exp_suitcase_bomb_main", origem );		
		
	duracao = randomIntRange(50,100);
	tempo = 0;
	while ( int(tempo) < 2 )
	{
		earthquake( .08, .05, origem, 80000);
		wait(.05);
		tempo = tempo + 0.1;
	}
	while( duracao > 0 )
	{
		earthquake( .5, 1, origem, 80000);
		wait(.05);
		earthquake( .25, .05, origem, 80000);
		duracao--;
	}
}


// ==================================================================================================================
//   Flag
// ==================================================================================================================

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
		
	if ( level.novos_objs )
		move_flag();		
		
	FlagCentral = SelecionaFlag();
	
	level.flags = [];
	level.flags[0] = FlagCentral;
	
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

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::setOwnerTeam( game["defenders"] );
		domFlag.visuals[0] setModel( game["flagmodels"][game["defenders"]] );		
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( 60.0 );	
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_captureneutral" );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_captureneutral" );
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
	
	// level.bestSpawnFlag is used as a last resort when the enemy holds all flags.
	level.bestSpawnFlag = [];
	level.bestSpawnFlag[ "allies" ] = getUnownedFlagNearestStart( "allies", undefined );
	level.bestSpawnFlag[ "axis" ] = getUnownedFlagNearestStart( "axis", level.bestSpawnFlag[ "allies" ] );
	
	flagSetup();
	
//	setDvar( level.scoreLimitDvar, level.domFlags.size );

}

SelecionaFlag()
{
	flag_center = undefined;
	
	if ( level.flags.size == 3 )
	{
		flag_ataque = FlagPertoSpawn( level.attack_spawn );
		flag_defesa = FlagPertoSpawn( level.defender_spawn );
		
		flag_center = RetornaFlagRestante( flag_ataque, flag_defesa );
	}
	else
	{
		flag_ataque = FlagPertoSpawn( level.attack_spawn );
		flag_defesa = FlagPertoSpawn( level.defender_spawn );
		
		flag_center = RetornaFlagMaisAlta( flag_ataque, flag_defesa );	
	}
	
	return flag_center;
}

FlagPertoSpawn( ponto )
{
	flag_perto = undefined;
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( index == 0 )
		{
			flag_perto = flag;
		}
		else
		{
			if ( distance( flag_perto.origin, ponto ) > distance( flag.origin , ponto ) )
			{
				flag_perto = flag;
			}
		}
	}
	return flag_perto;
}

RetornaFlagRestante( flag1, flag2 )
{
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( flag != flag1 && flag != flag2 )
		{
			return flag;
		}
	}
}

RetornaFlagMaisAlta( flag1, flag2 )
{
	flag_alta = undefined;
	
	novasFlags = [];
	novo_index = 0;
	
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( flag != flag1 && flag != flag2 )
		{
			novasFlags[novo_index] = flag;
			novo_index++;
		}
	}

	for ( index = 0; index < novasFlags.size; index++ )
	{	
		flag = novasFlags[index];
		
		if ( !isDefined( flag_alta ) )
		{
			flag_alta = flag;
		}
		else
		{
			if ( flag.origin[2] > flag_alta.origin[2] )
			{
				flag_alta = flag;
			}
		}
	}
	if ( !isDefined( flag_alta ) )
	{
		flag_alta = novasFlags[0];
	}	
	return flag_alta;
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
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team ); // não troca time!
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 	
	self.visuals[0] setModel( game["flagmodels"]["neutral"] ); // bandeira branca!
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

	setGameEndTime( 0 );
	[[level._setTeamScore]]( game["defenders"], 0 ); // zera placar da defesa
	
	equipe = level.nome_axis;
	if ( game["defenders"] == "allies" )
		equipe = level.nome_allies;	
	
	msg = equipe + " " + level.assault_succeed;
	sd_endGame( game["attackers"], msg );
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

getFlagTeam()
{
	return self.useObj maps\mp\gametypes\_gameobjects::getOwnerTeam();
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
	
	// diz q é a única flag
	nearestflag = flags[0];
	
	// distancia max pra valer o spawn
	nearestdist = 1000;
	
	// adiciona apenas os spawnpoints perto da flag
	spawnpoints = getentarray("mp_dom_spawn", "classname");

	// loop control
	tudo_ok = false;
	
	// spawn_count
	spawn_count = 0;
	
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
			dist = distance(flags[0].origin, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < nearestdist)
			{
				spawn_count++;
			}
		}
		if ( spawn_count < 2 )
		{
			nearestdist = nearestdist + 500;
			spawn_count = 0;
		}
		else
		{
			tudo_ok = true;
		}
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(flags[0].origin, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < nearestdist)
		{
			nearestflag.nearbyspawns[nearestflag.nearbyspawns.size] = spawnpoints[i];
		}
	}	
	
	//logPrint("spawnsize = " + nearestflag.nearbyspawns.size + "\n");
	
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

// ==================================================================================================================
//   Player
// ==================================================================================================================

CalculaSpawns()
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = 500;

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
			dist = distance(level.flags[0].origin, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
				spawn_count++;
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 200;
			spawn_count = 0;
		}
		else
			tudo_ok = true;
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(level.flags[0].origin, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
	}	
}


onSpawnPlayer()
{
	self.isCommander = false;
	
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();		
	
	// deleta skin do commander se sobrou do round anterior
	if ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP" )
		VIPloadModelBACK();	
	
	// airborne
	if(self.pers["team"] == game["attackers"])
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		assert( spawnPoints.size );
		
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );	
	
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		else
		{
			if ( randomInt(2) == 0 )
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.spawn_axis_start );
			else
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.spawn_allies_start );
				
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
	}
	else // defesa
	{
		// ================== Spawn Commander/Soldado ==========================
		
		if ( level.LiveVIP == false && self.pers["team"] == game["defenders"] && level.officers <= 6 )
			SpawnVIP();
		else
			SpawnSoldado();

		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
		maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
		
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );

		self spawn( spawnpoint.origin, spawnpoint.angles );
	}
	
	level notify ( "spawned_player" );
	
	// remove hardpoints
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints_player( self );
}

onPlayerDisconnect()
{
	// o prox a dar respawn será o novo Commander, sem alterar ranks ou pontos.
	if ( isDefined( self.isCommander ) )
	{
		if ( self.isCommander == true )
		{
			self.isCommander = false;
			level.LiveVIP = false;
		}
	}

	if( isDefined( self.pers["team"] ) && self.pers["team"] == game["attackers"] )
		maps\mp\gametypes\_airborne::removePQplayer();
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();

	if( isDefined( self.pers["team"] ) && self.pers["team"] == game["attackers"] )
		maps\mp\gametypes\_airborne::removePQplayer();

	self thread CommanderDead();
	
	team = self.pers["team"];
	if ( self.touchTriggers.size && isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] )
	{
		triggerIds = getArrayKeys( self.touchTriggers );
		ownerTeam = self.touchTriggers[triggerIds[0]].useObj.ownerTeam;
		
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

	if ( team == game["defenders"] && level.serendeu == 0 )
	{
		[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) - 1 );
		
		if ( [[level._getTeamScore]]( game["defenders"] ) <= 0 )
		{
			[[level._setTeamScore]]( game["defenders"], 0 );
		
			level.serendeu = 1;	
			
			equipe = level.nome_axis;
			if ( game["defenders"] == "allies" )
				equipe = level.nome_allies;			
			
			msg = equipe + " " + level.assault_succeed;
			sd_endGame( game["attackers"], msg );
		}		
	}
}

// ==================================================================================================================
//   Game Over
// ==================================================================================================================

sd_endGame( winningTeam, endReasonText )
{
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
	
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	
	// dá ponto extra apenas no 1° round pro War Server funcionar, e retira logo q inicia 2° round!
	
	if( game["roundsplayed"] == 0 )	
	{
		if ( isdefined( winningTeam ) )
		{
			if ( isdefined( [[level._getTeamScore]]( winningTeam ) ) )
				[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );
			else
				[[level._setTeamScore]]( winningTeam, 1 );
		}
	}
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onTimeLimit()
{
	sd_endGame( game["defenders"], level.assault_failed );
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

smokeFX( alvo, rot )
{
	alvo = alvo + (0,0,-100);
	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke );
}

// ==================================================================================================================
//   Score
// ==================================================================================================================

CalculaArmy()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;		
		
	if( game["roundsplayed"] == 0 )		
	{
		level.surarmy = level.players.size * level.SurrenderArmy;
		
		if ( getDvarInt("fl_bots") == 1 )
			level.surarmy = level.surarmy + (getDvarInt("fl_bots_num") * level.SurrenderArmy);
	
		if ( level.surarmy < 100 )
			level.surarmy = 100;
			
		SetDvar( "surrender_army", level.surarmy );				
			
		// inicia dando placar máximo pra defesa!
		[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) + getDvarInt("surrender_army") );			
	}
	else if( game["roundsplayed"] == 1 )
	{
		if ( !isDefined([[level._getTeamScore]]( game["defenders"] )) )
			[[level._setTeamScore]]( game["defenders"], 0 );
	
		[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) + getDvarInt("surrender_army") );
		
		
		// remove ponto extra!
		if ( [[level._getTeamScore]]( game["attackers"] ) == 0 )
			[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) - 1 );	 
	}	
}

Pontua( ponto )
{
	[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) - ponto );
}

// ==================================================================================================================
//   Sound
// ==================================================================================================================

TocaAlarme()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
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

createVipIcon()
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
	
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
}

CommanderDead()
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["attackers"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["defenders"] );

		// deixa de ser vip/commander
		self.isCommander = false;
		
		// pontua!
		pontos = DefineOfficerPoints();
		Pontua( pontos );
		
		if ( level.SidesMSG == 1 )
			OfficerDead();
		
		// sobe rank!
		level.officers++;

		// diz q nao tem mais vip/Commander vivo
		level.LiveVIP = false;
		
		level notify("vip_is_dead");
	}
}

SpawnVIP()
{
	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
	{
		//"^7You are the ^9General^7!"
		msg = level.text1 + " ^9" + DefineOfficer() + "^7!";
		self iPrintLnbold( msg );
	}
	
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

DefineOfficer()
{
	officer = "";
	
	switch ( level.officers )
	{			
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
			officer = level.officer1;
	}
	
	return officer;
}

DefineOfficerPoints()
{
	officer = 0;
	
	switch ( level.officers )
	{			
		case 1:
			officer = 3;
			break;
			
		case 2:
			officer = 5;
			break;

		case 3:
			officer = 10;
			break;
			
		case 4:
			officer = 15;
			break;

		case 5:
			officer = 20;
			break;

		case 6:
			officer = 30;
			break;
															
		default:
			officer = 3;
	}
	
	return officer;
}

OfficerDead()
{
	//"^9General ^7is ^1Dead^7!"
	msg = "^9" + DefineOfficer() + " ^7" + level.text3 + "^7!";

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

	if ( self.pers["team"] == game["defenders"] && level.officers <= 6 )
		thread ShowVipName();
}

ShowVipName()
{
	self endon ("disconnect");
	self endon ("death");
	self endon ( "game_ended" );
	
	wait 5;
	if ( !isDefined( level.ShowName ) )
		wait 5;

	if ( isDefined( level.ShowName ) )
	{
		msg_info = "^9" + level.ShowName + "^7 " + level.text2 + " ^9" + DefineOfficer() + "^7!" ;
		self iPrintLn( msg_info );
	}
}

VIPloadModel()
{
	// salva classe original
	game["original_class_atual"] = self.pers["class"];

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


// ==================================================================================================================
//   Mensagens
// ==================================================================================================================

SetaMensagens()
{
	if ( getDvar( "scr_surrender_officer1" ) == "" )
		level.officer1 =  "2nd Lieutenant";
	else
		level.officer1 = getDvar( "scr_surrender_officer1" );
	
	if ( getDvar( "scr_surrender_officer2" ) == "" )
		level.officer2 =  "1st Lieutenant";
	else
		level.officer2 = getDvar( "scr_surrender_officer2" );

	if ( getDvar( "scr_surrender_officer3" ) == "" )
		level.officer3 =  "Captain";
	else
		level.officer3 = getDvar( "scr_surrender_officer3" );

	if ( getDvar( "scr_surrender_officer4" ) == "" )
		level.officer4 =  "Major";
	else
		level.officer4 = getDvar( "scr_surrender_officer4" );

	if ( getDvar( "scr_surrender_officer5" ) == "" )
		level.officer5 =  "Colonel";
	else
		level.officer5 = getDvar( "scr_surrender_officer5" );
	
	if ( getDvar( "scr_surrender_officer6" ) == "" )
		level.officer6 =  "General";
	else
		level.officer6 = getDvar( "scr_surrender_officer6" );
	
	// ------------------------------------------------------------------------------------------------

	if ( getDvar( "scr_surrender_text1" ) == "" )
		level.text1 =  "You are the";
	else
		level.text1 = getDvar( "scr_surrender_text1" );
	
	if ( getDvar( "scr_surrender_text2" ) == "" )
		level.text2 =  "is the";
	else
		level.text2 = getDvar( "scr_surrender_text2" );
	
	if ( getDvar( "scr_surrender_text3" ) == "" )
		level.text3 =  "is ^1Dead";
	else
		level.text3 = getDvar( "scr_surrender_text3" );

	// ------------------------------------------------------------------------------------------------

	if ( getDvar( "scr_surrender_succeed" ) == "" )
		level.assault_succeed =  "Surrendered";
	else
		level.assault_succeed = getDvar( "scr_surrender_succeed" ) + " ";
	
	if ( getDvar( "scr_invasion_secured" ) == "" )
		level.assault_failed =  "Territory Secured";
	else
		level.assault_failed = getDvar( "scr_invasion_secured" );
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
	
	/*
	logPrint(  " = listas formadas = " + "\n");
	logPrint(  "level.xflag_a = " + level.xflag_a.size + "\n");
	logPrint(  "level.xflag_b = " + level.xflag_b.size + "\n");
	logPrint(  "level.xflag_c = " + level.xflag_c.size + "\n");
	if ( level.NumFlagsOri > 3 )
		logPrint(  "level.xflag_d = " + level.xflag_d.size + "\n");
	if ( level.NumFlagsOri > 4 )
		logPrint(  "level.xflag_e = " + level.xflag_e.size + "\n");
	*/
	
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
	
	/*
	logPrint(  " = listas -ABC - 1 de cada lista + lista selecionada que tem q ser 3 = " + "\n");
	logPrint(  "level.xflag_a = " + level.xflag_a.size + "\n");
	logPrint(  "level.xflag_b = " + level.xflag_b.size + "\n");
	logPrint(  "level.xflag_c = " + level.xflag_c.size + "\n");
	if ( level.NumFlagsOri > 3 )	
		logPrint(  "level.xflag_d = " + level.xflag_d.size + "\n");
	if ( level.NumFlagsOri > 4 )	
		logPrint(  "level.xflag_e = " + level.xflag_e.size + "\n");
	logPrint(  "level.xflag_selected = " + level.xflag_selected.size + "\n");	
	*/
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
	
	/*
	logPrint(  " = level.newFlags montada com 2 pos = " + "\n");
	logPrint(  "level.newFlags = " + level.newFlags.size + "\n");	
	logPrint(  " = level.xflags tem -2 pos removidas que foram para level.newFlags= " + "\n");
	logPrint(  "level.xflag_a = " + level.xflag_a.size + "\n");
	logPrint(  "level.xflag_b = " + level.xflag_b.size + "\n");
	logPrint(  "level.xflag_c = " + level.xflag_c.size + "\n");
	if ( level.NumFlagsOri > 3 )
		logPrint(  "level.xflag_d = " + level.xflag_d.size + "\n");
	if ( level.NumFlagsOri > 4 )
		logPrint(  "level.xflag_e = " + level.xflag_e.size + "\n");
	*/
}

CalculaDist()
{
	level.dist_inicial = 1000;
	
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
			//logPrint("=-=-=-=-=-=-=new_origin = " + new_origin + "\n");
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
	
	//logPrint("=-=-=-=-=-=-= pos = " + pos + " | flag = " + flag + "\n");
	
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
	
	//logPrint("=-=-=-=-=-=-=update_linkName - descriptors.size = " + descriptors.size + "\n");
	
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
	
	//logPrint("=-=-=-=-=-=-=update_linkTo - descriptors.size = " + descriptors.size + "\n");
	
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
