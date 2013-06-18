#!/usr/bin/perl

use strict;
use warnings;
use POSIX;

my $base_dir = $ENV{HOME};
my $short_pilite_dir = ".piLite";
my $short_pilite_conf_dir = "conf";
my $short_pilite_log_filename = "pilite_server.log";
my $pilite_log_filename = $base_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir.'/'.$short_pilite_log_filename;

if (not (-e $base_dir.'/'.$short_pilite_dir)) {
    mkdir $base_dir.'/'.$short_pilite_dir;
}
if (not (-e $base_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir)) {
    mkdir $base_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir;
}

my $fdlog;

    my $job_id= $ARGV[0];
    my $pilite_user_name = $ARGV[1];
    my $full_job_dir = $base_dir.'/'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id;
    my $job_status = "Unknown";
    if (-e $full_job_dir.'/'.$job_id.'_running') {
        $job_status = "Running";
    } elsif (-e $full_job_dir.'/'.$job_id.'_finished') {
        $job_status = "Finished";
    } elsif (-e $full_job_dir.'/'.$job_id.'_failed') {
       $job_status = "Failed";
    }

    open($fdlog, ">>", $pilite_log_filename);
    print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." $pilite_user_name: job-status $job_id $job_status\n";
    close($fdlog);
    print STDOUT $job_status;
