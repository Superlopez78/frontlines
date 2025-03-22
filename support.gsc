#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerSupportGunner2Dvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.SupportGunner2Dvar = dvarString;
	level.SupportGunner2Min = minValue;
	level.SupportGunner2Max = maxValue;
	level.SupportGunner2 = getDvarInt( level.SupportGunner2Dvar );
}

// funcao pra registrar 
registerSupportGunner3Dvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.SupportGunner3Dvar = dvarString;
	level.SupportGunner3Min = minValue;
	level.SupportGunner3Max = maxValue;
	level.SupportGunner3 = getDvarInt( level.SupportGunner3Dvar );
}

// funcao pra registrar class dos gunners
registerSupportGunnerClassDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.SupportGunnerClassDvar = dvarString;
	level.SupportGunnerClassMin = minValue;
	level.SupportGunnerClassMax = maxValue;
	level.SupportGunnerClass = getDvarInt( level.SupportGunnerClassDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "support", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "support", 6, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "support", 0, 0, 15000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "support", 10, 0, 30 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "support", 50, 50, 50 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "support", 1, 0, 1 );
	
	// define quantos players x gunners
	registerSupportGunner2Dvar( "scr_support_gunner_2", 20, 6, 65 );
	registerSupportGunner3Dvar( "scr_support_gunner_3", 30, 8, 65 );

	// registra classe default pro heavy gunner	
	registerSupportGunnerClassDvar( "scr_support_gunner_class", 0, 0, 5 );
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onPlayerDisconnect = ::onPlayerDisconnect;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "searchdestroy";
	game["dialog"]["offense_obj"] = "obj_destroy";
	game["dialog"]["defense_obj"] = "obj_defend";
}


onPrecacheGameType()
{
	precacheShader("ac130_overlay_25mm");
	
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
	
	game["alarm_red"] = "alarm_missile_incoming";
	game["alarm_blue"] = "alarm_altitude";	
	
	precacheShader( "waypoint_targetneutral" );
	precacheStatusIcon( "death_helicopter" );
	precacheStatusIcon( "specialty_longersprint" );
}


// ========================================================================
//		Brain
// ========================================================================

onStartGameType()
{
	level.HeliSupportA = undefined;
	level.HeliSupportB = undefined;
	level.HeliSupportC = undefined;
	level.GunnerA = undefined;
	level.GunnerB = undefined;
	level.GunnerC = undefined;
	
	//level.SupportLiberaGame = false;

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
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_SUPPORT_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_SUPPORT_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_SUPPORT_ATTACKER_SCORE" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SUPPORT_DEFENDER_SCORE" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_SUPPORT_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_SUPPORT_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	
	// define pos Zulu
	level.EscapeZone = level.attack_spawn;
	
	// diz que Zulu ainda não foi marcada
	level.ZuluRevealed = false;
	level.ZuluRevealedStartou = false;
	
	// carrega fumaça
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");		
	
	// calcula tamanho do mapa
	level.tamanho = distance( level.attack_spawn, level.defend_spawn );
	level.spread = int(level.tamanho/2);			
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	
	maps\mp\gametypes\_gameobjects::main(allowed);

	thread updateGametypeDvars();
	
	novos_sd_init();
	
	thread bombs();
		
	CalculaSpawnsDefesa();
	SetaMensagens();
	
	//thread maps\mp\gametypes\_globallogic::SupportLiberaPlayers();
	thread HeliSupport();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}

// ========================================================================
//		Heli Support
// ========================================================================

HeliSupport()
{
	level endon( "game_ended" );
	
	server_vazio = 0;
	
	while ( level.inPrematchPeriod )
		wait 1;
	
	// não pode ser jogado com MENOS de 4 players!	
	while ( level.players.size < 4 ) // 4
	{
		wait 1;
		server_vazio++;
		if ( server_vazio > 50 )
		{
			temp = strtok( level.BasicGametypes, " " );
			SetDvar( "fl", temp[RandomInt(temp.size)] );

			return;
		}
	}
		
	thread ControlaAtaque();

	// Gunner #1
	while ( !isDefined(level.GunnerA) )
	{
		thread Support_HeliPlayer( game["attackers"], "A" );
		wait 1;
	}

	//iprintlnbold( level.GunnerA.name );
	
	if ( !level.GunnerA.hasSpawned ) // se ele ainda não deu spawn, espera!
		wait 1;

	// inicia chopper
	thread SupportHeli( game["attackers"], "A" );

	// manda o player pro heli		
	level.GunnerA thread EhSupport( "A" );

	// Gunner #2
	if ( level.players.size >= level.SupportGunner2 ) // 6 no mínimo
	{
		while ( !isDefined(level.GunnerB) )
		{
			thread Support_HeliPlayer( game["attackers"], "B" );
			wait 1;
		}	
		
		//iprintlnbold( level.GunnerB.name );

		// aguarda pra não se misturarem	
		//wait 10;

		if ( !level.GunnerB.hasSpawned ) // se ele ainda não deu spawn, espera!
			wait 1;

		// inicia chopper
		thread SupportHeli( game["attackers"], "B" );
		
		// manda o player pro heli		
		if ( isDefined(level.GunnerB) )
			level.GunnerB thread EhSupport( "B" );	
	}
	//else
	//	level.SupportLiberaGame = true;
	
	// Gunner #3
	if ( level.players.size >= level.SupportGunner3 ) // 8 no mínimo
	{
		while ( !isDefined(level.GunnerC) )
		{
			thread Support_HeliPlayer( game["attackers"], "C" );
			wait 1;
		}

		//iprintlnbold( level.GunnerC.name );

		// aguarda pra não se misturarem	
		//wait 10;
		
		if ( !level.GunnerC.hasSpawned ) // se ele ainda não deu spawn, espera!
			wait 1;		

		// inicia chopper
		thread SupportHeli( game["attackers"], "C" );
		
		// manda o player pro heli
		if ( isDefined(level.GunnerC) )
			level.GunnerC thread EhSupport( "C" );	
	}
	
	// se chegou aqui libera com ou sem o 3° gunner
	//level.SupportLiberaGame = true;
}

EhSupport( squad )
{
	level endon( "game_ended" );
	self endon("death");
	self endon("disconnect");	
	
	// dropa bomba se tiver com ela!
	if ( isDefined( self.carryObject ) )
		self.carryObject thread maps\mp\gametypes\_gameobjects::setDropped();		
	
	// enquanto nao tem chopper aguarda		
	if ( squad == "A" )
	{
		while ( !isDefined(level.HeliSupportA) ) 
			wait 0.1;	

		// cria MG no Heli
		level.HeliGunA = spawn ("script_model",(0,0,0));
		if ( self.team == "allies" )
			level.HeliGunA.origin = level.HeliSupportA.origin + (0,0,-250);
		else
			level.HeliGunA.origin = level.HeliSupportA.origin + (0,0,-200);
		level.HeliGunA.angles = level.HeliSupportA.angles;
		level.HeliGunA linkto (level.HeliSupportA);

		// move e linka soldado na MG
		self setorigin(level.HeliGunA.origin);
		self setplayerangles(level.HeliGunA.angles);
		self linkto (level.HeliGunA);
			
	}
	else if ( squad == "B" )
	{
		while ( !isDefined(level.HeliSupportB) ) 
			wait 0.1;	
			
		// cria MG no Heli
		level.HeliGunB = spawn ("script_model",(0,0,0));
		if ( self.team == "allies" )
			level.HeliGunB.origin = level.HeliSupportB.origin + (0,0,-250);
		else
			level.HeliGunB.origin = level.HeliSupportB.origin + (0,0,-200);
		level.HeliGunB.angles = level.HeliSupportB.angles;
		level.HeliGunB linkto (level.HeliSupportB);

		// move e linka soldado na MG
		self setorigin(level.HeliGunB.origin);
		self setplayerangles(level.HeliGunB.angles);
		self linkto (level.HeliGunB);			
	}
	else if ( squad == "C" )
	{
		while ( !isDefined(level.HeliSupportC) ) 
			wait 0.1;	
			
		// cria MG no Heli
		level.HeliGunC = spawn ("script_model",(0,0,0));
		if ( self.team == "allies" )
			level.HeliGunC.origin = level.HeliSupportC.origin + (0,0,-250);
		else
			level.HeliGunC.origin = level.HeliSupportC.origin + (0,0,-200);
		level.HeliGunC.angles = level.HeliSupportC.angles;
		level.HeliGunC linkto (level.HeliSupportC);

		// move e linka soldado na MG
		self setorigin(level.HeliGunC.origin);
		self setplayerangles(level.HeliGunC.angles);
		self linkto (level.HeliGunC);			
	}	

	// diz que é gunner
	self.gunner = true;
	self hide();
	self takeAllWeapons();
	self giveWeapon( "mp44_mp" );
	self switchToWeapon( "mp44_mp" );
	self SetActionSlot( 1, "nightvision" );
	
	if (isDefined(self.bIsBot) && self.bIsBot)
	{
		self.weaponPrefix = "mp44_mp";
		self switchToWeapon( "mp44_mp" );
		self.maxEngageRange = 4000;
	}	
	
	self thread Gunner();
	thread executaOverlay( "ac130_overlay_25mm");
	thread FazFX();
	
	self.statusicon = "death_helicopter";
	
	if ( level.SidesMSG == 1 )
		self iPrintLnBold( level.support_escort );	
}

Gunner()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );	

	self thread GunnerWeapon();
	
	while ( isDefined(self.gunner) && self.gunner )
		wait 0.5;
	
	self OverheatRemoveHUD();
}

GunnerWeapon()
{
	self endon("disconnect");
	self endon("death");

	level.overheat_heatrate = 4;
	level.overheat_coolrate = 6;
	
	self.heat_rate = level.overheat_heatrate / 2;
	self.heat_status = 1;
	self.heat_danger = 80;
	self.heat_max = 114;
	self.cool_rate = level.overheat_coolrate;
	self thread OverheatDrain();
	
	self.heat = false;

	while( isDefined(self.gunner) && self.gunner )
	{
		self thread OverheatShowHUD();

		while(self useButtonPressed()) wait 0.05;

		for(;;)
		{
			wait 0.05;

			// turret overheating
			if(isDefined(self) && self attackButtonPressed())
			{
				if(self.heat_status < self.heat_max)
				{
					self.heat_status = self.heat_status + self.heat_rate;
					if(self.heat_status > self.heat_max) self.heat_status = self.heat_max;
				}

				if(self.heat_status == self.heat_max)
				{
					self thread CyborgHeatAlarm();
					self thread maps\mp\gametypes\_globallogic::ExecClientCommand("-attack; +activate; wait 10; -activate");
				}
			}
			self thread OverheatUpdateHUD();
		}
	}
}

CyborgHeatAlarm()
{
	self endon("disconnect");
	self endon("death");
	
	if ( self.heat == false )
	{
		self.heat = true;
		self playLocalSound(game["cyborg_alarm"]);
		//self iprintlnbold("^1Overheat Warning!");
		wait 10;
		self.heat = false;
	}
}

OverheatDrain()
{
	self endon("disconnect");
	self endon("death");

	frames = getDvarInt("sv_fps");

	for(;;)
	{
		wait 0.05;

		if(self.heat_status > 1)
		{
			difference = self.heat_status - (self.heat_status - self.cool_rate);
			frame_difference = (difference / frames);

			for(i = 0; i < frames; i++)
			{
				self.heat_status -= frame_difference;
				if(self.heat_status < 1)
				{
					self.heat_status = 1;
					break;
				}
				wait 0.05;
			}
		}
	}
}

OverheatUpdateHUD()
{
	self endon("disconnect");
	self endon("death");

	if(isDefined(self.overheat_status) && self.heat_status > 1)
	{
		self.overheat_status scaleovertime( 0.1, 10, int(self.heat_status));
		self.overheat_status.color = OverheatSetColor();
		wait 0.1;
	}
}

OverheatSetColor()
{
	self endon("disconnect");
	self endon("death");

	// define what colors to use
	color_cold = [];
	color_cold[0] = 1.0;
	color_cold[1] = 1.0;
	color_cold[2] = 0.0;
	color_warm = [];
	color_warm[0] = 1.0;
	color_warm[1] = 0.5;
	color_warm[2] = 0.0;
	color_hot = [];
	color_hot[0] = 1.0;
	color_hot[1] = 0.0;
	color_hot[2] = 0.0;

	// default color
	SetValue = [];
	SetValue[0] = color_cold[0];
	SetValue[1] = color_cold[1];
	SetValue[2] = color_cold[2];

	// define where the non blend points are
	cold = 0;
	warm = (self.heat_max / 2);
	hot = self.heat_max;
	value = self.heat_status;

	iPercentage = undefined;
	difference = undefined;
	increment = undefined;

	if( (value > cold) && (value <= warm) )
	{
		iPercentage = int(value * (100 / warm));
		for( colorIndex = 0 ; colorIndex < SetValue.size ; colorIndex++ )
		{
			difference = (color_warm[colorIndex] - color_cold[colorIndex]);
			increment = (difference / 100);
			SetValue[colorIndex] = color_cold[colorIndex] + (increment * iPercentage);
		}
	}
	else if( (value > warm) && (value <= hot) )
	{
		iPercentage = int( (value - warm) * (100 / (hot - warm) ) );
		for( colorIndex = 0 ; colorIndex < SetValue.size ; colorIndex++ )
		{
			difference = (color_hot[colorIndex] - color_warm[colorIndex]);
			increment = (difference / 100);
			SetValue[colorIndex] = color_warm[colorIndex] + (increment * iPercentage);
		}
	}

	return (SetValue[0], SetValue[1], SetValue[2]);
}

OverheatShowHUD()
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(self.overheat_bg))
	{
		self.overheat_bg = newclienthudelem(self);
		self.overheat_bg.alignX = "right";
		self.overheat_bg.alignY = "bottom";
		self.overheat_bg.horzAlign = "right";
		self.overheat_bg.vertAlign = "bottom";
		self.overheat_bg.x = -18;
		self.overheat_bg.y = -170;
		self.overheat_bg.alpha = 0.75; // Transparent
		self.overheat_bg setShader("black", 25, 120);
		self.overheat_bg.sort = 2;
	}

	// status bar
	if(!isDefined(self.overheat_status))
	{
		self.overheat_status = newclienthudelem(self);
		self.overheat_status.alignX = "right";
		self.overheat_status.alignY = "bottom";
		self.overheat_status.horzAlign = "right";
		self.overheat_status.vertAlign = "bottom";
		self.overheat_status.x = -25;
		self.overheat_status.y = -172;
		self.overheat_status setShader("white", 10, int(self.heat_status));
		self.overheat_status.color = OverheatSetColor();
		self.overheat_status.alpha = 1;
		self.overheat_status.sort = 1;
	}
}

OverheatRemoveHUD()
{
	self endon("disconnect");

	if(isDefined(self.overheat_bg)) self.overheat_bg destroy();
	if(isDefined(self.overheat_status)) self.overheat_status destroy();
}


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
	
	if (isDefined(self.bIsBot) && self.bIsBot)
		return;		
	
	for(;;)
	{
		if ( self.gunner == false )
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

proxGunner( team )
{
	players = level.players;
	winner = undefined;

	if ( players.size > 0 )
	{
		// get random player
		
		lista_ataque = [];
		j = 0;

		// cria lista só com a defesa...
		for( i = 0; i < players.size; i++ )
		{
			if ( players[i].pers["team"] == team )
			{
				lista_ataque[j] = players[i];
				j++;
			}
		}	

		if ( isDefined(lista_ataque.size) && lista_ataque.size > 0 )
		{
			// pega id random da lista_ataque
			id_win = randomInt( lista_ataque.size );
		
			// seta o winner
			winner = lista_ataque[id_win];
		}
	}
	return winner;
}

KillGunner( squad )
{
	players = level.players;
	winner = undefined;
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		return;

	/*	
	iprintlnbold("^1Matar do Heli:^7 " + squad );

	if ( isDefined( level.GunnerA ) )
		iprintlnbold("^2Gunner do A:^7 " + level.GunnerA.name );
	if ( isDefined( level.GunnerB ) )
		iprintlnbold("^3Gunner do B:^7 " + level.GunnerB.name );
	if ( isDefined( level.GunnerC ) )
		iprintlnbold("^4Gunner do C:^7 " + level.GunnerC.name );
	*/	
	
	if ( players.size > 0 && squad == "A" )
	{
		// pega o player = level.GunnerA e mata
		for( i = 0; i < players.size; i++ )
		{
			if ( players[i] == level.GunnerA )
			{
				if ( isDefined(level.HeliSupportA) && isDefined(level.HeliSupportA.attacker) )
					players[i].HeliAttacker = level.HeliSupportA.attacker;
				players[i] suicide();
				level.HeliSupportA = undefined;
				level.GunnerA = undefined;
				break;
			}
		}	
	}	
	else if ( players.size > 0 && squad == "B" )
	{
		// pega o player = level.GunnerB e mata
		for( i = 0; i < players.size; i++ )
		{
			if ( players[i] == level.GunnerB )
			{
				if ( isDefined(level.HeliSupportB) && isDefined(level.HeliSupportB.attacker) )
					players[i].HeliAttacker = level.HeliSupportB.attacker;
				players[i] suicide();
				level.HeliSupportB = undefined;
				level.GunnerB = undefined;
				break;
			}
		}	
	}
	else if ( players.size > 0 && squad == "C" )
	{
		// pega o player = level.GunnerC e mata
		for( i = 0; i < players.size; i++ )
		{
			if ( players[i] == level.GunnerC )
			{
				if ( isDefined(level.HeliSupportC) && isDefined(level.HeliSupportC.attacker) )
					players[i].HeliAttacker = level.HeliSupportC.attacker;
				players[i] suicide();
				level.HeliSupportC = undefined;
				level.GunnerC = undefined;
				break;
			}
		}	
	}	
}

// ========================================================================
//		Heli-Gunner
// ========================================================================

// calcula os reforços do Waves
SupportHeli( attackers, squad )
{
	level endon( "game_ended" );
	
	level Support_HelitriggerHardPoint( "helicopter_mp", attackers, squad );
}

// executa heli
Support_HelitriggerHardPoint( hardpointType, attackers, squad )
{
	// hardpointType == "helicopter_mp" 
	
	if ( !isDefined( level.heli_paths ) || !level.heli_paths.size )
		return false;
   
	destination = 0;
	random_path = randomint( level.heli_paths[destination].size );
	startnode = level.heli_paths[destination][random_path];
	
	// axis ou allies
	team = attackers;
	otherTeam = level.otherTeam[team];
	
	// inicia heli com o player
	if ( squad == "A" )
		thread maps\mp\_helicopter::Support_heli_think( level.GunnerA, startnode, attackers, squad );	
	else if ( squad == "B" )
		thread maps\mp\_helicopter::Support_heli_think( level.GunnerB, startnode, attackers, squad );	
	else if ( squad == "C" )
		thread maps\mp\_helicopter::Support_heli_think( level.GunnerC, startnode, attackers, squad );	
}

Support_HeliPlayer( attackers, squad )
{
	players = level.players;
	lista_ataque = [];
	j = 0;

	// cria lista só com o ataque...
	for( i = 0; i < players.size; i++ )
	{
		if ( players[i].pers["team"] == attackers )
		{
			lista_ataque[j] = players[i];
			j++;
		}
	}	
	
	// se é random entre os atacantes...
	if ( level.SupportGunnerClass == 0 )
	{
		if ( isDefined(lista_ataque.size))
		{
			if ( lista_ataque.size > 0 )
			{
				// pega id random da lista_ataque
				id_win = randomInt( lista_ataque.size );
				
				if ( squad == "A" )
				{
					if ( lista_ataque[id_win].hasSpawned )
						level.GunnerA = lista_ataque[id_win];
				}
				else if ( squad == "B" )
				{
					while ( lista_ataque[id_win].gunner == true || lista_ataque[id_win].isBombCarrier == true )
					{
						id_win = randomInt( lista_ataque.size );
						if ( level.players.size < level.SupportGunner2 )
							break;
					}
					if ( lista_ataque[id_win].hasSpawned )
						level.GunnerB = lista_ataque[id_win];
					
					// caso continue igual, poe undefined! = sem gunner!
					if ( isDefined(level.GunnerB) )
					{					
						if ( level.GunnerB == level.GunnerA )
							level.GunnerB = undefined;
					}
				}
				else if ( squad == "C" )
				{
					while ( lista_ataque[id_win].gunner == true || lista_ataque[id_win].isBombCarrier == true )
					{
						id_win = randomInt( lista_ataque.size );
						if ( level.players.size < level.SupportGunner3 )
							break;
					}
					if ( lista_ataque[id_win].hasSpawned )
						level.GunnerC = lista_ataque[id_win];
					
					// caso continue igual, poe undefined! = sem gunner!
					if ( isDefined(level.GunnerC) )
					{
						if ( level.GunnerC == level.GunnerA || level.GunnerC == level.GunnerB )
							level.GunnerC = undefined;				
					}
				}			
			}
			else
			{
				iprintlnbold("Not Enough Players to Start!");
			}
		}
		else
		{
			iprintlnbold("Not Enough Players to Start!");
		}
	}
	else // apenas entre os que tiverem classe X
	{
		// 0 = OFF (random player)	// recomended to open servers
		// 1 = Assault
		// 2 = Spec Opcs
		// 3 = Heavy Gunner
		// 4 = Demolitions
		// 5 = Sniper
		
		gunner_class = "CLASS_HEAVYGUNNER";
		
		switch( level.SupportGunnerClass )
		{
			case 1:
				gunner_class = "CLASS_ASSAULT";
				break;
			case 2:
				gunner_class = "CLASS_SPECOPS";
				break;
			case 3:
				gunner_class = "CLASS_HEAVYGUNNER";
				break;
			case 4:
				gunner_class = "CLASS_DEMOLITIONS";
				break;
			case 5:
				gunner_class = "CLASS_SNIPER";
				break;
		}
		
		lista_gunner = [];
		g = 0;
		
		if ( isDefined(lista_ataque.size))
		{
			if ( lista_ataque.size > 0 )
			{
				// cria lista só player da classe Gunner...
				for( i = 0; i < lista_ataque.size; i++ )
				{
					if ( players[i].pers["class"] == gunner_class )
					{
						lista_gunner[g] = players[i];
						g++;
					}
				}		
	
				if ( squad == "A" )
				{
					if ( lista_gunner.size > 0 ) 
					{
						// tem com a classe gunner peda de lá, senão pega random
						id_win = randomInt( lista_gunner.size );
						
						if ( lista_gunner[id_win].hasSpawned )
							level.GunnerA = lista_gunner[id_win];						
					}
					else
					{
						// pega id random da lista_ataque
						id_win = randomInt( lista_ataque.size );

						if ( lista_ataque[id_win].hasSpawned )
							level.GunnerA = lista_ataque[id_win];
					}
				}
				else if ( squad == "B" )
				{
					if ( lista_gunner.size > 1 ) 
					{
						// tem com a classe gunner peda de lá, senão pega random
						id_win = randomInt( lista_gunner.size );
						
						// tem com a classe gunner peda de lá, senão pega random
						while ( lista_gunner[id_win].gunner == true || lista_gunner[id_win].isBombCarrier == true )
						{
							id_win = randomInt( lista_gunner.size );
							if ( level.players.size < level.SupportGunner2 )
								break;
						}
						if ( lista_gunner[id_win].hasSpawned )
							level.GunnerB = lista_gunner[id_win];
						
						// caso continue igual, poe undefined! = sem gunner!
						if ( isDefined(level.GunnerB) )
						{					
							if ( level.GunnerB == level.GunnerA )
								level.GunnerB = undefined;
						}					
					}
					else
					{
						// pega id random da lista_ataque
						id_win = randomInt( lista_ataque.size );
											
						while ( lista_ataque[id_win].gunner == true || lista_ataque[id_win].isBombCarrier == true )
						{
							id_win = randomInt( lista_ataque.size );
							if ( level.players.size < level.SupportGunner2 )
								break;
						}
						if ( lista_ataque[id_win].hasSpawned )
							level.GunnerB = lista_ataque[id_win];
						
						// caso continue igual, poe undefined! = sem gunner!
						if ( isDefined(level.GunnerB) )
						{					
							if ( level.GunnerB == level.GunnerA )
								level.GunnerB = undefined;
						}
					}
				}
				else if ( squad == "C" )
				{
					if ( lista_gunner.size > 1 ) 
					{
						// tem com a classe gunner peda de lá, senão pega random
						id_win = randomInt( lista_gunner.size );
											
						while ( lista_gunner[id_win].gunner == true || lista_gunner[id_win].isBombCarrier == true )
						{
							id_win = randomInt( lista_gunner.size );
							if ( level.players.size < level.SupportGunner3 )
								break;
						}
						if ( lista_gunner[id_win].hasSpawned )
							level.GunnerC = lista_gunner[id_win];
						
						// caso continue igual, poe undefined! = sem gunner!
						if ( isDefined(level.GunnerC) )
						{
							if ( level.GunnerC == level.GunnerA || level.GunnerC == level.GunnerB )
								level.GunnerC = undefined;				
						}					
					}
					else
					{	
						// pega id random da lista_ataque
						id_win = randomInt( lista_ataque.size );					
					
						while ( lista_ataque[id_win].gunner == true || lista_ataque[id_win].isBombCarrier == true )
						{
							id_win = randomInt( lista_ataque.size );
							if ( level.players.size < level.SupportGunner3 )
								break;
						}
						if ( lista_ataque[id_win].hasSpawned )
							level.GunnerC = lista_ataque[id_win];
						
						// caso continue igual, poe undefined! = sem gunner!
						if ( isDefined(level.GunnerC) )
						{
							if ( level.GunnerC == level.GunnerA || level.GunnerC == level.GunnerB )
								level.GunnerC = undefined;				
						}
					}
				}			
			}
			else
			{
				iprintlnbold("Not Enough Players to Start!");
			}
		}
		else
		{
			iprintlnbold("Not Enough Players to Start!");
		}
	}
}


// ========================================================================
//		Player
// ========================================================================

CalculaSpawnsDefesa()
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia mínima para spawn ser válido! pra não nascer dentro da hold line, por isso = 600
	dist_min = 200;

	// distancia maxima para spawn ser válido!
	dist_max = level.spread;

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
			dist = distance(level.defend_spawn, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist > dist_min && dist < dist_max )
			{
				spawn_count++;
			}
		}
		if ( spawn_count < 2 )
		{
			dist_max = dist_max + 100;
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
		dist = distance(level.defend_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist > dist_min && dist < dist_max )
		{
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
		}
	}	
}


onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	self.gunner = false;
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::SpawnPlayer( false, false, false );
	
	if( isDefined( self.mira_overlay ) )
		self.mira_overlay destroy();	

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
			
	if ( self.pers["team"] == game["attackers"] )
	{
		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		local = randomInt(10);
		if( local > 3 )
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
		else
		{
			spawnPoints = getEntArray( spawnPointName, "classname" );
			assert( spawnPoints.size );
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );		
		}
	}

	self spawn( spawnpoint.origin, spawnpoint.angles );

	level notify ( "spawned_player" );
	
	// se deu spawn e ainda não liberou, congela player
	//if ( level.SupportLiberaGame == false )
	//	self freezeControls( true );
	
	// garante que não vai voltar transparente!
	self show();
	
	// testa escape de cada soldado
	if ( self.pers["team"] == game["attackers"] )
		self thread	PlayerRetreat();		
}


onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	// seta como gunner pra saber que não é mais do ground team
	self.gunner = true;

	// apenas time ataque só tem 1 vida!
	if ( self.pers["team"] == game["attackers"] )
		self.pers["lives"] = 0;

	if( isDefined( self.mira_overlay ) )
		self.mira_overlay destroy();
		
	if(isDefined(self.overheat_bg)) self.overheat_bg destroy();
	if(isDefined(self.overheat_status)) self.overheat_status destroy();		
	
	thread checkAllowSpectating();
}


onPlayerDisconnect()
{
	self unlink();
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

// ========================================================================
//		Game Over
// ========================================================================

sd_endGame( winningTeam, endReasonText )
{
	// só dá ponto pra defesa se defender ataque!
	if ( isdefined( winningTeam ) && winningTeam == game["defenders"] )
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

// ========================================================================
//		Bombs
// ========================================================================

bombs()
{
	level.bombPlanted = false;
	level.bombDefused = false;
	level.bombExploded = false;
	
	if ( level.novos_objs )
		novos_sd();	

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
	
	// pega um dos alvos aleatoriamente
	obj_index = randomInt ( bombZones.size );
	
	//logPrint("obj_index = " + obj_index + "\n");
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	obj_trigger = [];
	
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

onBeginUse( player )
{
	if( level.bombExploded )
		return;

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
	
	if( level.bombExploded )
		return;	
	
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

	if ( !level.bombDefused && !level.bombExploded )
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
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );
	
	for ( index = 0; index < level.bombZones.size; index++ )
		level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
	defuseObject maps\mp\gametypes\_gameobjects::disableObject();
	
	//setGameEndTime( 0 );
	
	thread ZuluSmoke();
	Pontua( 10 );
	
	//sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
}

smokeFX( alvo, rot )
{
	alvo = alvo + (0,0,-100);
	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke );
	earthquake( 1, 1.5, alvo, 8000 );		
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
	if( level.bombExploded )
		return;

	level.tickingObject maps\mp\gametypes\_globallogic::stopTickingSound();
	level.bombDefused = true;
	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused");
	
	wait 1.5;
	
	setGameEndTime( 0 );
	
	sd_endGame( game["defenders"], game["strings"]["bomb_defused"] );
}

// ==================================================================================================================
//   Escape Zone - Zulu
// ==================================================================================================================

ZuluSmoke() 
{
	// se já foi revelada aborta!
	if ( level.ZuluRevealedStartou == true )
		return;
		
	level.ZuluRevealedStartou = true;

	wait 3;
	
	level.ZuluRevealed = true;
	
	level.zulu_mark = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", level.EscapeZone + (0,0,70), game["attackers"], "waypoint_targetneutral" );
	level.zulu_mark setWayPoint( true, "waypoint_targetneutral" );	

	thread playSoundinSpace( "smokegrenade_explode_default", level.EscapeZone );

	rot = randomfloat(360);
	zulupoint = spawnFx( level.zulu_point_smoke, level.EscapeZone, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( zulupoint );

	thread ZuluRevealed();
}

ZuluRevealed()
{
	if ( level.SidesMSG == 1 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( player.pers["team"] == game["attackers"] )
			{
				if ( isDefined(player.gunner) && player.gunner == false )
					player iPrintLnBold( level.support_retreat );
			}
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
}

PlayerRetreat()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while(1)
	{
		// se virou gunner aborta loop
		if ( self.gunner )
			return;		
	
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.EscapeZone) < 100 )
			{
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 50 );
				Pontua( 1 );
				if ( level.starstreak > 0 )
					self.fl_stars_pts = self.fl_stars_pts + 3;
				self thread Salvo();
				return;
			} 
		}
		wait 1;
	}
}

Salvo()
{
	wait 0.5;
	
	if( isDefined( self.mira_overlay ) )
		self.mira_overlay destroy();	
		
	if ( isDefined( self.carryObject ) )
		self.carryObject thread maps\mp\gametypes\_gameobjects::setDropped();		
	
	self.gunner = true;

	[[level.spawnSpectator]]();
	
	self.statusicon = "specialty_longersprint";
}

// ==================================================================================================================
//   Score
// ==================================================================================================================

Pontua( ponto )
{
	[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) + ponto );
}

// chamo toda vez que um atacante morre!
ControlaAtaque()
{
	level endon("game_ended");
	ground_team = 0;
	ataque_team = game["attackers"];
	
	while(1)
	{
		wait 5;
		
		//iprintlnbold("Loop de Controle");
		
		if ( level.everExisted[ataque_team] )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];
				if ( player.pers["team"] == game["attackers"] )
				{
					if ( isAlive( player ) )
					{
						// se não for gunner e tá vivo = ground team
						if( player.gunner == false )
							ground_team++;
					}
				}
			}
			
			//iprintlnbold("ground_team = " + ground_team);
			
			if ( ground_team == 0 )
			{
				if ( level.bombExploded == true )
				{
					//iprintlnbold("FinalizaAtaque");
					thread FinalizaAtaque();
					return;
				}
				else if ( level.bombPlanted == false )
				{
					//iprintlnbold("AbandonaAtaque");
					thread AbandonaAtaque();
					return;
				}
			}
			else
				ground_team = 0;	
		}
	}
}

FinalizaAtaque()
{
	level endon("game_ended");
	
	thread RetiradaHelis();

	setGameEndTime( 0 );

	if ( isDefined( level.GunnerC ) && isAlive(level.GunnerC) )
		wait 15;
	else
		wait 10;
	
	thread sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );	
}

AbandonaAtaque()
{
	level endon("game_ended");
	
	thread RetiradaHelis();
	
	setGameEndTime( 0 );

	if ( isDefined( level.GunnerC ) && isAlive(level.GunnerC) )
		wait 15;
	else
		wait 10;
	
	thread sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
}

RetiradaHelis()
{
	level endon("game_ended");
	
	if ( isDefined(level.HeliSupportA) )
	{
		level.HeliSupportA thread maps\mp\_helicopter::heli_leave();
		if ( isDefined( level.GunnerA ) && isAlive(level.GunnerA) )
		{
			wait 2;
			level.GunnerA thread Salvo();
		}
		wait 3;
	}
	if ( isDefined(level.HeliSupportB) )
	{
		level.HeliSupportB thread maps\mp\_helicopter::heli_leave();
		if ( isDefined( level.GunnerB ) && isAlive(level.GunnerB) )
		{
			wait 2;
			level.GunnerB thread Salvo();
		}
		wait 3;
	}
	if ( isDefined(level.HeliSupportC) )
	{
		level.HeliSupportC thread maps\mp\_helicopter::heli_leave();
		if ( isDefined( level.GunnerC ) && isAlive(level.GunnerC) )
		{
			wait 2;
			level.GunnerC thread Salvo();
		}
	}
}

// ==================================================================================================================
//   Mensagens
// ==================================================================================================================

SetaMensagens()
{
	if ( getDvar( "scr_support_escort" ) == "" )
	{
		level.support_escort =  "^7Escort the ^9Ground ^7team!";
	}
	else
	{
		level.support_escort = getDvar( "scr_support_escort" );
	}
	
	if ( getDvar( "scr_support_retreat" ) == "" )
	{
		level.support_retreat =  "^7Retreat to the ^9Zulu ^7point!";
	}
	else
	{
		level.support_retreat = getDvar( "scr_support_retreat" );
	}
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