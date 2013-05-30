#!/usr/bin/perl

use strict;
use warnings;
use POSIX;

my $short_pilite_dir = ".piLite";
my $short_pilite_conf_dir = "conf";
my $short_pilite_log_filename = "pilite_server.log";
my $pilite_log_filename = './'.$short_pilite_dir.'/'.$short_pilite_conf_dir.'/'.$short_pilite_log_filename;

if (not (-e './'.$short_pilite_dir)) {
    mkdir './'.$short_pilite_dir;
}
if (not (-e './'.$short_pilite_dir.'/'.$short_pilite_conf_dir)) {
    mkdir './'.$short_pilite_dir.'/'.$short_pilite_conf_dir;
}

my $fdlog;

    my $job_id = $ARGV[0];
    my $pilite_user_name = $ARGV[1];

    if ((defined $pilite_user_name) and (length $pilite_user_name) and (not (-e './'.$short_pilite_dir.'/'.$pilite_user_name))) {
        if (not(mkdir './'.$short_pilite_dir.'/'.$pilite_user_name)) {
            open($fdlog, ">>", $pilite_log_filename);
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." $pilite_user_name: job_prepare_dir $job_id ERROR: Failed to create dir ".'./'.$short_pilite_dir.'/'.$pilite_user_name." \n";
            close($fdlog);
        }
    }
    if ((defined $job_id) and (length $job_id) and (not (-e './'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id))) {
        if (not (mkdir './'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id)) {
            open($fdlog, ">>", $pilite_log_filename);
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." $pilite_user_name: job_prepare_dir $job_id ERROR: Failed to create dir ".'./'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id." \n";
            close($fdlog);
        }
    }
