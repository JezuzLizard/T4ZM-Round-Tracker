main()
{
	level.round_tracker_file_path = "scriptdata/round_tracker/" + getDvar( "mapname" ) + "/" + getDvar( "net_port" ) + ".txt";
	level thread watch_round_change();
	level thread wait_for_first_player();
	if ( getDvar( "round_tracker_lock_server_on_high_round" ) == "" )
	{
		setDvar( "round_tracker_lock_server_on_high_round", 0 );
	}
	if ( getDvar( "round_tracker_server_lock_threshold" ) == "" )
	{
		setDvar( "round_tracker_server_lock_threshold", -1 );
	}
	if ( getDvar( "round_tracker_record_message_delay" ) == "" )
	{
		setDvar( "round_tracker_record_message_delay", 240 );
	}
	//Automatically clear the password if we lock the server at high rounds
	lock_server_at_high_round = getDvarInt( "round_tracker_lock_server_on_high_round" );
	if ( lock_server_at_high_round )
	{
		setDvar( "g_password", "" );
	}
	level.newline_characters = [];
	level.newline_characters[ "\n" ] = true;
	level.newline_characters[ "\r" ] = true;
	level.newline_characters[ "\r\n" ] = true;
}

wait_for_first_player()
{
	level waittill( "connected", player );
	level.time_passed_since_first_player = 0;
	level thread track_time();
	level thread display_previous_record_message();
	level thread lock_server_at_high_round();
	level thread watch_intermission();
}

lock_server_at_high_round()
{
	level endon( "end_game" );
	level endon( "intermission" );
	if ( getDvarInt( "round_tracker_server_lock_threshold" ) <= 0 )
	{
		return;
	}
	while ( !isDefined( level.round_number ) )
	{
		wait 1;
	}
	while ( true )
	{
		if ( level.round_number >= getDvarInt( "round_tracker_server_lock_threshold" ) )
		{
			break;
		}
		wait 1;
	}

	pin = generate_random_password();
	setDvar( "g_password", pin );
	players = getPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[ i ] setClientDvar( "password", pin );
	}
	while ( true )
	{
		cmdExec( "say " + " Server is now locked! Use password " + pin + " in the console to rejoin if you disconnect" );
		wait 600;
	}
}

generate_random_password()
{
	str = "";
	for ( i = 0; i < 4; i++ )
	{
		str = str + randomInt( 10 );
	}
	return str;
}

track_time()
{
	level endon( "end_game" );
	level endon( "intermission" );
	while ( true )
	{
		wait 1;
		level.time_passed_since_first_player++;
	}
}

watch_round_change()
{
	level endon( "end_game" );
	level endon( "intermission" );
	level waittill( "new_zombie_round", current_round );
	while ( true )
	{
		level waittill( "new_zombie_round", current_round );
		players = getPlayers();
		record_data = get_current_record_data( players );
		if ( !isDefined( record_data ) )
		{
			set_current_record_data( current_round, players );
			continue;
		}
		if ( record_data[ "round" ] >= current_round )
		{
			continue;
		}
		//printConsole( "current_record_round: " + current_record_round + " player_count: " + getPlayers().size );
		set_current_record_data( current_round, players );
		//record_data = get_current_record_data();
		//cmdExec( "say " + "New record of ^5" + current_round + "^7 set! " + " Time taken: " + to_mins(  record_data[ "time" ] ) );
	}
}

watch_intermission()
{
	level waittill( "intermission" );
	lock_server_at_high_round = getDvarInt( "round_tracker_lock_server_on_high_round" );
	if ( lock_server_at_high_round )
	{
		setDvar( "g_password", "" );
	}
}

display_previous_record_message()
{
	level endon( "end_game" );
	level endon( "intermission" );	
	while ( true )
	{
		display_record_delay = getDvarInt( "round_tracker_record_message_delay" );
		for ( i = 0; i < display_record_delay; i++ )
			wait 1;
		players = getPlayers();
		record_data = get_current_record_data( players );
		if ( !isDefined( record_data ) || record_data[ "round" ] <= 0 )
		{
			continue;
		}
		player_names = record_data[ "players" ];
		players_str = "";
		message = "";
		if ( player_names.size == 1 )
		{
			message = "Record for ^5solo ^7is ^5" + record_data[ "round" ] + "^7 held by ^5" + player_names[ 0 ];
		}
		else 
		{
			for ( i = 0; i < player_names.size - 1; i++ )
			{
				players_str = players_str + player_names[ i ] + "^7, ^5";
			}
			players_str = players_str + "^7and ^5" + player_names[ i ];

			message = "Record for ^5" + player_names.size + " player ^7is ^5" + record_data[ "round" ] + "^7 held by ^5" + players_str;
		}
		if ( message != "" )
		{
			cmdExec( "say " + message );
			wait 0.5;
			cmdExec( "say " + "^7Time taken: ^5" + to_mins( record_data[ "time" ] ) );
		}
	}
}

get_name_for_map()
{
	mapname = getDvar( "mapname" );
	switch ( mapname )
	{
		case "nazi_zombie_prototype":
			return "Nacht der Untoten";
		case "nazi_zombie_asylum":
			return "Verruckt";
		case "nazi_zombie_sumpf":
			return "Shi no Numa";
		case "nazi_zombie_factory":
			return "Der Riese";
		default:
			if ( isDefined( level.round_tracker_localized_names[ mapname ] ) )
			{
				return level.round_tracker_localized_names[ mapname ];
			}
			break;
	}
	return mapname;
}

get_current_record_data( players )
{
	keys = parse_csv();
	if ( !isDefined( keys ) )
	{
		return undefined;
	}
	cur_player_count = players.size;
	for ( i = 0; i < keys.size; i++ )
	{
		if ( keys[ i ][ "player_count" ] == cur_player_count )
		{
			return keys[ i ];
		}
	}
	return undefined;
}

set_current_record_data( round_number, players )
{
	if ( players.size <= 0 )
	{
		return;
	}
	keys = parse_csv();

	new_key = [];
	new_key[ "player_count" ] = players.size;
	players_str = "";
	for ( i = 0; i < players.size; i++ )
	{
		if ( i == ( players.size - 1 ) )
		{
			players_str = players_str + players[ i ].playername;
			break;
		}
		players_str = players_str + players[ i ].playername + "|";
	}
	players_array = [];
	for ( i = 0; i < players.size; i++ )
	{
		players_array[ i ] = players[ i ].playername;
	}
	new_key[ "players" ] = players_array;
	new_key[ "round" ] = round_number;
	new_key[ "time" ] = level.time_passed_since_first_player;

	keys = insert_key_in_csv_keys( keys, new_key );
	logprint( "New record set! " + new_key[ "player_count" ] + "," + players_str + "," + new_key[ "round" ] + "," + new_key[ "time" ] + "\n" );
	//printConsole( "set_current_round_data() new_row: " + new_row );
	write_csv( keys );
}

parse_csv()
{
	buffer = fileRead( level.round_tracker_file_path );
	if ( !isDefined( buffer ) || buffer == "" )
	{
		file_header = "player_count,players,round,time\n";
		fileWrite( level.round_tracker_file_path, file_header, "write" );
		return undefined;
	}
	rows = strTok( buffer, "\n" );
	if ( rows.size <= 1 )
	{
		return undefined;
	}
	keys = [];

	for ( i = 1; i < rows.size; i++ )
	{
		tokens = strTok( rows[ i ], "," );
		keys[ keys.size ] = [];
		keys[ keys.size - 1 ][ "player_count" ] = int( tokens[ 0 ] );
		keys[ keys.size - 1 ][ "players" ] = strTok( tokens[ 1 ], "|" );
		keys[ keys.size - 1 ][ "round" ] = int( tokens[ 2 ] );
		keys[ keys.size - 1 ][ "time" ] = int( tokens[ 3 ] );
	}
	return keys;
}

insert_key_in_csv_keys( keys, key )
{
	if ( !isDefined( keys ) )
	{
		keys = [];
		keys[ 0 ] = key;
		return keys;
	}
	replaced_key = false;
	for ( i = 0; i < keys.size; i++ )
	{
		if ( keys[ i ][ "player_count" ] == key[ "player_count" ] )
		{
			replaced_key = true;
			keys[ i ] = key;
			break;
		}
	}

	if ( !replaced_key )
	{
		keys[ keys.size ] = key;
	}
	return keys;
}

write_csv( keys )
{
	file_header = "player_count,players,round,time\n";
	row = "";
	buffer = file_header;
	for ( i = 0; i < keys.size; i++ )
	{
		row = "";
		row = row + keys[ i ][ "player_count" ] + ",";
		players_str = "";
		for ( j = 0; j < keys[ i ][ "players" ].size; j++ )
		{
			if ( j == ( keys[ i ][ "players" ].size - 1 ) )
			{
				players_str = players_str + keys[ i ][ "players" ][ j ];
				break;
			}
			players_str = players_str + keys[ i ][ "players" ][ j ] + "|";
		}
		row = row + players_str + ",";
		row = row + keys[ i ][ "round" ] + ",";
		row = row + keys[ i ][ "time" ];
		buffer = buffer + row + "\n";
	}
	fileWrite( level.round_tracker_file_path, buffer, "write" );
}

/*
Example round_tracker file

player_count,players,round
3,shadow|enimen|meme,30
4,ree|knee|bee|key,69
2,bree|ree,3
1,JezuzLizard,1
*/

/* 
Color codes:
// ^0 Black                                     //
// ^1 Red                                       //
// ^2 Green                                     //
// ^3 Yellow                                    //
// ^4 Blue                                      //
// ^5 Cyan                                      //
// ^6 Pink                                      //
// ^7 White                                     //
*/

/*
quickSort(array, compare_func) 
{
	return quickSortMid(array, 0, array.size -1, compare_func);     
}

quickSortMid(array, start, end, compare_func)
{
	i = start;
	k = end;

	if(!IsDefined(compare_func))
		compare_func = ::quickSort_compare;
	
	if (end - start >= 1)
	{
		pivot = array[start];

		while (k > i)
		{
			while ( [[ compare_func ]](array[i], pivot) && i <= end && k > i)
				i++;
			while ( ![[ compare_func ]](array[k], pivot) && k >= start && k >= i)
				k--;
			if (k > i)
			array = swap(array, i, k);
		}
		array = swap(array, start, k);
		array = quickSortMid(array, start, k - 1, compare_func);
		array = quickSortMid(array, k + 1, end, compare_func);
	}
	else
		return array;
	
	return array;
}

quicksort_compare(left, right)
{
	return left<=right;
}

swap( array, index1, index2 )
{
	temp = array[ index1 ];
	array[ index1 ] = array[ index2 ];
	array[ index2 ] = temp;
	return array;
}
*/

to_mins( seconds )
{
	hours = 0; 
	minutes = 0; 
	
	if( seconds > 59 )
	{
		minutes = int( seconds / 60 );

		seconds = int( seconds * 1000 ) % ( 60 * 1000 );
		seconds = seconds * 0.001; 

		if( minutes > 59 )
		{
			hours = int( minutes / 60 );
			minutes = int( minutes * 1000 ) % ( 60 * 1000 );
			minutes = minutes * 0.001; 		
		}
	}

	if( hours < 10 )
	{
		hours = "0" + hours; 
	}

	if( minutes < 10 )
	{
		minutes = "0" + minutes; 
	}

	seconds = Int( seconds ); 
	if( seconds < 10 )
	{
		seconds = "0" + seconds; 
	}

	combined = "" + hours  + ":" + minutes  + ":" + seconds; 

	return combined; 
}