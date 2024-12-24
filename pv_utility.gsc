#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\compass;
#using scripts\shared\system_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm; 
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_weapons;

#insert scripts\zm\_zm_utility.gsh;
#insert scripts\_pv\pv_utility.gsh;

/* ------------------- */
/* ---- prov3ntus ---- */
/* ------------------- */

/* **********************************************
// TODO:
	Add another dvar to change hitmarker sounds b/w classic, MW2019, MW2022 & MW2023 (whatever u can find)
	Fix hitmarker PrintLn-ing twice
	Add varargs to PrintPostBlack()
********************************************** */

#namespace pv_util;

/* ===================================================================== */


REGISTER_SYSTEM_EX( "pv_util", &__init__, &__main__, undefined )


function __init__()
{
	// Date format: dd-mm-yy
	//util::registerClientSys( "subtitleMessage" );
}

function __main__()
{
	level waittill( "initial_players_connected" );
	waittillframeend;

	// Init cmds
	//thread __cmds_init__();
	// -- My packs use my utils, so ima have to thread this manually for each map
}

function __cmds_init__()
{
	thread InfiniteAmmo();
	thread Hitmarkers_Dvar(); // 31-03-24
	thread HitmarkerSounds_Dvar(); // 31-03-24
	thread NewDvar( "give_points", "", &give_points_to_all_players, false, true );
}


/@
/* ========== New Dvar ========== */
// Summary | Creates a new dvar, allowing for a provided logic function to be ran when the dvar changes
// Exmaple | thread pv_util::NewDvar( "give_points", "", &give_points_to_all_players, false, true );
// Param 1 | <dvar_name> The name of the dvar in the game's console. E.g. "hitmarkers"
// Param 2 | <default_val> The default value of the dvar. E.g. "on"
// Param 3 | <logic_on_dvar_change> The callback function to run when the dvar changes. The new value of the dvar is passed as the only parameter
// Param 4 | <keep_set_val> Whether or not to keep the value as the new value set by the player, or just reset it to the default value every time it's changed.
// Param 5 | <dev_only> True or false. True will lock this dvar's use if the `developer` dvar is 0
// Param 6 | <accepted_values> An array of values for validation. "failed_validation_println" will print if input is not in this array. Leave undefined if you don't want validation.
// Param 7 | <failed_validation_println> The string to IPrintLn when a dvar value entered is invalid. E.g. "^9Hitmarkers: Please enter 1/on or 0/off to toggle hitmarkers"
@/
function NewDvar( dvar_name, default_val, logic_on_dvar_change, keep_set_val = true, dev_only = false, accepted_values, failed_validation_println ) // 02-04-24
{
	level endon( "intermission" );
	level endon( "game_over" );

	ModVar( dvar_name, default_val );

	old_val = undefined;

	for( ;; )
	{
		wait .05;

		_val = ToLower( GetDvarString( dvar_name, "" ) );

		if( !isdefined( _val ) || _val == "" )
			continue;

		ModVar( dvar_name, ( keep_set_val && isdefined( old_val ) ? old_val : default_val ) );

		if( isdefined( old_val ) && old_val == _val )
		{
			continue;
		}

		if( dev_only )
		{
			if( !GetDvarInt( "sv_cheats" ) || !GetDvarInt( "developer" ) )
			{
				IPrintLn( "Dvar locked; cheats aren't enabled on this server" );
				IPrintLn( " - pv" );
				continue;
			}
		}

		if( isdefined( accepted_values ) )
		{
			if( !array::contains( accepted_values, _val ) )
			{
				IPrintLn( failed_validation_println );
				continue;
			}
		}

		[[ logic_on_dvar_change ]]( _val );

		old_val = _val;
	}
}

/* ========== Print Post-black ========== */

function PrintPostBlack( str )
{
	thread _thread_print( str );
}

// Thread function in case caller didn't
function private _thread_print( str )
{
	while( !level flag::exists( "initial_blackscreen_passed" ) )
		wait .05;
	level flag::wait_till( "initial_blackscreen_passed" );

	IPrintLnBold( str );
}

/* ========== Better print ========== */

function BetterPrint( text, font_scale = 1.5, fade_time = 2, y_offset = 100 )
{
	hud = NewHudElem();
	hud.foreground = true;
	hud.font = "objective";
	hud.fontScale = font_scale;
	hud.sort = 1;
	hud.hidewheninmenu = false;
	hud.alignX = "center";
	hud.alignY = "bottom";
	hud.horzAlign = "center";
	hud.vertAlign = "middle";
	hud.x = 0;
	hud.y = hud.y + y_offset;
	hud.alpha = 1;

	hud SetText(text);

	wait 2;

	hud FadeOverTime( fade_time );
	hud.alpha = 0;

	wait( fade_time );

	hud Destroy();
}

/* ========== Better print client ========== */

// self == player you want to print this message to
function BetterPrintClient( text, font_scale = 1.5, fade_time = 2, y_offset = 100 )
{
	hud = NewClientHudElem( self );
	hud.foreground = true;
	hud.font = "objective";
	hud.fontScale = font_scale;
	hud.sort = 1;
	hud.hidewheninmenu = false;
	hud.alignX = "center";
	hud.alignY = "bottom";
	hud.horzAlign = "center";
	hud.vertAlign = "middle";
	hud.x = 0;
	hud.y = hud.y + y_offset;
	hud.alpha = 1;

	hud ScaleOverTime( 0.25, hud GetTextWidth(), Int( 10 * font_scale ) );
	hud SetText(text);

	wait 2;

	hud FadeOverTime( fade_time );
	hud.alpha = 0;

	wait( fade_time );

	hud Destroy();
}

/* ========== Dev Print ========== */

function print_subtitle( message ) // Broken
{
	if( !isdefined( self ) )
		return;
	
	if( IsPlayer( self ) )
	{
		self util::setClientSysState( "subtitleMessage", message, self );
		return;
	}

	if( self == level )
	{
		foreach( player_e in GetPlayers() )
		{
			player_e util::setClientSysState( "subtitleMessage", message, player_e );
		}
		return;
	}	
}

/* ============== Misc ============== */

function HasAllPerks() // self == player
{
	return IS_EQUAL( self GetPerks().size, level.perk_purchase_limit );
}



#define PSEUDO_LOOP_PREFIX			"kill_pseudo_loop_"

// self == player
// Note: sound alias must NOT be set to looping in the alias' .csv file
function PlayLocalPseudoLoopSound( str_sound_alias )
{
    level endon( "disconnect" );
    level endon( "intermission" );

    str_endon = PSEUDO_LOOP_PREFIX + str_sound_alias;
    n_playback = ( SoundGetPlaybackTime( str_sound_alias ) * .001 ) - 0.01;
    self endon( str_endon );

    for(;;)
    {
        self PlayLocalSound( str_sound_alias );
        self util::waittill_any_timeout( n_playback, str_endon );
    }
}

// self == player
function StopLocalPseudoLoopSound( str_alias )
{
	self StopLocalSound( str_alias );
	self notify( str_alias );
}


/* =============== DVAR LOGIC FUNCS =============== */

function Hitmarkers_Dvar()
{
	enable_original_zombie_hitmarkers();
	level endon( "intermission" );
	level endon( "game_over" );

	ModVar( "hitmarkers", "on" );

	value_array = array( "1", "on", "0", "off" );
	old_val = undefined;

	for( ;; )
	{
		wait .05;

		_val = GetDvarString( "hitmarkers", "" );

		if( !isdefined( _val ) )
		{
			continue;
		}

		if( _val == "" )
		{
			continue;
		}
	
		ModVar( "hitmarkers", ( isdefined( old_val ) ? old_val : "on" ) );

		if( !array::contains( value_array, _val ) )
		{
			IPrintLn( "^9Hitmarker options | on (1), off (0)" );
			continue;
		}

		if( isdefined( old_val ) && old_val == _val )
		{
			continue;
		}

		if( _val == "1" || _val == "on" )
		{
			set_zombie_hitmarkers( true );
			IPrintLn( "^2Hitmarkers enabled" );
			ModVar( "hitmarkers", "on" );
		}
		else
		{
			set_zombie_hitmarkers( false );
			IPrintLn( "^1Hitmarkers disabled" );
			ModVar( "hitmarkers", "off" );
		}

		old_val = _val;
	}
}

/* Watches hitmarker_sounds Dvar */
function HitmarkerSounds_Dvar()
{
	level endon( "intermission" );
	level endon( "game_over" );

	level.hitmarker_sound = "nsz_hit_alert";
	ModVar( "hitmarker_sounds", "on" );

	value_array = array( "1", "on", "0", "off" );
	old_val = undefined;

	for( ;; )
	{
		wait .05;

		_val = GetDvarString( "hitmarker_sounds", "" );

		if( !isdefined( _val ) )
		{
			continue;
		}

		if( _val == "" )
		{
			continue;
		}

		ModVar( "hitmarker_sounds", ( isdefined( old_val ) ? old_val : "on" ) );

		if( !array::contains( value_array, _val ) )
		{
			IPrintLn( "^9hitmarker_sounds options | on (1), off (0)" );
			continue;
		}

		if( isdefined( old_val ) && old_val == _val )
		{
			continue;
		}

		if( _val == "1" || _val == "on" )
		{
			level.hitmarker_sound = "nsz_hit_alert"; // pv_usermap.csv
			IPrintLn( "^2Hitmarker sounds turned on" );
			ModVar( "hitmarker_sounds", "on" );
		}
		else
		{
			level.hitmarker_sound = undefined;
			IPrintLn( "^1Hitmarker sounds turned off" );
			ModVar( "hitmarker_sounds", "off" );
		}

		old_val = _val;
	}
}

function enable_original_zombie_hitmarkers()
{
    callback::on_spawned( &enable_player_hitmarkers );

    zm::register_zombie_damage_override_callback( &hit_markers );
}

function set_zombie_hitmarkers( decision )
{
    foreach( player in GetPlayers() )
        player.uses_hitmarkers = decision;
}

function enable_player_hitmarkers()
{
    self endon( "bled_out" );
    self endon( "spawned_player" );
    self endon( "disconnect" );

    self.uses_hitmarkers = true;
}

function hit_markers( death, inflictor, attacker, damage, flags, mod, weapon, vpoint, vdir, sHitLoc, psOffsetTime, boneIndex, surfaceType )
{
    if( isdefined( attacker ) && IsPlayer( attacker ) )
    {
        if( IS_TRUE( attacker.uses_hitmarkers ) )
            attacker show_hit_marker( death );
    }
}

function show_hit_marker( death )  // self = player
{
    if ( IsDefined( self ) && IsDefined( self.hud_damagefeedback ) )
    {
        if( IS_TRUE( death ) )
            self.hud_damagefeedback SetShader( "damage_feedback_glow_orange", 24, 48 );
        else
            self.hud_damagefeedback SetShader( "damage_feedback", 24, 48 );

        if( isdefined( level.hitmarker_sound ) )
            self PlaySoundToPlayer( level.hitmarker_sound, self );

        self.hud_damagefeedback.alpha = 1;
        self.hud_damagefeedback FadeOverTime( 1 );
        self.hud_damagefeedback.alpha = 0;
    }    
}



/* Watches InfiniteAmmo Dvar */
function InfiniteAmmo() // 12-02-24
{
	level.infinite_ammo = false;
	ModVar( "InfiniteAmmo", "" );

	for(;;)
	{
		WAIT_SERVER_FRAME;

		dvar_value = ToLower( GetDvarString( "InfiniteAmmo", "" ) );

		if( isdefined( dvar_value ) && dvar_value != "" )
		{
			ModVar( "InfiniteAmmo", "" );

			if( !GetDvarInt( "sv_cheats" ) || !GetDvarInt( "developer" ) )
			{
				IPrintLn( "Dvar locked; cheats aren't enabled on this server" );
				IPrintLn( " - pv" );
				continue;
			}
			
			level.infinite_ammo = !level.infinite_ammo;

			if( level.infinite_ammo )
			{
				array::run_all( level.players, &give_infinite_ammo );
				IPrintLn( "^2Infinite ammo on" );
			}
			else IPrintLn( "^1Infinite ammo off" );
		}
	}
}

/* Gives player infinite ammo */
function give_infinite_ammo() // self = player
{
	self PlayLocalSound( "bottomless_clip_vox" );
	self thread bottomless_clip(); 
}

function private bottomless_clip() // self = player
{
	while( level.infinite_ammo )
	{
		gun = self GetCurrentWeapon();
		if( gun == level.weaponNone ) continue;
		self SetWeaponAmmoClip( gun, gun.clipsize ); 
		wait .05; 
	}
}


function give_points_to_all_players( points )
{
	if( !isdefined( GetPlayers() ) )
	{
		return;
	}

	foreach( player in GetPlayers() )
	{
		player zm_score::add_to_player_score( points );
		IPrintLn( sprintf( "Given ${0} to {1}.", points, player.name ) );
	}

}

/* ------------------- */
/* ---- prov3ntus ---- */
/* ------------------- */