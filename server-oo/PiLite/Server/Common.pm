package PiLite::Server::Common;

use strict;
use warnings;
use POSIX;
use JSON;

my $base_dir = $ENV{HOME};
my $short_pilite_dir = ".piLite";
my $short_pilite_conf_dir = "conf";
my $short_pilite_log_filename = "pilite_server.log";
my $pilite_log_filename = $base_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir.'/'.$short_pilite_log_filename;

###
##### common
###
sub write_log {
    my ($self, $message) = @_;
    my $fdlog;
    open($fdlog, ">>", $pilite_log_filename);
    print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time)).' '.$message;
    close($fdlog);
}

sub create_pilite_dirs {
    my ($self) = @_;
    if (not (-e $base_dir.'/'.$short_pilite_dir)) {
        mkdir $base_dir.'/'.$short_pilite_dir;
    }
    if (not (-e $base_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir)) {
        mkdir $base_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir;
    }
}

sub new {
    my ( $class, @params ) = @_;
    my $self = bless { PARAMS => {} }, $class;

    if ( ref $params[0] eq 'HASH' && ref $params[0]->{param} eq 'ARRAY' ) {
        foreach my $declared ( @{ $params[0]->{param} } ) {
            $params[0]->{ $declared->{name} } = $declared->{value};
        }
        delete $params[0]->{param};
    }
    $self->init(@params);

    $self->create_pilite_dirs();
    return $self;
}

sub init {return}

sub get_full_job_dir {
    my ($self, $job_id, $pilite_user_name) = @_;

    return $base_dir.'/'.$short_pilite_dir.'/'.$pilite_user_name.'/'.$job_id;
}

sub create_job_dir {
    my ($self, $job_id, $pilite_user_name) = @_;
    if ((not (defined $job_id)) or (not length $job_id)) {
        $self->write_log("create job dir ERROR: job_id is not defined or is empty!\n");
        return 1;
    }
    if ((not (defined $pilite_user_name)) or (not length $pilite_user_name)) {
        $self->write_log("create job dir ERROR: pilite_user_name is not defined or is empty!\n");
        return 1;
    }

    my $full_user_dir = $base_dir.'/'.$short_pilite_dir.'/'.$pilite_user_name;
    if (not (-e $full_user_dir)) {
        if (not (mkdir $full_user_dir)) {
            $self->write_log("$pilite_user_name: job_prepare_dir $job_id ERROR: Failed to create dir $full_user_dir\n");
            return 1;
        }
    }
    my $full_job_dir = $self->get_full_job_dir($job_id, $pilite_user_name);
    if (not (-e $full_job_dir)) {
        if (not (mkdir $full_job_dir)) {
            $self->write_log("$pilite_user_name: job_prepare_dir $job_id ERROR: Failed to create dir $full_job_dir\n");
            return 1;
        }
    }
    return 0;
}

sub check_job_id_and_user {
    my ($self, $job_id, $pilite_user_name, $cmd_name) = @_;

    if ((defined $job_id) and (length $job_id) and (defined $pilite_user_name) and (length $pilite_user_name)) {
        return 0;
    } else {
        $self->write_log("$cmd_name WARNING: usage: $cmd_name job_id pilite_user_name\n");
    }
    return 1;
}

###
##### job_execute part
###
sub execute_check_params {
    my ($self, $job_id, $pilite_user_name, $short_job_filename) = @_;

    if ((not defined $job_id) or (not length $job_id) or (not defined $pilite_user_name) or (not length $pilite_user_name) or (not defined $short_job_filename) or (not length $short_job_filename)) {
        $self->write_log("job_execute WARNING: usage: job_execute.pl job_id pilite_user_name job_definition.js ...\n\n");
        return "";
    }

    my $full_job_dir = $self->get_full_job_dir($job_id, $pilite_user_name);
    my $job_filename = $full_job_dir.'/'.$short_job_filename;
    if (not(-e $job_filename)) {
        $self->write_log("$pilite_user_name: job_execute ERROR: job definition file not found: '".$job_filename."'\n");
        return "";
    }
    return $job_filename, $full_job_dir;
}

sub read_job_definition {
    my ($self, $job_filename, $pilite_user_name) = @_;

    my $fd;
    if (not(open($fd, $job_filename))) {
        $self->write_log("$pilite_user_name: job_execute ERROR: Can not open file: ".$job_filename."\n"); 
        return "";
    }
    my $job_text = "";
    while (my $line=<$fd>) {
        $job_text .= $line;
    }
    close($fd);
    return $job_text;
}

sub parse_job_definition {
    my ($self, $job_filename, $pilite_user_name) = @_;

    my $job_def;
    my $job_text = $self->read_job_definition($job_filename, $pilite_user_name);
    if (length($job_text) == 0) {
        return 1;
    }
    $job_def  = decode_json $job_text;
    my @tasks = ();
    if ((exists $job_def->{tasks}) and (defined $job_def->{tasks}) and (ref $job_def->{tasks} eq 'ARRAY')) {
        @tasks = @{$job_def->{tasks}};
    }
    if (length(@tasks) == 0) {
        $self->write_log("$pilite_user_name: job_execute ERROR: No tasks defined!\n");
        return 1;
    } 
    return $job_def;
}

sub check_and_organize_data {
    my ($self, $job_def, $pilite_user_name, $full_job_dir) = @_;
    my $res_data;
    my $error_msg = "";
    
    ### Set default STDERR and STDOUT names
    my $stdout = $full_job_dir.'/stdout.log';
    my $stderr = $full_job_dir.'/stderr.log';

    ### Iterate through the tasks and select the first one
    my @tasks = @{$job_def->{tasks}};
    foreach my $task (@tasks) {
        my $task_definition;
        if ((exists $task->{definition}) and (defined $task->{definition}) and (ref $task->{definition} eq 'HASH')) {
            $task_definition = $task->{definition};
            ### INPUT FILES
            my $input_files;
            if ((exists $task_definition->{input_files}) and (defined $task_definition->{input_files}) and (ref $task_definition->{input_files} eq 'HASH')) {
                $input_files = $task_definition->{input_files};
                foreach my $input_file_name (keys %{$input_files}) {
                    my $input_file = $full_job_dir.'/'.$input_file_name;
                    if (-e $input_file) {
                        push @{$res_data->{INPUTFILES}}, $input_file;
                    } else {
                        $error_msg = "ERROR: input file '".$full_job_dir.'/'.$input_file."' for task '".$task->{id}."' is not found\n";
                        $self->write_log("$pilite_user_name: job_execute $error_msg");
                        $res_data->{ERROR} = $error_msg;
                        return $res_data;
                    }
                }
            }
            ### OUTPUT FILES
            my $output_files;
            if ((exists $task_definition->{output_files}) and (defined $task_definition->{output_files}) and (ref $task_definition->{output_files} eq 'HASH')) {
                $output_files = $task_definition->{output_files};
                foreach my $output_file_name (keys %{$output_files}) {
                    my $output_file = $full_job_dir.'/'.$output_file_name;
                    push @{$res_data->{OUTPUTFILES}}, $output_file;
                }
            }
            ### STDOUT
            if ((exists $task_definition->{stdout}) and (defined $task_definition->{stdout}) and (length $task_definition->{stdout} > 0)) {
                $stdout = $full_job_dir.'/'.$task_definition->{stdout};
                $res_data->{STDOUT} = $stdout;
            }
            ### STDERR
            if ((exists $task_definition->{stderr}) and (defined $task_definition->{stderr}) and (length $task_definition->{stderr} > 0)) {
                $stderr = $full_job_dir.'/'.$task_definition->{stderr};
                $res_data->{STDERR} = $stderr;
            }
            ### TASK EXECUTABLE
            my $executable;
            if ((exists $task_definition->{executable}) and (defined $task_definition->{executable}) and (length $task_definition->{executable} > 0)) {
                $executable = $task_definition->{executable};
                $res_data->{EXECUTABLE} = $executable;
            } else {
                $error_msg = "ERROR: Invalid definition for task: '".$task->{id}."'. No executable defined!\n";
                $self->write_log("$pilite_user_name: job_execute $error_msg");
                $res_data->{ERROR} = $error_msg;
                return $res_data;
            }
        } else {
            $error_msg = "ERROR: Invalid definition for task: '".$task->{id}."'. No definition!\n";
            $self->write_log("$pilite_user_name: job_execute $error_msg");
            $res_data->{ERROR} = $error_msg;
            return $res_data;
        }
    } # foreach task
    $res_data->{ERROR} = "";
    return $res_data;
}

sub execute_prepare {
    my ($self, $job_id, $pilite_user_name, $short_job_filename) = @_;

    my ($job_filename, $full_job_dir) = $self->execute_check_params($job_id, $pilite_user_name, $short_job_filename);
    return 1 if (length $job_filename == 0);
    my $job_def = $self->parse_job_definition($job_filename, $pilite_user_name);
    return 1 if (not (ref $job_def));
    my $res_data = $self->check_and_organize_data($job_def, $pilite_user_name, $full_job_dir);
    if ((exists $res_data->{ERROR}) and (defined $res_data->{ERROR}) and (length $res_data->{ERROR})) {
        return 1;
    }
    $res_data->{FULL_JOB_DIR} = $full_job_dir;
    $self->{EXECUTE_DATA} = $res_data;
    return $self->{EXECUTE_DATA};
}

###
##### main commands
###

sub execute {
    my ($self, $job_id, $pilite_user_name, $short_job_filename) = @_;

    if ((not (exists $self->{EXECUTE_DATA})) or (not (ref $self->{EXECUTE_DATA}))) {
        $self->execute_prepare($job_id, $pilite_user_name, $short_job_filename);
        if ((not (exists $self->{EXECUTE_DATA})) or (not (ref $self->{EXECUTE_DATA}))) {
            return 1;
        }
    }

    ### !!! This is for test purposes only
    system('touch '.$self->{EXECUTE_DATA}->{FULL_JOB_DIR}.'/'.$job_id.'_running');
    system('sleep 10');
    system('rm -rf '.$self->{EXECUTE_DATA}->{FULL_JOB_DIR}.'/'.$job_id.'_running');
    system('touch '.$self->{EXECUTE_DATA}->{FULL_JOB_DIR}.'/'.$job_id.'_finished');
}

sub status {
    my ($self, $job_id, $pilite_user_name) = @_;

    my $job_status = "Unknown";
    my $res = $self->check_job_id_and_user($job_id, $pilite_user_name, "job_status.pl");
    if ($res == 0) {
        my $full_job_dir = $self->get_full_job_dir($job_id, $pilite_user_name);
        if (-e $full_job_dir.'/'.$job_id.'_running') {
            $job_status = "Running";
        } elsif (-e $full_job_dir.'/'.$job_id.'_finished') {
            $job_status = "Finished";
        } elsif (-e $full_job_dir.'/'.$job_id.'_failed') {
            $job_status = "Failed";
        }
        $self->write_log("$pilite_user_name: job_status.pl $job_id $job_status\n");
    }

    return $job_status;
}

sub cancel {
    my ($self, $job_id, $pilite_user_name) = @_;

    my $cancel_result = "NONE";
    my $res = $self->check_job_id_and_user($job_id, $pilite_user_name, "job_cancel.pl");
    if ($res == 0) {
        my $full_job_dir = $self->get_full_job_dir($job_id, $pilite_user_name);
        if (-e $full_job_dir) {
            $cancel_result = "CANCELLED";
            $self->write_log("$pilite_user_name: job_cancel $job_id\n");
        } else {
            $self->write_log("$pilite_user_name: job_cancel $job_id WARNING: no job!\n");
        }
    }

    return $cancel_result;
}

sub cleanup {
    my ($self, $job_id, $pilite_user_name) = @_;

    my $cleanup_result = "NONE";
    my $res = $self->check_job_id_and_user($job_id, $pilite_user_name, "job_cleanup.pl");
    if ($res == 0) {
        my $full_job_dir = $self->get_full_job_dir($job_id, $pilite_user_name);
        if ($full_job_dir =~ /\*/) {
            $self->write_log("$pilite_user_name: job_cleanup $job_id ERROR: cleanup path contains forbidden symbols: $full_job_dir\n");
        }
        if (-e $full_job_dir) {
            $cleanup_result = "REMOVED";
            $self->write_log("$pilite_user_name: job_cleanup $job_id removing $full_job_dir\n");
            system('rm -rf '.$full_job_dir);
        } else {
            $self->write_log("$pilite_user_name: job_cleanup $job_id no such a directory: $full_job_dir\n");
        }
    }
    
    return $cleanup_result;
}

1;
