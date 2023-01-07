main()
{
	level.round_tracker_file_path = "scriptdata/round_tracker/" + getDvar( "mapname" ) + "/" + getDvar( "net_port" ) + ".txt";
	level thread watch_round_change();
	level thread wait_for_first_player();
}

wait_for_first_player()
{
	level waittill( "connected", player );
	level.time_passed_since_first_player = 0;
	level thread track_time();
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
	current_record_round = get_current_record_data()[ "round" ];
	while ( true )
	{
		level waittill( "new_zombie_round", current_round );
		if ( current_round >= current_record_round )
		{
			set_current_record_data( current_round, getPlayers() );
			current_record_round = current_round;
		}
	}
}

watch_intermission()
{
	level waittill( "intermission" );
}

display_previous_record_message()
{
	level endon( "end_game" );
	level endon( "intermission" );	
	display_record_delay = 10;
	while ( true )
	{
		for ( i = 0; i < display_record_delay; i++ )
			wait 1;
		record_data = get_current_record_data();
		if ( record_data[ "round" ] <= 0 )
		{
			continue;
		}
		player_names = record_data[ "player_names" ];
		players_str = "";
		message = "";
		if ( player_names.size == 1 )
		{
			message = "Current record for solo on ^1" + get_name_for_map() + "^7 is held by ^4" + player_names[ 0 ];
		}
		else 
		{
			for ( i = 0; i < player_names.size - 1; i++ )
			{
				players_str = players_str + player_names[ i ];
			}
			players_str = players_str + "^7 and ^4" + player_names[ i + 1 ];

			message = "Current record for " + player_names.size + " player on ^4" + get_name_for_map() + "^7 is held by ^4" + players_str;
		}
		if ( message != "" )
		{
			cmdExec( "say " + message );
			cmdExec( "say " + "^4 time: " + to_mins( int( record_data[ "time" ] ) ) );
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

get_current_record_data()
{
	data = [];
	data[ "round" ] = 0;
	data[ "player_names" ] = [];
	data[ "time" ] = 0;
	buffer = fileRead( level.round_tracker_file_path );
	if ( !isDefined( buffer ) || buffer == "" )
	{
		return data;
	}
	rows = strTok( buffer, "\n" );
	if ( rows.size <= 1 )
	{
		return data;
	}
	cur_player_count = getPlayers().size;
	for ( i = 1; i < rows.size; i++ )
	{
		sub_tokens = strTok( rows[ i ], "," );

		if ( int( sub_tokens[ 0 ] ) == cur_player_count )
		{
			data[ "player_names" ] = strTok( sub_tokens[ 1 ], "|" );
			data[ "round" ] = int( sub_tokens[ 2 ] );	
			data[ "time" ] = int( sub_tokens[ 3 ] );
			return data;
		}
	}
	return data;
}

get_parsed_record_data()
{
	buffer = fileRead( level.round_tracker_file_path );
	if ( !isDefined( buffer ) || buffer == "" )
	{
		return undefined;
	}
	rows = strTok( buffer, "\n" );
	if ( rows.size <= 1 )
	{
		return undefined;
	}
	array = [];
	for ( i = 1; i < rows.size; i++ )
	{
		array[ i - 1 ] = rows[ i ];
	}
	return array;
}

set_current_record_data( round_number, players )
{
	if ( players.size <= 0 )
	{
		return;
	}
	rows = get_parsed_record_data();

	new_row = "";

	player_count_str = players.size + "";
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
	round_str = round_number + "";
	time_str = level.time_passed_since_first_player + "";
	new_row = player_count_str + "," + players_str + "," + round_str + "," + time_str + "\n";
	regenerate_record_data( rows, new_row );
}

regenerate_record_data( rows, new_row )
{
	file_header = "player_count,players,round,time\n";
	if ( !isDefined( rows ) )
	{
		fileWrite( level.round_tracker_file_path, file_header + new_row, "write" );
		return;
	}
	unsorted_array = [];
	for ( i = 0; i < rows.size; i++ )
	{
		unsorted_array[ i ] = strTok( rows[ i ], "," )[ 0 ];
	}
	sorted_array = quickSort( unsorted_array );

	tries = 30;
	sorted_rows = [];
	i = 0;
	j = 0;
	player_count = 0;
	while ( sorted_rows.size < sorted_array.size )
	{
		player_count = int( strTok( rows[ j ], "," )[ 0 ] );
		if ( player_count == sorted_array[ i ] )
		{
			sorted_rows[ sorted_rows.size ] = rows[ j ];
			i++;
			continue;
		}
		j++;
		if ( j >= rows.size )
		{
			j = 0;
		}
		tries--;
		if ( tries <= 0 )
		{
			break;
		}
	}
	buffer = file_header;
	player_count_new_row = int( strTok( new_row, "," ) )[ 0 ];
	for ( i = 0; i < sorted_rows.size; i++ )
	{
		player_count_current = int( strTok( rows[ j ], "," )[ 0 ] );
		if ( player_count_current == player_count_new_row )
		{
			buffer = buffer + new_row;
			continue;
		}
		buffer = buffer + sorted_rows[ i ] + "\n";
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