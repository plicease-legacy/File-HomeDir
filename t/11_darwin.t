#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More;
use File::HomeDir;

if ( $File::HomeDir::IMPLEMENTED_BY->isa('File::HomeDir::Darwin') ) {
        # Force pure perl since it should work everywhere
        $File::HomeDir::IMPLEMENTED_BY = 'File::HomeDir::Darwin';
	plan( tests => 6 );
} else {
	plan( skip_all => "Not running on Darwin" );
	exit(0);
}

SKIP: {
	my $user;
	foreach ( 0 .. 9 ) {
		my $temp = sprintf 'fubar%04d', rand(10000);
		getpwnam $temp and next;
		$user = $temp;
		last;
	}
	$user or skip("Unable to find non-existent user", 1);
	$@ = undef;
	my $home = eval {File::HomeDir->users_home($user)};
	$@ and skip("Unable to execute File::HomeDir->users_home('$user')", 1);
	ok (!defined $home, "Home of non-existent user should be undef");
}

SCOPE: {
	# Reality Check
	my $music    = File::HomeDir->my_music;
	my $video    = File::HomeDir->my_videos;
	my $pictures = File::HomeDir->my_pictures;
	SKIP: {
		skip( "No music directory", 1 ) unless defined $music;
		like( File::HomeDir->my_music, qr/Music/ );
	}
	SKIP: {
		skip( "No videos directory", 1 ) unless defined $video;
		like( File::HomeDir->my_videos, qr/Movies/ );
	}
	SKIP: {
		skip( "No pictures directory", 1 ) unless defined $pictures;
		like( File::HomeDir->my_pictures, qr/Pictures/ );
	}

	# This one, on the other hand, we probably should always have???
	like( File::HomeDir->my_data, qr/Application Support/ );
}

SKIP: {
	my $user;
	foreach my $uid ( 501 .. 540 ) {
		$uid == $< and next;
		$user = getpwuid $uid or next;
		last;
	}
	$user or skip("Unable to find another user", 1);
	my $me = getpwuid $<;
	my $my_home = eval { File::HomeDir->my_home() };
	unless ( defined $my_home ) {
		skip( "File::HomeDir->my_home() undefined", 1 );
	}
	my $users_home = eval { File::HomeDir->users_home($user) };
	unless ( defined $users_home ) {
		skip( "File::HomeDir->users_home('$user') undefined", 1 );
	}
	if ( $my_home eq $users_home ) {
		skip( "Users '$me' and '$user' have same home", 1 );
	}
	my $my_data = eval { File::HomeDir->my_data() };
	unless ( defined $my_data ) {
		skip( "File::HomeDir->my_data() undefined", 1 );
	}
	my $users_data = eval { File::HomeDir->users_data($user) };
	unless ( defined $users_data ) {
		skip( "File::HomeDir->users_data('$user') undefined", 1 );
	}
	ok (
		$my_data ne $users_data,
		"Users '$me' and '$user' should have different data",
	);
}
