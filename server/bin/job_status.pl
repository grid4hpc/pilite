#!/usr/bin/perl

use strict;
use warnings;

    my $file_name = $ARGV[0];
    if (-e './'.$file_name.'_running') {
        print "Running";
    } elsif (-e './'.$file_name.'_finished') {
        print "Finished";
    } elsif (-e './'.$file_name.'_failed') {
        print "Failed";
    } else {
        print "Unknown";
    }
