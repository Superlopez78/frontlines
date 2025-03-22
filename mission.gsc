#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	level.LiveVIP = false;
	level.GeneralMorto = false;
		
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	if ( getDvar( "mission_type" ) == "" )
		setDvar( "mission_type", 0 );
	
	if ( getDvarInt ( "mission_type" ) == 0 )
		maps\mp\gametypes\mission_gt::init();
	else if ( getDvarInt ( "mission_type" ) == 1 )
		maps\mp\gametypes\virus::init();
}
