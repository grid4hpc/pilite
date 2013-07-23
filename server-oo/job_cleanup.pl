#!/usr/bin/perl

use strict;
use warnings;
use PiLite::Server::Common;

    my $job_id = $ARGV[0];
    my $pilite_user_name = $ARGV[1];

    my $psc = PiLite::Server::Common->new();
    my $cleanup_status = $psc->cleanup($job_id, $pilite_user_name);

    print STDOUT $cleanup_status;

