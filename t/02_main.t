#!/usr/bin/perl -w

# Main testing for File::HomeDir

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use File::Spec::Functions ':ALL';
use Test::More;
use File::HomeDir;

# This module is destined for the core.
# Please do NOT use convenience modules
# use English; <-- don't do this





#####################################################################
# Environment Detection and Plan

# For what scenarios can we be sure that we have desktop/documents
my $NO_GETPWUID = 0;
my $HAVEHOME    = 0;
my $HAVEDESKTOP = 0;
my $HAVEMUSIC   = 0;
my $HAVEOTHERS  = 0;

# Various cases of things we should try to test for
# Top level is entire classes of operating system.
# Below that are more general things.
if ( $^O eq 'MSWin32' ) {
	$NO_GETPWUID = 1;
	$HAVEHOME    = 1;
	$HAVEDESKTOP = 1;
	$HAVEOTHERS  = 1;

	# My Music does not exist on Win2000
	require Win32;

# elsif ( other major different things? )

# System is unix-like

# Nobody users on all unix systems generally don't have home directories
} elsif ( getpwuid($<) eq 'nobody' ) {
	$HAVEHOME    = 0;
	$HAVEOTHERS  = 0;
	$HAVEDESKTOP = 0;

} elsif ( $^O eq 'darwin' ) {
	# Darwin special cases
	if ( $< ) {
		# Normal user
		$HAVEHOME    = 1;
		$HAVEOTHERS  = 1;
		$HAVEDESKTOP = 1;
	} else {
		# Darwin root only has a home, nothing else
		$HAVEHOME    = 1;
		$HAVEOTHERS  = 0;
		$HAVEDESKTOP = 0;
	}

} else {
	# Default to traditional Unix
	$HAVEHOME    = 1;
	$HAVEOTHERS  = 1;
	$HAVEDESKTOP = 1;
}

plan tests => 52;





#####################################################################
# Test invalid uses

eval {
    home(undef);
};
like( $@, qr{Can't use undef as a username}, 'home(undef)' );
my $warned = 0;
eval {
	local $SIG{__WARN__} = sub { $warned++ };
	my $h = $~{undef()};
};
is( $warned, 1, 'Emitted a single warning' );
like( $@, qr{Can't use undef as a username}, '%~(undef())' );

# Check error messages for unavailable tie constructs
SKIP: {
	skip("getpwuid not available", 3) if $NO_GETPWUID;

	eval {
    	$~{getpwuid($<)} = "new_dir";
	};
	like( $@, qr{You can't STORE with the %~ hash}, 'Cannot store in %~ hash' );

	eval {
	    exists $~{getpwuid($<)};
	};
	like( $@, qr{You can't EXISTS with the %~ hash}, 'Cannot store in %~ hash' );

	eval {
	    delete $~{getpwuid($<)};
	};
	like( $@, qr{You can't DELETE with the %~ hash}, 'Cannot store in %~ hash' );
}

eval {
    %~ = ();
};
like( $@, qr{You can't CLEAR with the %~ hash}, 'Cannot store in %~ hash' );

eval {
    my ($k, $v) = each(%~);
};
like( $@, qr{You can't FIRSTKEY with the %~ hash}, 'Cannot store in %~ hash' );

# right now if you call keys in void context
# keys(%~);
# it does not throw an exception while if you call it in list context it
# throws an exception.
my @usernames;
eval {
    @usernames = keys(%~);
};
like( $@, qr{You can't FIRSTKEY with the %~ hash}, 'Cannot store in %~ hash' );

# How to test NEXTKEY error if FIRSTKEY already throws an exception?





#####################################################################
# API Test

# Check the methods all exist
foreach ( qw{ home desktop documents music pictures video data } ) {
	can_ok( 'File::HomeDir', "my_$_" );
	can_ok( 'File::HomeDir', "users_$_" );
}





#####################################################################
# Main Tests

# Find this user's homedir
my $home = home();
if ( $HAVEHOME ) {
	ok( !!($home and -d $home), 'Found our home directory' );
} else {
	is( $home, undef, 'Confirmed no home directory' );
}

# this call is not tested:
# File::HomeDir->home

# Find this user's home explicitly
my $my_home = File::HomeDir->my_home;
if ( $HAVEHOME ) {
	ok( !!($home and -d $home), 'Found our home directory' );
} else {
	is( $home, undef, 'Confirmed no home directory' );
}

is( $home, $my_home, 'Different APIs give same results' );
SKIP: {
	skip("getpwuid not available", 1) if $NO_GETPWUID;
	is( home(getpwuid($<)), $home, 'home(username) returns the same value' );
}

is( $~{""}, $home, 'Legacy %~ tied interface' );
SKIP: {
	skip("getpwuid not available", 1) if $NO_GETPWUID;
	is( $~{getpwuid($<)}, $home, 'Legacy %~ tied interface' );
}

my $my_home2 = File::HomeDir::my_home();
if ( $HAVEHOME ) {
	ok( !!($my_home2 and -d $my_home2), 'Found our home directory' );
} else {
	is( $home, undef, 'No home directory, as expected' );
}
is( $home, $my_home2, 'Different APIs give same results' );

# shall we test using -w if the home directory is writable ?

# Find this user's documents
SKIP: {
	skip("Cannot assume existance of documents", 3) unless $HAVEOTHERS;
	my $my_documents  = File::HomeDir->my_documents;
	my $my_documents2 = File::HomeDir::my_documents();
	is( $my_documents, $my_documents2, 'Different APIs give the same results' );
	ok( !!($my_documents  and -d $my_documents), 'Found our documents directory' );
	ok( !!($my_documents2 and $my_documents2),   'Found our documents directory' );
}

# Find this user's local data
SKIP: {
	skip("Cannot assume existance of application data", 3) unless $HAVEOTHERS;
	my $my_data  = File::HomeDir->my_data;
	my $my_data2 = File::HomeDir::my_data();
	is( $my_data, $my_data2, 'Different APIs give the same results' );
	ok( !!($my_data  and -d $my_data),  'Found our local data directory' );
	ok( !!($my_data2 and -d $my_data2), 'Found our local data directory' );
}

# Find this user's music directory
SKIP: {
	skip("Cannot assume existance of music", 3) unless $HAVEOTHERS;
	my $my_music  = File::HomeDir->my_music;
	my $my_music2 = File::HomeDir::my_music();
	is( $my_music, $my_music2, 'Different APIs give the same results' );
	ok( !!($my_music  and -d $my_music),  'Our music directory exists' );
	ok( !!($my_music2 and -d $my_music2), 'Our music directory exists' );
}

# Find this user's pictures directory
SKIP: {
	skip("Cannot assume existance of pictures", 3) unless $HAVEOTHERS;
	my $my_pictures  = File::HomeDir->my_pictures;
	my $my_pictures2 = File::HomeDir::my_pictures();
	is( $my_pictures, $my_pictures2, 'Different APIs give the same results' );
	ok( !!($my_pictures  and -d $my_pictures),  'Our pictures directory exists' );
	ok( !!($my_pictures2 and -d $my_pictures2), 'Our pictures directory exists' );
}

# Find this user's video directory
SKIP: {
	skip("Cannot assume existance of videos", 3) unless $HAVEOTHERS;
	my $my_videos  = File::HomeDir->my_videos;
	my $my_videos2 = File::HomeDir::my_videos();
	is( $my_videos, $my_videos2, 'Different APIs give the same results' );
	ok( !!($my_videos  and -d $my_videos),  'Our local data directory exists' );
	ok( !!($my_videos2 and -d $my_videos2), 'Our local data directory exists' );
}

# Desktop cannot be assumed in all environments
SKIP: {
	skip("Cannot assume existance of desktop", 3 ) unless $HAVEDESKTOP;

	# Find this user's desktop data
	my $my_desktop  = File::HomeDir->my_desktop;
	my $my_desktop2 = File::HomeDir::my_desktop();
	is( $my_desktop, $my_desktop2, 'Different APIs give the same results' );
	ok( !!($my_desktop  and -d $my_desktop),  'Our desktop directory exists' );
	ok( !!($my_desktop2 and -d $my_desktop2), 'Our desktop directory exists' );
}

# Shall we check name space pollution by testing functions in main before
# and after calling use ?

# On platforms other than windows, find root's homedir
SKIP: {
	if ( $^O eq 'MSWin32' or $^O eq 'darwin') {
		skip("Skipping root test on $^O", 3 );
	}

	# Determine root
	my $root = getpwuid(0);
	unless ( $root ) {
		skip("Skipping, can't determine root", 3 );
	}

	# Get root's homedir
	my $root_home1 = home($root);
	ok( !!($root_home1 and -d $root_home1), "Found root's home directory" );

	# Confirm against %~ hash
	my $root_home2 = $~{$root};
	ok( !!($root_home2 and -d $root_home2), "Found root's home directory" );

	# Root account via different methods match
	is( $root_home1, $root_home2, 'Home dirs match' );
}

exit(0);
