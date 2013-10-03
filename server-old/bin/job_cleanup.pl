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

    my $job_id = $ARGV[0];
    my $pilite_user_name = $ARGV[1];
    my $path_for_cleanup = $base_dir.'/'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id;
    if ($path_for_cleanup =~ /\*/) {
        open($fdlog, ">>", $pilite_log_filename);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." $pilite_user_name: job_cleanup $job_id ERROR: cleanup path contains forbidden symbols: $path_for_cleanup\n";
        close($fdlog);
        exit 1;
    }
    if (-e $path_for_cleanup) {
        open($fdlog, ">>", $pilite_log_filename);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." $pilite_user_name: job_cleanup $job_id removing $path_for_cleanup\n";
        close($fdlog);
        system('rm -rf '.$path_for_cleanup);
    } else {
        open($fdlog, ">>", $pilite_log_filename);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." $pilite_user_name: job_cleanup $job_id no such a directory: $path_for_cleanup\n";
        close($fdlog);
    }
