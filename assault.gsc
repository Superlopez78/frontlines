#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

registerAssaultStrikeDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.AssaultStrikeDvar = dvarString;
	level.AssaultStrikeMin = minValue;
	level.AssaultStrikeMax = maxValue;
	level.AssaultStrike = getDvarInt( level.AssaultStrikeDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	level.LiveVIP = false;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerAssaultStrikeDvar( "scr_assault_strike", 0, 0, 1 );

	if ( level.AssaultStrike == 0 )
		maps\mp\gametypes\assault_gt::init();		
	else if ( level.AssaultStrike == 1 )
		maps\mp\gametypes\strike::init();
}