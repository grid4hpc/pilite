#!/usr/bin/perl

use strict;
use warnings;
use JSON;

my $home_dir = $ENV{HOME};
my $executable = $home_dir.'/job_execute.pl';

my $job_path = './'.$ARGV[0].'/';
my $job_short_name = $ARGV[1];

    if ((not defined $job_path) or (not length $job_path) or (not defined $job_short_name) or (not length $job_short_name)) {
        print "usage: job_execute_wrapper.pl job_dir job_definition.js ...\n\n";
        exit 1;
    }

    my $job_name = $job_path.$job_short_name;
    if (not(-e $job_name)) {
        print "ERROR: job definition file not found: '".$job_name."'\n";
        exit 1;
    }

    my $stderr = $job_path.$job_short_name.'_stderr.log';
    my $stdout = $job_path.$job_short_name.'_stdout.log';

    system($executable.' '.$job_path.' '.$job_short_name.' 1>'.$stdout.' 2>'.$stderr.' &');

    exit 0;
