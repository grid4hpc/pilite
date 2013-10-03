package PiLite::Server::Common;

use strict;
use warnings;
use POSIX;
use JSON;
use String::ShellQuote;
use File::Path;
use Log::Log4perl;

sub new {
    my $class = shift;
    my $self = {};
    %$self = @_;

    bless $self, $class;

    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    $log->logdie("job_id is not defined or is empty!") unless ($self->{job_id});
    $log->logdie("user_name is not defined or is empty!") unless ($self->{user_name});
    $log->logdie("config is not defined or is empty!") unless ($self->{config});

    $self->{pilite_dir} = $self->{config}->param('SERVER.PILITE_DIR');
    $log->logdie("pilite_dir is not defined or is empty!") unless ($self->{pilite_dir});

    #all methods expect this one to exist
    #it make little sense to keep it separated from constuctor
    my $job_dir=$self->job_dir();

    unless (-e $job_dir or ($self->{create_dirs} and mkpath $job_dir)) {
        $log->logdie("Failed to create dir $job_dir");
    }

    return $self;
}

sub job_id {
    my $self = shift;
    return $self->{job_id};
}

sub user_name {
    my $self = shift;
    return $self->{user_name};
}

sub user_dir {
    my $self = shift;
    return $self->{pilite_dir}."/".$self->{user_name};
}

sub job_dir {
    my $self = shift;
    return $self->user_dir()."/".$self->job_id();
}

sub full_path {
    my $self = shift;
    my $local = shift;
    return $self->job_dir()."/".$local;
}

sub job_file {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    #FIXME
    #move to constructor?
    #make short_job_filename essential parameter
    #flatten client/server api
    $log->logdie("short_job_filename is not defined or is empty!") unless ($self->{short_job_filename});

    my $job_file=$self->full_path($self->{short_job_filename});
    $log->logdie("job definition file not found: '$job_file'") unless (-e $job_file);

    return $job_file;
}

sub job {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    my $job_file=$self->job_file();
    my $fd;

    $log->logdie("Can not open job definition file: $job_file") unless (open($fd, $job_file));

    my $job_text = do { local $/; <$fd> };
    return decode_json $job_text;
}

sub task {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    my $job_def = $self->job();

    my @tasks = @{$job_def->{tasks}} if (ref $job_def->{tasks} eq 'ARRAY');
    $log->logdie("No tasks defined!\n") unless (@tasks);

    #we will only use first one
    my $task=$tasks[0];

    $log->logdie("Invalid definition for task. No definition!\n") unless (ref $task->{definition} eq 'HASH');

    return $task;
}

sub task_description {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    my $description;

    my $task=$self->task();
    my $task_definition = $task->{definition};

    #input files
    my $input_files;
    if (ref $task_definition->{input_files} eq 'HASH') {
        $input_files = $task_definition->{input_files};
        foreach my $input_file_name (keys %{$input_files}) {
            my $input_file = $self->full_path($input_file_name);
            $log->logdie("input file '$input_file' for task '$task->{id}' is not found") unless (-e $input_file);

            push @{$description->{input_files}}, $input_file;
        }
    }

    #output files
    my $output_files;
    if (ref $task_definition->{output_files} eq 'HASH') {
        $output_files = $task_definition->{output_files};
        foreach my $output_file_name (keys %{$output_files}) {
            push @{$description->{output_files}}, $self->full_path($output_file_name);
        }
    }

    #stdout
    if ($task_definition->{stdout}) {
        $description->{stdout} = $self->full_path($task_definition->{stdout});
    } else {
        $description->{stdout} = $self->full_path("stdout.log");
    }

    #stdin
    if (length $task_definition->{stderr}) {
        $description->{stderr} = $self->full_path($task_definition->{stderr});
    } else {
        $description->{stderr} = $self->full_path("stderr.log");
    }

    #executable
    if ($task_definition->{executable}) {
        if ($task_definition->{executable} =~ "%/%") {
            $description->{executable} = $task_definition->{executable};
        } else {
            if (-x $self->full_path($task_definition->{executable})) {
                $description->{executable} = $self->full_path($task_definition->{executable});
            } else {

                #frequently requested feature
                #borderline security bug
                $description->{executable} = $task_definition->{executable};
            }
        }
    } else {
        $log->logdie("Invalid definition for task. No executable defined!");
    }

    #arguments
    if ($task_definition->{arguments}) {
        $description->{arguments} = shell_quote @{$task_definition->{arguments}};
    }

    #count
    if ($task_definition->{count}){
        $description->{count} = $task_definition->{count};
    } else {
        $description->{count} = 1;
    }

    $description->{directory}=$self->job_dir();

    my $job=$self->job();
    if ($job->{requirement} and $job->{requirement}->{queue}) {
        $description->{queue} = $job->{requirement}->{queue};
    }

    return $description;
}

sub execute {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    $log->logdie("Unimplemented");

    return;
}

sub status {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    $log->logdie("Unimplemented");

    return;
}

sub cancel {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    $log->logdie("Unimplemented");

    return;
}

sub cleanup {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Common");

    my $job_dir = $self->job_dir();
    my $job_id=$self->job_id();

    my $cleanup_result = "NONE";
    if ($job_dir =~ /\*/) {
        $log->logdie("job_cleanup $job_id, cleanup path contains forbidden symbols: $job_dir");
    }
    if (-e $job_dir) {
        $cleanup_result = "REMOVED";
        $log->debug("job_cleanup $job_id removing $job_dir\n");
        system('rm -rf '.$job_dir);
    } else {
        $log->debug("job_cleanup $job_id no such a directory: $job_dir\n");
    }

    return $cleanup_result;
}

sub local_job_id {
    my $self = shift;
    my $local_job_id = shift;

    my $job_id = $self->job_id();

    my $local_job_id_filename = $self->full_path("$job_id.job_id");
    if ($local_job_id) {
        open my $local_job_id_file, ">", $local_job_id_filename;
        print $local_job_id_file $local_job_id,"\n";
        close $local_job_id_file;
    } else {
        open my $local_job_id_file, "<", $local_job_id_filename;
        $local_job_id = <$local_job_id_file>;
        chop($local_job_id);
        close $local_job_id_file;
    }

    return $local_job_id;
}

1;
