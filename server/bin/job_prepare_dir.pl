#!/usr/bin/perl

use strict;
use warnings;

    my $dir_name = $ARGV[0];
    my $job_id = $ARGV[1];

    if ((defined $dir_name) and (length $dir_name) and (not (-e $dir_name))) {
        mkdir './'.$dir_name or die "Can not create dir: $! \n";
    }
    if ((defined $job_id) and (length $job_id) and (not (-e $job_id))) {
        mkdir './'.$dir_name.'/.'.$job_id or die "Can not create dir: $! \n";
    }
