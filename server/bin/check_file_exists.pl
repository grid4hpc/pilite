#!/usr/bin/perl

use strict;
use warnings;

    my $file_name = $ARGV[0];
    if (-e './'.$file_name) {
        print "Exists";
    } else {
        print "No";
    }
