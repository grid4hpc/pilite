#!/usr/bin/perl

use strict;
use warnings;
use POSIX;
use File::Spec;
use File::Basename qw(dirname);

my $current_dir = File::Spec->rel2abs(dirname(__FILE__)); 
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

    my $executable = $current_dir.'/job_execute.pl';
    my $job_id = $ARGV[0];
    my $pilite_user_name = $ARGV[1];
    my $short_job_name = $ARGV[2];
    my $full_job_dir = $base_dir.'/'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id;

    my $stderr = $full_job_dir.'/'.$job_id.'_stderr.log';
    my $stdout = $full_job_dir.'/'.$job_id.'_stdout.log';

    open($fdlog, ">>", $pilite_log_filename);
    print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." $pilite_user_name: job_execute_wrapper $job_id started\n";
    close($fdlog);
    system($executable.' '.$job_id.' '.$pilite_user_name.' '.$short_job_name.' 1>'.$stdout.' 2>'.$stderr.' &');

    exit 0;
