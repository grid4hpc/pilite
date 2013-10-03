#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Cwd qw(abs_path);
use lib dirname(abs_path(__FILE__));
use Config::Simple;
use Module::Load;

my $cfg_file = '/home/ngrid/.piLite/conf/pilite.conf';

my $cfg = new Config::Simple($cfg_file);
my $batch_system = $cfg->param('SERVER.BATCH_SYSTEM');
my $logger_cfg = $cfg->param('SERVER.PILITE_LOGGER_CONFIG');
my $module="PiLite::Server::$batch_system";

load $module;
Log::Log4perl::init($logger_cfg);

my $job_id= $ARGV[0];
my $pilite_user_name = $ARGV[1];

my $psc;
eval { $psc = $module->new(job_id => $job_id, user_name => $pilite_user_name, config => $cfg); };

unless ($@) {
    my $job_status = $psc->status();
    print STDOUT $job_status;
} else {
    exit 1;
}
