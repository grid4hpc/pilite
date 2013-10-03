package PiLite::Server::Fork;

use strict;
use warnings;
no warnings 'redefine';
use POSIX;
use JSON;
use Template;
use Log::Log4perl;

use PiLite::Server::Common;
use base qw(PiLite::Server::Common);

sub execute {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::Fork");

    my $job_dir = $self->job_dir();
    my $job_id = $self->job_id();

    $log->debug("job_execute $job_id started");

    chdir $job_dir;
    my $batch_file = $self->full_path("$job_id.sh");

    my $file = $self->{config}->param('SERVER.BATCH_FILE_TEMPLATE');

    my $vars = $self->task_description();

    my $template = Template->new(ABSOLUTE => 1);
    $template->process($file, $vars, $batch_file) or die "Template process failed: ", $template->error(), "\n";

    my $job_result=`/bin/sh $batch_file`;
    my $local_job_id = $job_result;

    chomp($local_job_id);
    unless ($? == 0) {
        $log->logdie("PBS submission error");
    }

    $self->local_job_id($local_job_id);

}

sub status {
    my $self = shift;

    my $job_id = $self->local_job_id();

    my $job_status = "Unknown";

    #This is wrong and buggy
    my $exists = kill 0, $self->local_job_id();

    if ($exists) {
        $job_status="Running";
    } else {
        $job_status = "Finished";
    }

    return $job_status;
}

sub cancel {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("PiLite::Server::PBS");

    my $job_id = $self->job_id();
    my $job_dir = $self->job_dir();

    my $cancel_result = "NONE";
    if (-e $job_dir) {
        $cancel_result = "CANCELLED";
        kill "KILL", $self->local_job_id();
        $log->debug("job_cancel $job_id");
    } else {
        $log->debug("job_cancel $job_id WARNING: no job!");
    }

    return $cancel_result;
}

1;
