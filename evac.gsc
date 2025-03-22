#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// ==================================================================================================================
//   Evac Brain
// ==================================================================================================================

init()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "evac", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "evac", 10, 1, 10 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "evac", 2, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "evac", 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "evac", 1, 0, 1 );
	
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
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "goodtogo";
	game["dialog"]["defense_obj"] = "goodtogo";
	
	game["nuke_alarm"] = "nuke_alarm";
}


onPrecacheGameType()
{
	precacheShader("compass_waypoint_target");
	precacheShader("waypoint_target");
}

onStartGameType()
{
	level.ZuluRevealed = false;
	
	// define angulos das fumaças!
	level.rot = randomfloat(360);

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
	//level.smoke_tm	= loadfx("smoke/smoke_launchtubes");
	//level.smoke_tm_black = loadfx("explosions/tanker_explosion");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_EVAC_MENU" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_EVAC_MENU" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_EVAC_HINT" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_EVAC_HINT" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_EVAC_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_EVAC_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_EVAC_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_EVAC_HINT" );

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
	
	// posição spawns para marcar spawns da defesa/ataque!
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	level.tamanho = distance( level.attack_spawn, level.defender_spawn );
	level.spread = int(level.tamanho/2);
	//logPrint("level.tamanho = " + level.tamanho + "\n");
	
	allowed[0] = "dom";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	CalculaSpawnsDefesa();
	CalculaSpawnsAtaque();
	
	domFlags();
	
	level.maxaltFX = 5000;

	NumSmokesIniciais = int(level.tamanho/300);
	thread CriaSmoke(NumSmokesIniciais);
	thread EQInicial();

	thread CriaAbalos();
	
	SetaMensagens();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}

DeletaFlags()
{
	allowed = [];
	maps\mp\gametypes\_gameobjects::main(allowed);
}

// ==================================================================================================================
//   Smokes
// ==================================================================================================================

CriaSmoke( num )
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	time = "";
	lado = randomInt(1);

	if( lado == 1 )
		time = "axis";
	else
		time = "allies";
		
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( time );
	assert( spawnPoints.size );
	spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
	while(num > 0 )
	{
		thread seta_pulo( spawnPoint.origin );
		num--;
	}
}

// de onde será o pulo
seta_pulo( spawn )
{
	while(1)
	{
		pulo = calcula_pulo( spawn );
		alvo = calcula_alvo ( pulo );
		
		testa_clip = PlayerPhysicsTrace( pulo , alvo );
		
		if ( distance( pulo,  testa_clip ) > 500 )	
		{
			Smoking( alvo );		
			return; // ok se for distante o suficiente, senão refaz tudo de novo!	
		}
	}
}

Smoking( alvo )
{
	if ( level.ZuluRevealed == false )
	{
		alvo = alvo + (0,0,-100);
	
		smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(level.rot),sin(level.rot),0) );
		triggerFx( smoke );
	
		smoke_black = spawnFx( level.smoke_tm_black, alvo, (0,0,1), (cos(level.rot),sin(level.rot),0) );
		triggerFx( smoke_black );
		
		//thread DeletaSmokes(smoke,30);
		thread DeletaSmokes(smoke_black, 10);
	}
	else
	{
		delay = randomInt(5);
		wait delay;
		
		alvo2 = alvo + (0,0,-100);
		smoke = spawnFx( level.smoke_tm, alvo2, (0,0,1), (cos(level.rot),sin(level.rot),0) );
		triggerFx( smoke );
	
		smoke_black = spawnFx( level.smoke_tm_black, alvo, (0,0,1), (cos(level.rot),sin(level.rot),0) );
		triggerFx( smoke_black );	

		thread playSoundinSpace( "exp_suitcase_bomb_main", alvo );
		
		smoke_black radiusDamage( alvo, 512, 200, 20 );
		
		thread EQLocal(alvo);
		
		thread DeletaSmokes(smoke);
		thread DeletaSmokes(smoke_black, 10);	
	}
}

ExplosaoIsolada( alvo )
{
	rot = randomfloat(360);
	
	alvo2 = alvo + (0,0,-100);
	smoke = spawnFx( level.smoke_tm, alvo2, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke );

	smoke_black = spawnFx( level.smoke_tm_black, alvo, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke_black );	

	thread playSoundinSpace( "exp_suitcase_bomb_main", alvo );
	
	smoke_black radiusDamage( alvo, 512, 200, 20 );
	
	thread EQLocal(alvo);
	
	thread DeletaSmokes(smoke_black, 15);	
}


calcula_pulo( pulo )
{
	// calcula ponto central pra fazer vento inicial para tirar das bordas
	x = randomIntRange ( (level.spread * -1), level.spread );
	y = randomIntRange ( (level.spread * -1), level.spread );
	x_centro = int(level.mapCenter[0] + x );
	y_centro = int(level.mapCenter[1] + y );
	z_centro = level.maxaltFX;
		
	// spawn atual com altura maxima!
	pulo = (int(pulo[0]),int(pulo[1]),level.maxaltFX);
		
	pulo_final = PlayerPhysicsTrace( pulo , (x_centro,y_centro,z_centro) );

	return pulo_final;
}

calcula_alvo ( pulo )
{
	time = "";
	lado = randomInt(1);

	if( lado == 1 )
		time = "axis";
	else
		time = "allies";

	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( time );

	pos_tipo = randomInt(1);
	
	if( pos_tipo == 0 )
	{
		while ( 1 )
		{
			x = randomIntRange ( (level.spread * -1), level.spread );
			y = randomIntRange ( (level.spread * -1), level.spread );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			novo_alvo = spawnPoint.origin + (x,y,0);
			
			if ( distance( pulo,  spawnPoint.origin ) > distance( pulo, novo_alvo ) )
				return novo_alvo;
		}
	}
	else 
	{
			x = randomIntRange ( (level.spread * -1), level.spread );
			y = randomIntRange ( (level.spread * -1), level.spread );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			novo_alvo = spawnPoint.origin + (x,y,0);
			
			return novo_alvo;
	}
}

CriaAbalos()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	if ( getDvarInt( "frontlines_chaotic" ) > 0 ) // se server tem chaos liberado evac sera 100%
		SetDvar( "frontlines_chaos", 1 );

	while ( !level.gameEnded )
	{		
		while ( getDvarInt ( "frontlines_chaos" ) == 0 )
			wait 1;
	
		Intervalos = randomInt(20);
		NumAbalos = randomIntRange(2,5);
	
		wait Intervalos;
		thread CriaSmoke(NumAbalos);
	}
}

EQInicial()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	thread playSoundinSpace( "exp_suitcase_bomb_main", level.FlagCentral );		

	duracao = randomIntRange(50,100);
	tempo = 0;
	while ( int(tempo) < 2 )
	{
		earthquake( .08, .05, level.FlagCentral, 80000);
		wait(.05);
		tempo = tempo + 0.1;
	}
	while( duracao > 0 )
	{
		earthquake( .5, 1, level.FlagCentral, 80000);
		wait(.05);
		earthquake( .25, .05, level.FlagCentral, 80000);
		duracao--;
	}
}

EQLocal( alvo )
{
	duracao = randomIntRange(50,100);
	tempo = 0;
	while ( int(tempo) < 2 )
	{
		earthquake( .08, .05, alvo, 8000);
		wait(.05);
		tempo = tempo + 0.1;
	}
	while( duracao > 0 )
	{
		earthquake( 0.7, 0.5, alvo, 800 );
		wait(.05);
		earthquake( 0.4, 0.6, alvo, 700 );
		
		duracao--;
	}
}

DeletaSmokes(smoke, duracao)
{
	if( !isDefined(duracao))
		duracao = randomIntRange(20,30);
		
	wait duracao;
	
	if(isDefined(smoke))
		smoke delete();
}

// ==================================================================================================================
//   Escape Zone = Flag Central DOM
// ==================================================================================================================

domFlags()
{
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
	level.FlagCentral = FlagCentral.origin;
	thread ZuluSmoke( FlagCentral.origin );
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

ZuluSmoke( origin ) 
{
	level.pos_zulu = origin;

	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	wait 10;
	
	thread TocaAlarme();
	
	level.zulu = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", origin + (0,0,70), "all", "waypoint_target" );
	level.zulu setWayPoint( true, "waypoint_target" );		

	thread playSoundinSpace( "smokegrenade_explode_default", origin );
	
	zulupoint = spawnFx( level.zulu_point_smoke, origin, (0,0,1), (cos(level.rot),sin(level.rot),0) );
	triggerFx( zulupoint );
	
	level.ZuluRevealed = true;

	thread ZuluRevealed();
}

ZuluRevealed()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		player iPrintLn( level.escape_mark );
	}
	playSoundOnPlayers( "mp_suitcase_pickup" );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move" );
}


PlayerSafe()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	if ( level.SidesMSG == 1 )
	{
		self iPrintLnbold( level.evac_msg );
	}	

	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.pos_zulu) < 100 )
			{
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 10 );
				if ( level.starstreak > 0 )
					self.fl_stars_pts = self.fl_stars_pts + 3;
				thread EscapeUpdateScore( self.team );
				self RespawnSafe();
			} 
		}
		wait 1;
	}
}

// ==================================================================================================================
//   Spawn Player
// ==================================================================================================================

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	
	thread PlayerSafe();
	
	if ( level.inPrematchPeriod )
	{
		if(self.pers["team"] == game["attackers"])
		{
			spawnPointName = "mp_sd_spawn_attacker";
		}
		else
		{
			spawnPointName = "mp_sd_spawn_defender";
		}

		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		if(self.pers["team"] == game["attackers"])
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.AtaqueSpawns );
		}
		else
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
		}	
	}

	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );	

	self spawn( spawnpoint.origin, spawnpoint.angles );

	level notify ( "spawned_player" );
	
	//maps\mp\gametypes\_globallogic::HajasRemoveHardpoints_player( self );
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
}

CalculaSpawnsDefesa()
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = level.spread/2;

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
			{
				spawn_count++;
			}
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 200;
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
		dist = distance(level.defender_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
		{
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
		}
	}	
}

CalculaSpawnsAtaque()
{
	// inicia spaws da defesa
	level.AtaqueSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = level.spread/2;

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
			{
				spawn_count++;
			}
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 200;
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
		dist = distance(level.attack_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
		{
			level.AtaqueSpawns[level.AtaqueSpawns.size] = spawnpoints[i];
		}
	}	
}


// ==================================================================================================================
//   Controla Score
// ==================================================================================================================

EscapeUpdateScore ( team )
{
	[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + 1 );
}

CalculaPontos( team )
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == team )
		{
			if ( isAlive( player ) )
			{
				EscapeUpdateScore ( team );
			}
		}
	}
	
	// pega tempo que passou
	tempo_passou = (maps\mp\gametypes\_globallogic::getTimePassed() / 1000);
	tempo_passou = (tempo_passou/60);
	tempo_falta = int( getDvarFloat("scr_evac_timelimit") - tempo_passou );
	pontos_elimina = tempo_falta * 10;
	[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + pontos_elimina );
}


// ==================================================================================================================
//   Game Over
// ==================================================================================================================

sd_endGame( winningTeam, endReasonText )
{
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onDeadEvent( team )
{
	if ( team == "all" )
	{
		winner = "tie";

		if ( [[level._getTeamScore]]( game["defenders"] ) > [[level._getTeamScore]]( game["attackers"] ) )
			winner = game["defenders"];
		else if ( [[level._getTeamScore]]( game["defenders"] ) < [[level._getTeamScore]]( game["attackers"] ) )
			winner = game["attackers"];

		sd_endGame( winner, game["strings"]["time_limit_reached"] );			
	}
	else if ( team == game["attackers"] )
	{
		// vitória da defesa pois eliminou todos inimigos
		CalculaPontos( game["defenders"] );
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		CalculaPontos( game["attackers"] );
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}

onOneLeftEvent( team )
{
	warnLastPlayer( team );
}


onTimeLimit()
{
	winner = "tie";

	if ( [[level._getTeamScore]]( game["defenders"] ) > [[level._getTeamScore]]( game["attackers"] ) )
		winner = game["defenders"];
	else if ( [[level._getTeamScore]]( game["defenders"] ) < [[level._getTeamScore]]( game["attackers"] ) )
		winner = game["attackers"];

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

// ==================================================================================================================
//   Sound
// ==================================================================================================================

playSoundinSpace( alias, origin )
{
	level endon( "game_ended" );

	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 6; // MP doesn't have "sounddone" notifies =(
	org delete();
}

TocaAlarme()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	wait 2;
	
	while ( !level.gameEnded )
	{		
		maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
		wait 33;
	}
}

// ==================================================================================================================
//   Mensagens
// ==================================================================================================================

SetaMensagens()
{
	if ( getDvar( "scr_evac_msg" ) == "" )
	{
		level.evac_msg =  "^7Evac our ^9Men ^7out of here^9!";
	}
	else
	{
		level.evac_msg = getDvar( "scr_evac_msg" );
	}
	
	if ( getDvar( "scr_escape_mark" ) == "" )
	{
		level.escape_mark =  "^1Warning ^0: ^7Extraction Point Marked!";
	}
	else
	{
		level.escape_mark = getDvar( "scr_escape_mark" );
	}	
}