#!/usr/bin/perl

use strict;
use warnings;
use PiLite::Server::Common;

    my $job_id = $ARGV[0];
    my $pilite_user_name = $ARGV[1];
    my $short_job_name = $ARGV[2];

    my $psc = PiLite::Server::Common->new();
    my $res_data = $psc->execute_prepare($job_id, $pilite_user_name, $short_job_name);
    if (not ref $res_data) {
        exit 1;
    }
    $psc->write_log("$pilite_user_name: job_execute $job_id started\n");
    $psc->execute($job_id, $pilite_user_name, $short_job_name);
