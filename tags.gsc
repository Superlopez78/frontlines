#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "tags", 10, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "tags", 0, 0, 5000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "tags", 1, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "tags", 0, 0, 1000 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;

	game["dialog"]["gametype"] = "hardcore_tm_death";
	
}

onStartGameType()
{
	setClientNameMode("auto_change");

	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_TAGS_MENU" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_TAGS_MENU" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_TAGS_MENU" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_TAGS_MENU" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_TAGS_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_TAGS_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_TAGS_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_TAGS_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	SetaMensagens();
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "war";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	level.displayRoundEndText = true;
	level.onEndGame = ::onEndGame;
	maps\mp\gametypes\_gameobjects::main(allowed);
	
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

onSpawnPlayer()
{
	self.usingObj = undefined;
	spawnPoints   = undefined;
	spawnPoint    = undefined;
	
	if ( level.HajasWeap == 4 )  // se snipers mode
	{
		spawnPoints = getentarray("mp_tdm_spawn_" + self.pers["team"] + "_start", "classname");

		if ( !spawnPoints.size )
			spawnPoints = getentarray("mp_sab_spawn_" + self.pers["team"] + "_start", "classname");
			
		if ( !spawnPoints.size )
		{
			logPrint( "^1Not enough start TDM spawnpoints!" );
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;		
		}
		else
		{
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
		}
	}
	else
	{
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
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
		}
	}
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 && level.HajasWeap == 4 )
		maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
	else if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		Ganhando = maps\mp\gametypes\_globallogic::getREALLYWinningTeam();
		if ( self.pers["team"] == Ganhando )
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		else
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn( spawnPoint.origin, spawnPoint.angles );
		}
	}
	else
		self spawn( spawnPoint.origin, spawnPoint.angles );
}

onEndGame( winningTeam )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	//if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
	//	[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self thread DropaTags(self.origin, self.clientid, self.team);
}

DropaTags(origin, id, team)
{
	// "hud_status_dead"
	level endon( "game_ended" );
	
	tags_id = level.Tags_counter;
	level.Tags_counter++;
		
	name = "tags_" + tags_id;
	
	origin = PhysicsTrace( origin + (0,0,20), origin - (0,0,2000), false, undefined );	
	
	if ( team == "allies")
    {
		tags = maps\mp\gametypes\_objpoints::createTeamObjpoint( name, origin + (0,0,15), "all", game["icons"]["allies"] );
		tags setWayPoint( true, game["icons"]["allies"] );		
    }
    else
    {
		tags = maps\mp\gametypes\_objpoints::createTeamObjpoint( name, origin + (0,0,15), "all", game["icons"]["axis"] );
		tags setWayPoint( true, game["icons"]["axis"] );		
    }    
	
	OneMinute = 0;
	while (1)
	{
		wait 0.5;
		OneMinute = OneMinute + 0.5;
		for ( i = 0; i < level.players.size; i++ )
		{	
			outro = level.players[i].origin;
			dist = distance( outro, origin );
			if ( dist < 100 && isAlive( level.players[i] ) )
			{
				if ( level.players[i].team == team ) // mesmo time, aborta
				{
					// sound
					level.players[i] iPrintLn ( level.msg_tags_recovered );
					level.players[i] playLocalSound( "oldschool_pickup" );
					maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", level.players[i] );
				}
				else 
				{
					// sound
					level.players[i] iPrintLn ( level.msg_tags_confirmed );
					level.players[i] playLocalSound( "oldschool_pickup" );
					maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", level.players[i] );
					[[level._setTeamScore]]( level.otherTeam[team], [[level._getTeamScore]]( level.otherTeam[team] ) + 10 );
				}
				maps\mp\gametypes\_objpoints::deleteObjPoint( tags );
				return;				
			}
		}
		if ( OneMinute >= 60 )
		{
				maps\mp\gametypes\_objpoints::deleteObjPoint( tags );
				return;				
		}
	}
}

SetaMensagens()
{
	// locais
	
	if ( getDvar( "scr_tags_confirmed" ) == "" )
		level.msg_tags_confirmed =  "^1Kill: ^7CONFIRMED^1!";
	else
		level.msg_tags_confirmed = getDvar( "scr_tags_confirmed" );
	
	if ( getDvar( "scr_tags_recovered" ) == "" )
		level.msg_tags_recovered =  "^1Tag: ^7RECOVERED^1!";
	else
		level.msg_tags_recovered = getDvar( "scr_tags_recovered" );
}