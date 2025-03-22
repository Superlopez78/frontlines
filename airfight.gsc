#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	SetDvar( "hajas_weapons", 0 );		
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "airfight", 15, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "airfight", 500, 0, 5000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "airfight", 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "airfight", 0, 0, 100 );
	
	registerChaosChopperDvar( "scr_airfight_choppers", 0, 0, 4 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;		
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	game["dialog"]["gametype"] = "hardcore_tm_death";
}

onPrecacheGameType()
{
	game["alarm_red"] = "alarm_missile_incoming";
	game["alarm_blue"] = "alarm_altitude";	
	
	precacheStatusIcon( "death_helicopter" );
}

onStartGameType()
{
	setClientNameMode("auto_change");

	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_AF_MENU" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_AF_MENU" );
	
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_AF_SCORE" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_AF_SCORE" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_AF_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_AF_HINT" );
			
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
	
	// elimination style
	if ( level.roundLimit != 1 && level.numLives )
	{
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		level.onEndGame = ::onEndGame;
	}
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );
	
	// helis no mapa!
	level.AF_Heli = [];
	
	// contador Heli x Gun x Gunner
	level.AF_HeliCount = 0;
	
	// número de helis vivos
	level.AF_HeliVivosRED = 0;
	level.AF_HeliVivosBLU = 0;
	
	level.MaxHelis = level.ChaosChopper;
	if ( level.ChaosChopper == 0 || getDvarInt("fl_bots") == 1 )
	{
		level.MaxHelis = 1;
		thread CalculaNumHelis();
	}
}

CalculaNumHelis()
{
	while ( level.inPrematchPeriod )
		wait 1;

	if ( getDvarInt("fl_bots") == 1 )
	{
		if ( getDvarInt("fl_bots_num_ori") <= 8 )
			level.MaxHelis = 4;	
		else if ( getDvarInt("fl_bots_num_ori") > 8 && getDvarInt("fl_bots_num_ori") <= 16 )
			level.MaxHelis = 1;	
		else if ( getDvarInt("fl_bots_num_ori") > 16 && getDvarInt("fl_bots_num_ori") <= 30 )
			level.MaxHelis = 2;	
		else if ( getDvarInt("fl_bots_num_ori") > 30 && getDvarInt("fl_bots_num_ori") <= 50 )
			level.MaxHelis = 3;
		else if ( getDvarInt("fl_bots_num_ori") > 50 )
			level.MaxHelis = 4;
	
		return;
	}

	if ( level.players.size <= 8 )
		level.MaxHelis = 4;	
	else if ( level.players.size > 8 && level.players.size <= 16 )
		level.MaxHelis = 1;	
	else if ( level.players.size > 16 && level.players.size <= 30 )
		level.MaxHelis = 2;	
	else if ( level.players.size > 30 && level.players.size <= 50 )
		level.MaxHelis = 3;
	else if ( level.players.size > 50 )
		level.MaxHelis = 4;
}

onSpawnPlayer()
{
	self.usingObj = undefined;
	spawnPoints   = undefined;
	spawnPoint    = undefined;
	self.gunner = false;
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::SpawnPlayer( false, false, false );	

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

	if(!isDefined(self.bIsBot))	
	{
		if ( self.pers["team"] == "allies" )
		{	
			if ( level.AF_HeliVivosBLU < level.MaxHelis )
			{
				self.gunner = true;
				self spawn( spawnPoint.origin, spawnPoint.angles );	
				self hide();			
				self takeAllWeapons();
				level.AF_HeliCount++;
				level.AF_HeliVivosBLU++;		
				thread AF_Heli( self.team, level.AF_HeliCount, self );
				
			}
		}
		else if ( self.pers["team"] == "axis" )
		{	
			if ( level.AF_HeliVivosRED < level.MaxHelis )
			{
				self.gunner = true;
				self hide();
				self spawn( spawnPoint.origin, spawnPoint.angles );	
				self takeAllWeapons();
				level.AF_HeliCount++;
				level.AF_HeliVivosRED++;
				thread AF_Heli( self.team, level.AF_HeliCount, self );
			}
		}
	}
	
	if(isDefined(self.bIsBot) && self.bIsBot)	
	{
		self spawn( spawnPoint.origin, spawnPoint.angles );
			
		if ( self.pers["team"] == "allies" )
		{	
			if ( level.AF_HeliVivosBLU < level.MaxHelis )
			{
				level notify ( "spawned_player" );
				self.gunner = true;
				self hide();			
				//self spawn( spawnPoint.origin, spawnPoint.angles );
				self takeAllWeapons();
				level.AF_HeliCount++;
				level.AF_HeliVivosBLU++;		
				thread AF_Heli( self.team, level.AF_HeliCount, self );
				
			}
		}
		else if ( self.pers["team"] == "axis" )
		{	
			if ( level.AF_HeliVivosRED < level.MaxHelis )
			{
				level notify ( "spawned_player" );
				self.gunner = true;
				self hide();
				//self spawn( spawnPoint.origin, spawnPoint.angles );	
				self takeAllWeapons();
				level.AF_HeliCount++;
				level.AF_HeliVivosRED++;
				thread AF_Heli( self.team, level.AF_HeliCount, self );
			}
		}		
	}

	if ( self.gunner == false )
	{
		if( isDefined( self.mira_overlay ) )
			self.mira_overlay destroy();		

		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
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

		self show();
		
		level notify ( "spawned_player" );
	}
}

// ========================================================================
//		Heli-Gunner
// ========================================================================

AF_Heli( team, squad, player )
{
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait 1;

	if(isDefined(player.bIsBot) && player.bIsBot == true)
	{	wait 1;		
		wait randomfloatrange(0,10);		
	}
	
	level AF_HelitriggerHardPoint( "helicopter_mp", team, squad, player );
}

// executa heli
AF_HelitriggerHardPoint( hardpointType, team, squad, player )
{
	// hardpointType == "helicopter_mp" 
	
	if ( !isDefined( level.heli_paths ) || !level.heli_paths.size )
		return false;
   
	destination = 0;
	random_path = randomint( level.heli_paths[destination].size );
	startnode = level.heli_paths[destination][random_path];
	
	// axis ou allies
	otherTeam = level.otherTeam[team];
	thread maps\mp\_helicopter::AF_heli_think( player, startnode, team, squad );	
}

AF_Gunner(squad)
{
	level endon( "game_ended" );
	self endon("death");
	self endon("disconnect");	
	
	self.gunsquad = squad;
	
	// preciso disso pra só mover o gunner quando o heli nascer
	while ( !isDefined(level.AF_Heli[squad]) ) 
		wait 0.1;	

	// garante que o Class rode antes! senão apagar arma do gunner		
	wait 0.3;

	// cria MG no Heli
	level.AF_Heli[squad].gun = spawn ("script_model",(0,0,0));
	if ( self.team == "allies" )
		level.AF_Heli[squad].gun.origin = level.AF_Heli[squad].origin + (0,0,-250);
	else
		level.AF_Heli[squad].gun.origin = level.AF_Heli[squad].origin + (0,0,-200);

	level.AF_Heli[squad].gun.angles = level.AF_Heli[squad].angles;
	level.AF_Heli[squad].gun linkto (level.AF_Heli[squad]);

	// move e linka soldado na MG
	self setorigin(level.AF_Heli[squad].gun.origin);
	self setplayerangles(level.AF_Heli[squad].gun.angles);
	self linkto (level.AF_Heli[squad].gun);

	self hide();
	self freezeControls( false );
	self giveWeapon( "mp44_mp" );
	self switchToWeapon( "mp44_mp" );
	self SetActionSlot( 1, "nightvision" );
	
	thread executaOverlay( "ac130_overlay_25mm");
	thread FazFX();
	
	self.statusicon = "death_helicopter";
}

KillGunner( player, attacker )
{
	if ( isDefined(attacker) )
		player.HeliAttacker = attacker;

	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( !player.gunner )
			return;
	}

	player suicide();
}

// ========================================================================
//		FX
// ========================================================================

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
		//self switchToWeapon( "colt45_mp" );		
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

TirosFX(center, weapon)
{
	wait 0.1;
	physicsExplosionSphere(center, 200, 200 / 2, 0.5);
}

// funcao pra registrar 
registerChaosChopperDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.ChaosChopperDvar = dvarString;
	level.ChaosChopperMin = minValue;
	level.ChaosChopperMax = maxValue;
	level.ChaosChopper = getDvarInt( level.ChaosChopperDvar );
}

// ========================================================================
//		GameOver
// ========================================================================

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if( isDefined( self.mira_overlay ) )
		self.mira_overlay destroy();
		
	if(isDefined(self.overheat_bg)) self.overheat_bg destroy();
	if(isDefined(self.overheat_status)) self.overheat_status destroy();
}

onEndGame( winningTeam )
{
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
}
