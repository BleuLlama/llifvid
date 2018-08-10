#!/usr/bin/perl
# player.pl
# 	server side interactive fiction video player converter language thing
#		https://github.com/BleuLlama/llifvid
#
#	Scott Lawrence - 2018-08-10
#		yorgle@gmail.com
#	(MIT License)


$|=1;	# no buffering

# some video frames in EO1
#136 surprised arthur
# 139 - opening song
# 157 - title screen
# 96 - curtains

$quiet = 1;

my @procedures =<<END =~ m/(^.*)\n/mg;

#--------------- general procedures

: 	startup
		goto	showIntro
		done

: 	episode1
		player	add /Users/scottl/proj/z/video/HHGTTG_E01.m4v
		seek	0
		until	1
		player	frame
		goto	dark
		done

: 	showIntro
		player	add /Users/scottl/proj/z/video/HHGTTG_E02.m4v
		seek	0
		player	play
		until	34
		player	frame
		goto	episode1

: 	dark
		seek 	0
		done

#--------------- runtime procedures

? 	RESETLL
		goto	startup

?	peril-sensitive sunglasses
		seek	91				#don't panic
		goto	dark

?	RESTART, RESTORE, HINTS or QUIT
		seek 160
		#player 	shutdown
		#done

?	You wake up. The room is spinning very gently round your head
		seek 	107
		goto 	dark

?	Good start to the day. Pity it's going to be the worst	#Bedroom, in the bed
		seek	109
		done

?	The room is still spinning. It dips
		seek	100
		done

?	This is the enclosed front porch of your home					#front porch
		seek	140
		done

?	You can enter your home to the north. 		#front of house, prosser is here
		seek	883
		done

? 	lying down[1;72H8						#Front of House, lying down
		seek	174
		done

?	You lie down in the path of the advancing bulldozer. Prosser yells
		seek 	181
		done

?	The bulldozer thunders toward you. The ground is shaking
		seek 	191
		done

?	The noise of the giant bulldozer is now so violently loud 
		seek	189
		done

?	Moments later, your friend Ford Prefect arrives. He hardly seems
		seek 	355		# hello arthur
		done

?	Your home collapses in a cloud of dust, and a stray 	#die
		seek	91				#don't panic
		done

#458	ford talking with arthur

?	you exclaim, "But that man wants to knock my house
		seek	383			# getting ford
		done

?	Ford and Prosser stop talking and approach you. Ford says that Prosser #prosser lies down
		seek 	532
		done

?	In a state of anxiety and confusion you follow Ford down the lane
		seek 	557
		done

?	Come along, Arthur," says Ford impatiently, and enters the Pub
		seek 656
		done


?	The Pub is pleasant and cheerful and full of pleasant and cheerful people
		seek	661
		done

?	It's very good beer, brewed by a small local company. You particularly like
		seek 300	# betelgeuse
		done

?	"Drink the beer," urges Ford. "It will help cushion your system against
		seek 743
		done

?	Ford mentions that the world is going to end in about twelve minutes
		seek 698
	done

?	There is a distant crash which Ford explains is nothing to worry about
	seek	808
	done

?	You see the huge bulldozer heaving itself among the cloud of brick dust which
	seek	882
	done

?	There is a huge pile of rubble to the north. A path leads around it to
	seek 887 #arthur :o
	done

?	With a noise like a cross between Led Zeppelin's farewell concert and
	seek 911
	done

?	Throughout the noise, Ford is shouting at you. He removes a small black device
	seek 907
	done

?	Fierce gales whip across the land, and thunder bangs continuously through
	# see lights on device
	seek 914
	done

?	Lights whirl sickeningly around your head, the ground arches away beneath your
	goto	dark

?	There's something pungent being waved under your nose
	goto 	dark


? 	****  You have died  ****
		goto 	blackscreen
END

@p = ();

foreach my $itm( @procedures )
{
	# remove comments
	$itm =~ s/#.*$//g;

	# strip front and back
	$itm =~ s/^\s+|\s+$//g;

	# skip if there's nothing left
	if( length( $itm ) == 0 ) {
		next;
	}


	my ($cmd, $param) = split( /\s/, $itm, 2);

	# clean these up
	$cmd =~ s/^\s+|\s+$//g;
	$param =~ s/^\s+|\s+$//g;

	noisy_print( sprintf( " %10s ==> %s\n", $cmd, $param ) );

	push( @p, [ $cmd, $param ] );
}
@procedures = @p;

$pc = -1;

foreach my $x ( @procedures )
{
	#printf( "p %10s => %s\n", $x->[0], $x->[1]);
}

$x = $procedures[12];
#printf( "q %10s => %s\n", $x->[0], $x->[1]);

sub noisy_print
{
	if( $quiet ){ return; }
	print( shift );
}

sub doUntilDone
{
	while( procesOneOpcode() >= 0 ) {}
}


sub doSendMediaCommand
{
	$cmd = shift;
	noisy_print( sprintf( "SEND_CMD( \"%s\" )\n", $cmd ));
	printf( "%s\n", $cmd );
}

sub doScanForLine
{
	$haystack = shift;

	$cntr = 0;

	$needle =~ s/^\[.+d//g;

	noisy_print( sprintf( "SCANFOR( %s ) ", $needle ));

	foreach my $x ( @procedures )
	{
		if( $x->[0] eq '?' ) {

			if( index($haystack, $x->[1]) != -1) {
				$pc = $cntr +1;
				noisy_print( sprintf( "  addr: %d\n", $pc ));
				return( $pc );
			}
		}
		$cntr++;
	}

	noisy_print( sprintf( " -> not found!\n" ));
	return -1;
}

sub doGoto
{
	$label = shift;
	$pc = -1;
	$cntr = 0;

	noisy_print( sprintf( "GOTO( %s ) ", $label ));

	foreach my $x ( @procedures )
	{
		if( $x->[0] eq ':' ) {
			if( $x->[1] eq $label ) {
				$pc = $cntr +1;
				noisy_print( sprintf( "  addr: %d\n", $pc ));
				return( $pc );
			}
		}
		$cntr++;
	}

	noisy_print( sprintf( " -> not found!\n" ));
	return $pc;
}

$lastSeek = 0;
sub procesOneOpcode
{
	if( $pc < 0 || $pc > scalar( @procedures )) {
		return -1;
	}

	$opcode = $procedures[ $pc ];

	noisy_print( sprintf( "%04x: %s( %s )\n", $pc, $opcode->[0], $opcode->[1] ));
	noisy_print( sprintf( "    : " ));
	$pc++;

	if( $opcode->[ 0 ] eq "done" ) { 
		noisy_print( sprintf( "\n" ));
		$pc = -1;
		return $pc;
	}

	if( $opcode->[ 0 ] eq "goto" ) {
		doGoto( $opcode->[ 1 ] );
		return $pc;
	}

	if( $opcode->[ 0 ] eq "seek" ) {
		doSendMediaCommand( 'frame' ); # make sure we're stopped
		doSendMediaCommand( sprintf( "seek %d", $opcode->[ 1 ] ) );
		$lastSeek = $opcode->[ 1 ];

		return $pc;
	}

	if( $opcode->[ 0 ] eq "until" ) {
		$duration = $opcode->[ 1 ] - $lastSeek;
		noisy_print( sprintf( "Sleeping for %d seconds:\n    : ", $duration ));
		while( $duration > 0 ) {
			#print( "get_time\n" );
			noisy_print( sprintf( "%d ", $duration-- ));
			sleep( 1 );
		}
		noisy_print( sprintf( "\n" ));
		return $pc;
	}

	if( $opcode->[ 0 ] eq "player" ) {
		doSendMediaCommand( sprintf( $opcode->[ 1] ) );
		return $pc;
	}

	noisy_print( sprintf( "unimplemented\n" ));
	return( 1 );
}

#-----------------------

sub gotLine
{
	$line = shift;
	$line =~ s/^\s+|\s+$//g;

	if( length( $line ) == 0 ) { return; }

	noisy_print( sprintf( "Line: %s\n", $line ));

	$x = doScanForLine( $line );
	doUntilDone();
}


sub isPrint {
	my $c = shift;
	return $c =~ /\P{IsC}/
}

$acc ="";
sub accum
{
	$ch = shift;

	if( ord( $ch ) == 0 ) {
		return;
	}

	if( ord ($ch) == 0x0d  || ord( $ch ) == 0x0a ) {
		gotLine( $acc );
		$acc = "";
	} else {
		if( isPrint( $ch )) {
			$acc = $acc . $ch;
		}
	}
	$cbuf = $ch;
	if( !isPrint( $ch )) { $cbuf = '.'; }
	#printf "%02s %s\n", (unpack "H*", $ch), $cbuf;
}


noisy_print( sprintf( "Starting...\n" ));

# run the startup routine
doGoto( "startup" );
doUntilDone();
#doGoto( "blackscreen" );
#doUntilDone();
#doGoto( "testSeek" );
#doUntilDone();

while( true )
{
	$buf = ' ';
	while($buf) {
		sysread STDIN, $buf, 1;
		accum( $buf );
		$counter = 0;
	}
}

exit;

