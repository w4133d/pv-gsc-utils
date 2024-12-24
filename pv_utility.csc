#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\audio_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_load;
#using scripts\zm\_zm_weapons;

#insert scripts\zm\_zm_utility.gsh;

/* ------------------- */
/* ---- prov3ntus ---- */
/* ------------------- */

#namespace pv_util;

REGISTER_SYSTEM_EX( "pv_util", &__init__, &__main__, undefined )

function __init__()
{
	callback::on_localclient_connect( &on_player_connect );
}

function __main__()
{
	util::register_system( "subtitleMessage", &subtitlesMessage );
}

function on_player_connect( localclientnum )
{
	// Need this for floatie dyn models
	SetDvar( "phys_buoyancy", 1 );
	// Need this for float dead zombies
	SetDvar( "phys_ragdoll_buoyancy", 1 );
}

function subtitlesMessage( n_local_client_num, message ) 
{
	SubtitlePrint( n_local_client_num, 100, message );
}



/* ------------------- */
/* ---- prov3ntus ---- */
/* ------------------- */