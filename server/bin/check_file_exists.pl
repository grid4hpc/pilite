#!/usr/bin/perl

use strict;
use warnings;

my $base_dir = $ENV{HOME};

    my $file_name = $ARGV[0];
    if (-e $base_dir.'/'.$file_name) {
        print "Exists";
    } else {
        print "No";
    }
