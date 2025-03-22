#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerTargetsSingleDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.TargetsSingleDvar = dvarString;
	level.TargetsSingleMin = minValue;
	level.TargetsSingleMax = maxValue;
	level.TargetsSingle = getDvarInt( level.TargetsSingleDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerTargetsSingleDvar( "scr_targets_single", 0, 0, 1 );
	
	level.onPrecacheGameType = maps\mp\gametypes\sd::onPrecacheGameType;

	if ( level.TargetsSingle == 0 )
		maps\mp\gametypes\targets_gt::init();
	else if ( level.TargetsSingle == 1 )
		maps\mp\gametypes\objective::init();
}