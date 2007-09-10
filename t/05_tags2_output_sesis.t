#!/usr/bin/perl
# $Id: 05_tags2_output_sesis.t,v 1.1 2007-09-10 17:43:19 skim Exp $

# Pragmas.
use strict;
use warnings;

# Modules.
use Tags2::Output::SESIS;
use Test;

# Global variables.
use vars qw/$debug $class $dir/;

BEGIN {
	# Name of class.
	$dir = $class = 'Tags2::Output::SESIS';
	$dir =~ s/:://g;

	my $tests = `egrep -r \"^[[:space:]]*ok\\(\" t/$dir/*.t | wc -l`;
        chomp $tests;
        plan('tests' => $tests);

        # Debug.
        $debug = 1;
}

# Prints debug information about class.
print "\nClass '$class'\n" if $debug;

# For every test for this Class.
my @list = `ls t/$dir/*.t`;
foreach (@list) {
        chomp;
        do $_;
	print $@;
}

