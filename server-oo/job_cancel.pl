#!/usr/bin/perl

use strict;
use warnings;
use PiLite::Server::Common;

    my $job_id = $ARGV[0];
    my $pilite_user_name = $ARGV[1];

    my $psc = PiLite::Server::Common->new();
    my $cancel_result = $psc->cancel($job_id, $pilite_user_name);

    print STDOUT $cancel_result;
