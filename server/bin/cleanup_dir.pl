#!/usr/bin/perl

use strict;
use warnings;

    my $dir_name = $ARGV[0];
    if ($dir_name =~ /\*/) {
        exit 1;
    }
    my $path_to_cleanup = './.piLite/.'.$dir_name;
    if (-e $path_to_cleanup) {
        system('rm -rf '.$path_to_cleanup);
    }
