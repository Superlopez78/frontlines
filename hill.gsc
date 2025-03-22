#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar HillSwarm
registerHillSwarmDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.HillSwarmDvar = dvarString;
	level.HillSwarmMin = minValue;
	level.HillSwarmMax = maxValue;
	level.HillSwarm = getDvarInt( level.HillSwarmDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	registerHillSwarmDvar( "scr_hill_swarm", 0, 0, 1 );

	if ( level.HillSwarm == 0 )
		init();
	else if ( level.HillSwarm == 1 )
	{
		maps\mp\gametypes\swarm::init();
		return;
	}
}

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "hill", 30, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "hill", 300, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "hill", 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "hill", 0, 0, 10 );

	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	// dobro tempo de espera pra quem t� na defesa
	level.onRespawnDelay = ::getRespawnDelay;

	game["dialog"]["gametype"] = "captureflag";
	game["dialog"]["offense_obj"] = "captureflag";
	game["dialog"]["defense_obj"] = "captureflag";
	
	game["dialog"]["ourflag"] = "ourflag";
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	game["dialog"]["enemyflag"] = "enemyflag";
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";	
}


onPrecacheGameType()
{
	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );

	precacheShader( "waypoint_captureneutral" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
}


onStartGameType()
{	
	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_HILL_MAIN" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_HILL_MAIN" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_HILL_MAIN" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_HILL_MAIN" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_HILL_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_HILL_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_HILL_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_HILL_HINT" );

	setClientNameMode("auto_change");

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dom_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dom_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// posi��o spawns para marcar spawns da defesa/ataque!
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_dom_spawn_allies_start" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_dom_spawn_axis_start" );
	
	//logprint( level.mapCenter );
	
	level.spawn_all = getentarray( "mp_dom_spawn", "classname" );
	level.spawn_axis_start = getentarray("mp_dom_spawn_axis_start", "classname" );
	level.spawn_allies_start = getentarray("mp_dom_spawn_allies_start", "classname" );
	
	level.startPos["allies"] = level.spawn_allies_start[0].origin;
	level.startPos["axis"] = level.spawn_axis_start[0].origin;
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "dom";
//	allowed[1] = "hardpoint";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	novos_flag_init();
		
	domFlags();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "dom,tdm" );
}


onSpawnPlayer()
{
	spawnpoint = undefined;
	
	FlagTeam = level.flags[0] getFlagTeam();
	
	if ( FlagTeam != "neutral" )
	{
		if ( FlagTeam == self.pers["team"] )
		{
			// spawn near our flag
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( getOwnedFlagSpawns( FlagTeam ) );
			//iPrintLnbold( "Spawn do lado da Flag!" );
		}
		else
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
			//iPrintLnbold( "Spawn longe da Flag!" );
		}
	}
	else
	{
		if (self.pers["team"] == "axis")
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_axis_start);
		else
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_allies_start);	
		//iPrintLnbold( "Spawn Inicial!" );
	}
	
	assert( isDefined(spawnpoint) );
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( FlagTeam != "neutral" && FlagTeam != self.pers["team"] )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
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

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( 10.0 );
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

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
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
	
	FlagTeam = level.flags[0] getFlagTeam();
	if ( team != FlagTeam && FlagTeam != "neutral" )
	{	
		if ( team == "axis" )
		{
			[[level._setTeamScore]]( "allies", [[level._getTeamScore]]( "allies" ) + 1 );
		}
		else if ( team == "allies" )
		{
			[[level._setTeamScore]]( "axis", [[level._getTeamScore]]( "axis" ) + 1 );
		}
	}
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
	
	// diz q � a �nica flag
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

getRespawnDelay()
{
	FlagTeam = level.flags[0] getFlagTeam();
	
	if ( FlagTeam == self.pers["team"] )
	{
		timeremaining = 15;
	
		if( getDvarInt( "scr_hill_waverespawndelay" ) > 0 )
		{
			timeRemaining = getDvarInt( "scr_hill_waverespawndelay" ) * 2;
		}
		else if ( getDvarInt( "scr_hill_playerrespawndelay" ) > 0 )
		{
			timeRemaining = getDvarInt( "scr_hill_playerrespawndelay" ) * 2;
		}		
		return (int(timeRemaining));
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
			logprint( "======================== N�o V�lido A!!! " + "\n");
		}
		level.xflag_selected[0] = level.xflag_a[id_a];
		level.xflag_a = removeFlagArray(level.xflag_a, id_a);	
		
		id_b = RandomInt(level.xflag_b.size);
		while ( ObjValido(level.xflag_b[id_b]) == false )
		{
			id_b = RandomInt(level.xflag_b.size);
			logprint( "======================== N�o V�lido B!!! " + "\n");
		}
		level.xflag_selected[1] = level.xflag_b[id_b];
		level.xflag_b = removeFlagArray(level.xflag_b, id_b);	
		
		id_c = RandomInt(level.xflag_c.size);
		while ( ObjValido(level.xflag_c[id_c]) == false )
		{
			id_c = RandomInt(level.xflag_c.size);
			logprint( "======================== N�o V�lido C!!! " + "\n");
		}
		level.xflag_selected[2] = level.xflag_c[id_c];
		level.xflag_c = removeFlagArray(level.xflag_c, id_c);
		
		if ( level.NumFlagsOri > 3 )
		{
			id_d = RandomInt(level.xflag_d.size);
			while ( ObjValido(level.xflag_d[id_d]) == false )
			{
				id_d = RandomInt(level.xflag_d.size);
				logprint( "======================== N�o V�lido D!!! " + "\n");
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
				logprint( "======================== N�o V�lido E!!! " + "\n");
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


	NewFlags = randomInt(3); // decide se v�o ter +3 flags
	
	if ( level.NumFlagsOri == 4 )
		NewFlags = randomInt(2); // fica com 4 ou vai pra 5
	else if ( level.NumFlagsOri == 5 )
		NewFlags = 0; // com 5 fica com 5 sempre!
	
	//NewFlags = 2; // teste for�ar sempre 2
	
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
	if ( NewFlags == 0 ) // n�o tem +3, mapas com +3 tem q ser removidas!
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
