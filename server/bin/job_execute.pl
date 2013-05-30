#!/usr/bin/perl

use strict;
use warnings;
use POSIX;
use JSON;

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

    my $job_id= $ARGV[0];
    my $pilite_user_name = $ARGV[1];
    my $short_job_filename = $ARGV[2];
    my $short_job_dir = './'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id;

    if ((not defined $short_job_dir) or (not length $short_job_dir) or (not defined $short_job_filename) or (not length $short_job_filename)) {
        print STDERR "usage: job_execute.pl job_dir job_definition.js ...\n\n";
        exit 1;
    }

    my $job_filename = $short_job_dir.'/'.$short_job_filename;
    if (not(-e $job_filename)) {
        print STDERR "ERROR: job definition file not found: '".$job_filename."'\n";
        exit 1;
    }

    ### Set default STDERR and STDOUT names
    my $stdout = $short_job_dir.'/stdout.log';
    my $stderr = $short_job_dir.'/stderr.log';

    ### Read the job definition
    my $fd;
    open($fd, $job_filename) or die "Can not open file: ".$job_filename."\n"; 
    my $job_text = "";
    while (my $line=<$fd>) {
        $job_text .= $line;
    }
    close($fd);

    ### !!! This is for test purposes only
    system('touch ./'.$short_job_dir.'/'.$job_id.'_running');
    
    ### Parse the job definition
    my $job_def = decode_json $job_text;
    my @tasks = ();
    if ((exists $job_def->{tasks}) and (defined $job_def->{tasks}) and (ref $job_def->{tasks} eq 'ARRAY')) {
        @tasks = @{$job_def->{tasks}};
    }
    if (length(@tasks) == 0) {
        print STDERR "ERROR: No tasks defined!\n";
        exit 0;
    } 

    ### !!! This is for test purposes only
    system('sleep 10');

    ### Iterate through the tasks and select the first one
    foreach my $task (@tasks) {
        my $task_definition;
        if ((exists $task->{definition}) and (defined $task->{definition}) and (ref $task->{definition} eq 'HASH')) {
            $task_definition = $task->{definition};
            ### INPUT FILES
            my $input_files;
            if ((exists $task_definition->{input_files}) and (defined $task_definition->{input_files}) and (ref $task_definition->{input_files} eq 'HASH')) {
                $input_files = $task_definition->{input_files};
                foreach my $input_file_name (keys %{$input_files}) {
                    my $input_file = $short_job_dir.'/'.$input_files->{$input_file_name};
                    if (-e $input_file) {
                        ### *** Do something with input file
                    } else {
                        print STDERR "ERROR: input file '".$short_job_dir.'/'.$input_file."' for task '".$task->{id}."' is not found\n";
                        exit 1;
                    }
                }
            }
            ### OUTPUT FILES
            my $output_files;
            if ((exists $task_definition->{output_files}) and (defined $task_definition->{output_files}) and (ref $task_definition->{output_files} eq 'HASH')) {
                $output_files = $task_definition->{output_files};
                foreach my $output_file_name (keys %{$output_files}) {
                    my $output_file = $short_job_dir.'/'.$output_files->{$output_file_name};
                    ### *** Do something with output file
                    ### !!! This is for test purposes only
                    system('echo "TEST OUT" > '.$output_file);
                }
            }
            ### STDOUT
            if ((exists $task_definition->{stdout}) and (defined $task_definition->{stdout}) and (length $task_definition->{stdout} > 0)) {
                $stdout = $short_job_dir.'/'.$task_definition->{stdout};
                ### *** Do something with stdout file
                ### !!! This is for test purposes only
                system('echo "TEST STDOUT" > '.$stdout);
            }
            ### STDERR
            if ((exists $task_definition->{stderr}) and (defined $task_definition->{stderr}) and (length $task_definition->{stderr} > 0)) {
                $stderr = $short_job_dir.'/'.$task_definition->{stderr};
                ### *** Do something with stderr file
                ### !!! This is for test purposes only
                system('echo "TEST STDERR" > '.$stderr);
            }
            ### TASK EXECUTABLE
            my $executable;
            if ((exists $task_definition->{executable}) and (defined $task_definition->{executable}) and (length $task_definition->{executable} > 0)) {
                $executable = $task_definition->{executable};
                ### *** Do something with executable
                ### !!! This is for test purposes only
                system($executable);
            } else {
                print STDERR "ERROR: Invalid definition for task: '".$task->{id}."'. No executable defined!\n";
            }
        } else {
            print STDERR "ERROR: Invalid definition for task: '".$task->{id}."'. No definition!\n";
        }
        
    }
    ### !!! This is for test purposes only
    system('sleep 10');
    system('rm -rf ./'.$short_job_dir.'/'.$job_id.'_running');
    system('touch ./'.$short_job_dir.'/'.$job_id.'_finished');

