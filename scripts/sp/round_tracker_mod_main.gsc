main()
{
	level.round_tracker_file_path = "scriptdata/round_tracker/" + getDvar( "mapname" ) + "/" + getDvar( "net_port" ) + ".txt";
	level thread watch_round_change();
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
	display_record_delay = 300;
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
		}
	}
}

get_current_record_data()
{
	round = 0;
	player_names = [];
	data = [];
	data[ "round" ] = 0;
	data[ "player_names" ] = player_names;
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
	rows = get_parsed_record_data();
	regenerate_record_data( rows )
}

regenerate_record_data( rows )
{
	file_header = "player_count,players,record\n";
	if ( !isDefined( rows ) )
	{
		fileWrite( level.round_tracker_file_path, file_header, "write" );
	}
	else 
	{
		buffer = "";
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
		if ( sorted_rows.size <= 0 )
		{
			fileWrite( level.round_tracker_file_path, file_header, "write" );
		}
	}
}

/*
Example round_tracker file

player_count,players,record
3,shadow|enimen|meme,30
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
		compare_func = &quickSort_compare;
	
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