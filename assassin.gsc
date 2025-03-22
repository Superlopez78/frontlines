#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

registerAssassinSpyDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.AssassinSpyDvar = dvarString;
	level.AssassinSpyMin = minValue;
	level.AssassinSpyMax = maxValue;
	level.AssassinSpy = getDvarInt( level.AssassinSpyDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	level.LiveVIP = false;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 5, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 10, 0, 30 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( level.gameType, 0, 0, 3 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( level.gameType, 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerNextVIPDvar( level.gameType, 2, 0, 2 );
	maps\mp\gametypes\_globallogic::registerVIPNameDvar( "scr_assassin_name", 1, 0, 1 );
	
	// registra vars do Assassin/Spy
	registerAssassinSpyDvar( "scr_assassin_spy_mode", 0, 0, 1 );

	// 0 = Random
	// 1 = A
	// 2 = B
	// 3 = Sab
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	
	level.endGameOnScoreLimit = false;
	
	// controlar morte vip/commandante
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;		
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "goodtogo";
	//game["dialog"]["defense_obj"] = "goodtogo";

	level.assassin_blocked = false;
}


onPrecacheGameType()
{
	precacheShader("compass_waypoint_target");
	precacheShader("waypoint_target");

	// assassin/spy
	precacheShader( "specialty_bulletaccuracy" );
	precacheStatusIcon( "specialty_bulletaccuracy" );	
	
	// VIP
	precacheShader( "killiconheadshot" );
	precacheStatusIcon( "killiconheadshot" );	
	
	precacheModel( "prop_suitcase_bomb" );
	
	//sounds
	
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";	
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
	level.strikefoi = false;
	level.WavesProtected = true;

	if ( !isDefined(game["VIPname"]) )
		game["VIPname"] = "";

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
		
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");
	
	// adequa todas as msgs para SPY ou ASSASSIN
	if ( level.AssassinSpy == 1 )
	{
		maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_SPY_DEFENDER" );
		
		if ( level.splitscreen )
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SPY_DEFENDER" );
		}
		else
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER_SCORE" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SPY_DEFENDER_SCORE" );
		}
		
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_SPY_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_ASSASSIN_DEFENDER" );
		
		if ( level.splitscreen )
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_ASSASSIN_DEFENDER" );
		}
		else
		{
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER_SCORE" );
			maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_ASSASSIN_DEFENDER_SCORE" );
		}
		
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_ASSASSIN_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_ASSASSIN_DEFENDER" );		
	}
	
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );

	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );		
		
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "sab";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	maps\mp\gametypes\_rank::registerScoreInfo( "win", 1 );
	maps\mp\gametypes\_rank::registerScoreInfo( "loss", 1 );
	maps\mp\gametypes\_rank::registerScoreInfo( "tie", 1 );
	
	thread bombs();
	
	SetaMensagens();
	
	if ( getDvar( "scr_assassin_time" ) == "" )
		AssTime =  20;
	else
		AssTime = getDvarInt( "scr_assassin_time" );
	
	thread maps\mp\gametypes\_globallogic::AssassinLiberaAtaque( AssTime );
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );	
}

onSpawnPlayer()
{
	self.isCommander = false;
	
	// inicializa array com spawns do ass
	ass_spawns = [];
	
	if(self.pers["team"] == game["attackers"])
	{
		spawnPointName = "mp_sd_spawn_attacker";
	}
	else
	{
		spawnPointName = "mp_sd_spawn_defender";
		
		// origin do spawn do VIP + escort
		spawn_escort_origin = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
		
		// distancia min pra valer o spawn
		nearestdist = 1500;
	
		// adiciona apenas os spawnpoints perto da flag
		spawnpoints = getentarray("mp_tdm_spawn", "classname");

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
				dist = distance(spawn_escort_origin, spawnpoints[i].origin);
				//logPrint("dist[ " + i + " ] = " + dist + "\n");
				if ( dist > nearestdist)
				{
					spawn_count++;
				}
			}
			if ( spawn_count < 1 )
			{
				nearestdist = nearestdist - 500;
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
			dist = distance(spawn_escort_origin, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist > nearestdist)
			{
				ass_spawns[ass_spawns.size] = spawnpoints[i];
			}
		}	
		//logPrint("spawnsize = " + ass_spawns.size + "\n");
	}
	
	// deleta skin do vip/commander se sobrou do round anterior
	if ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP" )
		VIPloadModelBACK();

	if ( self.pers["team"] == game["attackers"] )
	{
		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		assert( ass_spawns.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( ass_spawns );	
	}

	self spawn( spawnpoint.origin, spawnpoint.angles );

	level notify ( "spawned_player" );
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints_player( self );
	
	if ( level.LiveVIP == false && self.pers["team"] == game["attackers"])
	{
		// next = 0 : último ìd
		// next = 1 : melhor score 
		// next = 2 : random
		
		if ( level.NextVIP > 0 )
		{
			// caso não volte nada, será o primeiro sempre...
			if ( game["VIPname"] == "" )
				SpawnVIP();
			else
			{
				if ( game["VIPname"] == self.name )
					SpawnVIP();
				else
					SpawnSoldado();
			}
		}
		else
			SpawnVIP();
	}
	else
		SpawnSoldado();
	
	if ( self.pers["team"] == game["attackers"] )
	{
		if( level.strikefoi == false )
			self freezeControls( true );
	}
}

VIPnoTimeCerto( team )
{
	for( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i].pers["team"] == team )
		{
			if ( level.players[i].name == game["VIPname"] )
				return true;
		}
	}
	return false;
}

SpawnVIP()
{
	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
		self iPrintLnbold( level.assassin_you );
	
	self createVipIcon();

	// troca a skin pra VIP/Commander
	VIPloadModel(); 	
	
	// diz q o mapa já tem um vip/commander vivo
	level.LiveVIP = true;	
	
	// icone defend!
	//self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	
	// seta nome do Commander para mostrar na tela
	level.ShowName = self.name;	

	// safe?
	thread PlayerSafe();
}

SpawnSoldado()
{
	//logPrint("SpawnSoldado level.assassin_blocked = " + level.assassin_blocked + "\n");
	
	self.isCommander = false;

	if ( self.pers["team"] == game["attackers"] )
	{
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.escort_msg );

		if ( level.VIPName == 1 )
			thread ShowVipName();
	}
	else if ( (self.pers["team"] == game["defenders"] && level.assassin_blocked == false) || (self.pers["team"] == game["defenders"] && level.assassin_blocked == true && game["roundsplayed"] == 0 ) )
	{
		//logPrint("entrou pq caiu na defesa! level.assassin_blocked = " + level.assassin_blocked + "\n");	
				
		level.assassin_blocked = true;
		
		//logPrint("setou TRUE! level.assassin_blocked = " + level.assassin_blocked + "\n");	
		
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.kill_vip );
		
		// cria icon pro ass/spy
		self createAssIcon();
		
		// mostra radar pro Spy
		if ( level.AssassinSpy == 1 )
		{
			self setClientDvars("cg_deadChatWithDead", 1,
							"cg_deadChatWithTeam", 0,
							"cg_deadHearTeamLiving", 0,
							"cg_deadHearAllLiving", 0,
							"cg_everyoneHearsEveryone", 0,
							"g_compassShowEnemies", 1 );				
		}
	}
}

PlayerSafe()
{
	self.Safe = false;
	
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.pos_zulu) < 100 )
			{
				self.Safe = true;
				level.ZuluSafe = true;
				// pontos por ter chegado a zona
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 50 );
				self maps\mp\gametypes\_hardpoints::giveHardpointItem( "helicopter_mp" );
				self thread maps\mp\gametypes\_hardpoints::Assassin_hardpointNotify( "helicopter_mp" );
				return;
			} 
		}
		wait 1;
	}
}

ShowVipName()
{
	wait 5;
	if ( !isDefined( level.ShowName ) )
	{
		wait 5;
	}
	if ( isDefined( level.ShowName ) )
	{
		msg_info = "^9" + level.ShowName + "^7 " + level.assassin_is;
		if ( isDefined( self ) )
			self iPrintLn( msg_info );
	}
}

VIPloadModel()
{
	// salva classe original
	game["original_class"] = self.pers["class"];

	self.pers["class"] = "CLASS_VIP";
	self.class = "CLASS_VIP";
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

createVipIcon()
{
	self.carryIcon = createIcon( "killiconheadshot", 35, 35 );
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
	
	// carrega icon no placar
	self.statusicon = "killiconheadshot";
}

createAssIcon()
{
	self.carryIcon = createIcon( "specialty_bulletaccuracy", 35, 35 );
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
	
	// carrega icon no placar
	self.statusicon = "specialty_bulletaccuracy";
}


onPlayerDisconnect()
{
	if ( !isDefined ( self.team ) )
		return;

	AchouNovoAss = 0;

	// era o Assassino = libera a posição
	if ( self.team == game["defenders"] )
	{
		// assassino desconectou
		level.assassin_blocked = false;
		
		level notify( "assassino_desconectou" );

		// acha VIP pra mudar de time
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( isDefined(player) && player.isCommander == true )
			{
				// VIP vira assassino
				player thread MudaTime( player, game["defenders"], "ass" );
				
				// sai do loop
				AchouNovoAss = 1;
				i = level.players.size;
			}
		}
		if ( AchouNovoAss == 0 )
		{
			if ( level.players.size > 1 )
			{
				player = level.players[randomint(level.players.size)];
				player thread MudaTime( player, game["defenders"], "ass" );
			}
		}
		self AssDead();
	}
	else
		self vipDead();
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if ( !isDefined ( self.team ) )
		return;
	
	if ( isDefined( attacker.pers ) && attacker != self ) // not killed himself
	{
		// mataram Assassino
		if ( self.team == game["defenders"] )
		{
			//logPrint("quem matou o ASS?! attacker.name = " + attacker.name + "\n");		
		
			level.assassin_blocked = false;
			
			if ( !isDefined(attacker.isCommander) )
				attacker.isCommander = false;
		
			// VIP matou o Assassino
			if ( attacker.isCommander == true )
			{
				// da ponto ao VIP
				maps\mp\gametypes\_globallogic::HajasDaScore( attacker, 50 );
				
				if ( isSubStr( sMeansOfDeath, "MOD_MELEE" ) )
					maps\mp\gametypes\_globallogic::HajasDaScore( attacker, 50 );

				// Assassino vira Soldado
				thread MudaTime( self, game["attackers"], "sld" );

				// VIP vira assassino
				attacker.isCommander = false;
				thread MudaTime( attacker, game["defenders"], "ass" );
			}
			else
			// Soldado matou Assassino
			{
				// da ponto ao Soldado
				maps\mp\gametypes\_globallogic::HajasDaScore( attacker, 15 );
				
				if ( isSubStr( sMeansOfDeath, "MOD_MELEE" ) )
					maps\mp\gametypes\_globallogic::HajasDaScore( attacker, 50 );

				// Assassino vira Soldado
				thread MudaTime( self, game["attackers"], "sld" );

				// Soldado vira assassino
				thread MudaTime( attacker, game["defenders"], "ass" );
				
			}
			self AssDead();
		}
		else if ( self.team == game["attackers"] )
		{
			// mataram VIP
			if ( self.isCommander == true )
			{
				// foi TK
				if ( attacker.team == game["attackers"] )
				{
					// tira ponto do Soldado
					maps\mp\gametypes\_globallogic::HajasDaScore( attacker, -50 );
					// não muda nada
				}
				else
				// foi o assassino que matou o VIP
				{
					// da ponto ao assassino
					maps\mp\gametypes\_globallogic::HajasDaScore( attacker, 150 );

					if ( isSubStr( sMeansOfDeath, "MOD_MELEE" ) )
						maps\mp\gametypes\_globallogic::HajasDaScore( attacker, 50 );
						
					// tira ponto do VIP
					maps\mp\gametypes\_globallogic::HajasDaScore( self, -50 );
							
					// não muda nada
				}
				self vipDead();
			}
			else
			{
				//  foi TK, soldado matou soldado
				if ( isDefined ( attacker.team ) )
				{
					if ( attacker.team == game["attackers"] )
					{
						// tira ponto do Soldado
						maps\mp\gametypes\_globallogic::HajasDaScore( attacker, -15 );
						// não muda nada
					}
				}
			}
		}
	}
	else
	// ele se matou
	{
		// assassino se matou
		if ( self.team == game["defenders"] )
		{
			AchouNovoAss = 0;
			
			if ( level.assassin_blocked == true )
			{
				// tira ponto do Assassino
				maps\mp\gametypes\_globallogic::HajasDaScore( self, -50 );

				// acha VIP pra mudar de time
				for ( i = 0; i < level.players.size; i++ )
				{
					player = level.players[i];
					if ( isDefined(player) && isDefined(player.isCommander) && player.isCommander == true )
					{
						// Assassino vira Soldado
						level.assassin_blocked = false;
						thread MudaTime( self, game["attackers"], "sld" );				
						
						// VIP vira assassino
						player.isCommander = false;
						thread MudaTime( player, game["defenders"], "ass" );
						
						level.assassin_blocked = true;
						
						// diz q achou
						AchouNovoAss = 1;

						// sai do loop
						i = level.players.size;
					}
				}
					
				if ( AchouNovoAss == 0 )
				{
					if ( level.players.size > 1 )
					{
						player = level.players[randomint(level.players.size)];
						player thread MudaTime( player, game["defenders"], "ass" );
						level.assassin_blocked = true;
					}
				}					
				
				self AssDead();
			}		
		}
		else if ( self.team == game["attackers"] )
		{
			// VIP se matou
			if ( self.isCommander == true )
			{
				// tira ponto do VIP somente se o Assassin estiver vivo
				if ( level.assassin_blocked == true )
				{
					maps\mp\gametypes\_globallogic::HajasDaScore( self, -50 );
				}
				self vipDead();
			}
			else
			{
				// tira ponto do Soldado somente se o Assassin estiver vivo
				if ( level.assassin_blocked == true )
				{
					maps\mp\gametypes\_globallogic::HajasDaScore( self, -10 );
				}			
			}	
		}
	}
}

MudaTime( player, time, func )
{
	self endon("disconnect");
	self endon( "assassino_desconectou" );
	
	if ( func == "ass" && isDefined(player.bIsBot) && player.bIsBot)
	{
		game["ASSname"] = player.name;
		wait 2;
		player thread bot_mudatime(game["defenders"]);
	}
	else
	{
		wait 2;
		player maps\mp\gametypes\_teams::changeTeam(time);
	}
	
	wait 1;
	level.TimeCerto = VIPnoTimeCerto( game["attackers"] );
	if ( level.TimeCerto == false )
		game["VIPname"] = "";
	
}

bot_mudatime(team)
{
	level.assassin_blocked = false;
	
	self maps\mp\gametypes\_teams::changeTeam(team);
	
	while(!isdefined(self.pers["team"]))
		wait .05;
	
	wait 0.05;
	self notify("menuresponse", game["menu_team"], team);
	wait 1;
	level.assassin_blocked = true;
}

vipDead()
{
	if ( isDefined( self.isCommander ) && self.isCommander == true && level.assassin_blocked == true && !level.gameEnded )
	{
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["defenders"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["attackers"] );

		game["VIPname"] = "";

		level.endtext = level.vip_dead_score;
		
		// deixa de ser vip/commander
		self.isCommander = false;

		// diz q nao tem mais vip/Commander vivo
		level.LiveVIP = false;

		level notify("vip_is_dead");
		setGameEndTime( 0 );
		
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;

		iPrintLn( level.vip_dead );
		makeDvarServerInfo( "ui_text_endreason", level.vip_dead );
		setDvar( "ui_text_endreason", level.vip_dead );

		sd_endGame( game["defenders"], level.endtext );
	}
	else
	{
		//iPrintLn( "nao eh o alvo..." );
		return;
	}
}

AssDead()
{
	if ( self.team == game["defenders"] && !level.gameEnded )
	{
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["defenders"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["attackers"] );

		level.endtext = level.ass_dead_score;

		setGameEndTime( 0 );
		
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		
		iPrintLn( level.ass_dead );
		makeDvarServerInfo( "ui_text_endreason", level.ass_dead );
		setDvar( "ui_text_endreason", level.ass_dead );

		sd_endGame( game["attackers"], level.endtext );
	}
	else
	{
		//iPrintLn( "nao eh o alvo..." );
		return;
	}
}

sd_endGame( winningTeam, endReasonText )
{
	maps\mp\gametypes\_globallogic::proxVIP( game["attackers"] );
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();

	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	if ( team == "all" )
	{
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}

onOneLeftEvent( team )
{
	warnLastPlayer( team );
}


onTimeLimit()
{
	winner = undefined;
	
	if ( level.ZuluSafe == true )
	{
		// escort team vence
		winner = game["attackers"]; 
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( player.pers["team"] == game["defenders"] )
			{
				player suicide(); // mata ASS cagão
				break;
			}
		}			
		
	}
	else
	{
		// assassin/spy vence
		winner = game["defenders"];
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( isDefined(player.isCommander) && player.isCommander == true )
			{
				player suicide(); // mata VIP cagão
				break;
			}
		}		
	}

	logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

	// i think these two lines are obsolete
	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );

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

bombs()
{
	level.ZuluSafe = false;
	level.ZuluChopper = false;
	level.ZuluRevealed = false;
	
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
		
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();
	
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
			
			// move visuals
			novo_visual = undefined;
			for( i=0 ; i<visuals.size ; i++ )
			{
				if( distance( visuals[i].origin , trigger.origin ) <= 75 )
					novo_visual = visuals[i];
			}
			novo_visual.origin = sab_bomb_visuals;
			
			// move trigger
			trigger.origin = sab_bomb_target;
		}
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );

		// zulu point
		level.pos_zulu = trigger.origin;
		thread ZuluSmoke( level.pos_zulu, bombZone );		
		
		// deleta visual
		for ( i = 0; i < visuals.size; i++ )
		{
			visuals[i] delete();
		}		
		
		level.bombZones[level.bombZones.size] = bombZone;
		
		// seta a bomba obj
		obj_trigger = trigger;

		// destroi outra bomba

		trigger_del = bombZones[!a_bomb];
		visuals_del = getEntArray( bombZones[!a_bomb].target, "targetname" );    

		//logPrint("visuals_del.size = " + visuals_del.size + "\n");
		
		// deleta visual
		for ( i = 0; i < visuals_del.size; i++ )
		{
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
				bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );
		        
				// zulu point
				level.pos_zulu = trigger.origin;
				thread ZuluSmoke( level.pos_zulu, bombZone );
						        
				// deleta visual
				for ( i = 0; i < visuals.size; i++ )
				{
					visuals[i] delete();
				}
		        
				level.bombZones[level.bombZones.size] = bombZone;
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
			clips[i] delete();
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

playSoundinSpace( alias, origin )
{
	level endon( "game_ended" );

	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 6; // MP doesn't have "sounddone" notifies =(
	org delete();
}

ZuluSmoke( origin, zone ) 
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	zulutime = randomIntRange( 20, 60 );
	wait zulutime;

	zone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
	zone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" );
		
	thread playSoundinSpace( "smokegrenade_explode_default", origin );

	rot = randomfloat(360);
	zulupoint = spawnFx( level.zulu_point_smoke, origin, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( zulupoint );
	
	level.ZuluRevealed = true;

	thread ZuluRevealed();
}

ZuluRevealed()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["attackers"] )
		{
			player iPrintLn( level.escape_msg );
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
}

SetaMensagens()
{
	// basicos
	if ( getDvar( "scr_assassin_you" ) == "" )
	{
		level.assassin_you =  "^7You are the ^9VIP^7!";
	}
	else
	{
		level.assassin_you = getDvar( "scr_assassin_you" );
	}

	if ( getDvar( "scr_assassin_escort" ) == "" )
	{
		level.escort_msg =  "^7Escort the ^9VIP^7!";
	}
	else
	{
		level.escort_msg = getDvar( "scr_escort_attack" );
	}	
	
	if ( getDvar( "scr_assassin_is" ) == "" )
	{
		level.assassin_is =  "is the ^9VIP^7!";
	}
	else
	{
		level.assassin_is = getDvar( "scr_assassin_is" );
	}		

	if ( getDvar( "scr_assassin_mark" ) == "" )
	{
		level.escape_msg =  "^1Warning ^0: ^7Extraction Point Marked!";
	}
	else
	{
		level.escape_msg = getDvar( "scr_escort_mark" );
	}	
	
	// locais
	
	if ( getDvar( "scr_assassin_ass" ) == "" )
	{
		msg_ass =  "Assassin";
	}
	else
	{
		msg_ass = getDvar( "scr_assassin_ass" );
	}	
	
	if ( getDvar( "scr_assassin_spy" ) == "" )
	{
		msg_spy =  "Spy";
	}
	else
	{
		msg_spy = getDvar( "scr_assassin_spy" );
	}	

	if ( getDvar( "scr_assassin_vip" ) == "" )
	{
		msg_vip =  "VIP";
	}
	else
	{
		msg_vip = getDvar( "scr_assassin_vip" );
	}	
	
	if ( getDvar( "scr_assassin_dead" ) == "" )
	{
		msg_dead =  "is Dead!";
	}
	else
	{
		msg_dead = getDvar( "scr_assassin_dead" );
	}	
	
	if ( getDvar( "scr_assassin_the" ) == "" )
	{
		msg_the =  "The";
	}
	else
	{
		msg_the = getDvar( "scr_assassin_the" );
	}
	
	if ( getDvar( "scr_assassin_kill" ) == "" )
	{
		msg_kill =  "Kill the ^9VIP^7!";
	}
	else
	{
		msg_kill = getDvar( "scr_assassin_kill" );
	}	
	
	// finais
	
	level.vip_dead = msg_the + " ^9" + msg_vip + " ^7" + msg_dead;
	level.vip_dead_score = msg_the + " ^3" + msg_vip + " ^7" + msg_dead;
	
	if ( level.AssassinSpy == 0 )
	{
		level.kill_vip = "^9" + msg_ass + "^7: " + msg_kill;
		level.ass_dead = msg_the + " ^9" + msg_ass + " ^7" + msg_dead;
		level.ass_dead_score = msg_the + " ^3" + msg_ass + " ^7" + msg_dead;	
	}
	else
	{
		level.kill_vip = "^9" + msg_spy + "^7: " + msg_kill;
		level.ass_dead = msg_the + " ^9" + msg_spy + " ^7" + msg_dead;
		level.ass_dead_score = msg_the + " ^3" + msg_spy + " ^7" + msg_dead;			
	}	
}

