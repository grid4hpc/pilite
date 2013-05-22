package PilotCheckParams;

use strict;
use warnings;
use POSIX;

my $pilite_dir = '.piLite';
my $pilite_log = 'pilite.log';

sub TrimAndLC {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    return lc($string);
}

sub TrimOnly {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    return $string;
}

sub check_job_file {
    my $job_file_name = shift;
    my $piLiteLog = shift;
    ### Check if a job definition is defined
    if ((not defined $job_file_name) or (not length $job_file_name)) {
        my $fdlog;
        open($fdlog, ">>", $piLiteLog);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." pilot-job-submit: ERROR:\n";
        print $fdlog "usage: pilot-job-submit job_definition.js ...\n\n";
        print $fdlog " Submit a job to Pilot service.\n";
        close($fdlog);
        return 0;
    }

    ### Check if a job definition file exists
    if (not(-e $job_file_name)) {
        my $fdlog;
        open($fdlog, ">>", $piLiteLog);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." pilot-job-submit: ERROR: job definition file not found: '".$job_file_name."'\n";
        close($fdlog);
        return 0;
    }
    return 1;
}

sub get_job_name_by_id {
    my $pilite_full_dir = shift;
    my $rnd_job_name = shift;
    my $piLiteLog = shift;
    my $local_rnd_full_job_dir = $pilite_full_dir.'/.'.$rnd_job_name;
    my $local_job_description = $local_rnd_full_job_dir.'/'.$rnd_job_name;
    my $fd;
    if (not(open($fd, $local_job_description))) {
        my $fdlog;
        open($fdlog, ">>", $piLiteLog);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." Global checks: ERROR: Can not open file: ".$local_job_description."\n";
        close($fdlog);
        return "";
    }
    my $short_job_name = <$fd>;
    close($fd);
    if ((not defined $short_job_name) or (not length $short_job_name) or (not (-e $local_rnd_full_job_dir.'/'.$short_job_name))) {
        my $fdlog;
        open($fdlog, ">>", $piLiteLog);
        if ((not defined $short_job_name) or (not length $short_job_name)) {
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." Global checks: ERROR: job file for the job with ID=".$rnd_job_name." is not defined\n";
        } else {
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." Global checks: ERROR: job file for the job with ID=".$rnd_job_name." does not exist\n";
        }
        close($fdlog);
        return "";
    } else {
        return $short_job_name;
    }
}

sub check_params {
    my %results = (local_home_dir => '', local_key_file => '', local_script_dir => '',
                   remote_host_name => '', remote_user_name => '', remote_script_dir => '',
                   ssh_exec => '', scp_exec => '');

    my @pilot_scripts = ('pilot-job-submit', 'pilot-job-status', 'pilot-job-get-output', 'pilot-job-cleanup');
    my $user_home_dir = $ENV{HOME};
    my $piLiteConf = $user_home_dir.'/'.$pilite_dir.'/pilite.conf';
    my $piLiteLog = $user_home_dir.'/'.$pilite_dir.'/'.$pilite_log;
    if ((defined $user_home_dir) and (length $user_home_dir) and 
        (-e $user_home_dir) and #(-e $user_home_dir.'/'.$pilite_dir) and 
        (-e $piLiteConf)) {
        my $fd;
        if (open($fd, $piLiteConf)) {
            while (my $line=<$fd>) {
                my ($key, $value) = split('=', $line, 2);
                my $lc_key = TrimAndLC($key);
                if ((exists $results{$lc_key}) and (defined $value) and (length $value) and ($value !~ m{\A \s+ \z}xms)) {
                    $results{$lc_key} = TrimOnly($value);
                    #print "key = $lc_key, value = ".$results{$lc_key}."\n";
                }
            }
            close($fd);
        }
    }

    foreach my $result_key (keys %results) {
        my $env_name = uc($result_key);
        if ((exists $ENV{$env_name}) and (defined $ENV{$env_name}) and (length $ENV{$env_name})) {
            $results{$result_key} = $ENV{$env_name};
        } 
    }

    $results{user_home_dir} = $user_home_dir;
    $results{pilite_full_dir} = $user_home_dir.'/'.$pilite_dir;
    $results{pilite_dir} = $pilite_dir;
    $results{pilite_log_file} = $piLiteLog;

    my $fdlog;
    open($fdlog, ">>", $results{pilite_log_file});

    ### Local home dir checks
    if ((not defined $results{local_home_dir}) or (not length $results{local_home_dir})) {
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: local home directory (env \$LOCAL_HOME_DIR) is not defined or is empty!\n";
        close($fdlog);
        return \%results;
    }

    ### Key file checks
    if ((not defined $results{local_key_file}) or (not length $results{local_key_file})) {
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: local key file (env \$LOCAL_KEY_FILE) is not defined or is empty!\n";
        close($fdlog);
        return \%results;
    }

    my $path_to_key_file = $results{local_home_dir}.'/.ssh/'.$results{local_key_file};
    if (not(-e $path_to_key_file)) {
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: local key file ($path_to_key_file) does not exist or is not readable!\n";
        close($fdlog);
        return \%results;
    }
    $results{path_to_key_file} = $path_to_key_file;

    ### Local script dir checks
    if ((not defined $results{local_script_dir}) or (not length $results{local_script_dir}) or (not(-d $results{local_script_dir}))) {
        foreach my $pilot_script (@pilot_scripts) {
            if (not (-x './'.$pilot_script)) {
                print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: local script directory (env \$LOCAL_SCRIPT_DIR) is not defined, is empty or is not a directory!\n";
                close($fdlog);
                return \%results;
            }
        }
        $results{local_script_dir} = '.';
    }

    ### Server name checks
    if ((not defined $results{remote_host_name}) or (not length $results{remote_host_name})) {
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: server host name (env \$REMOTE_HOST_NAME) is not defined or is empty!\n";
        close($fdlog);
        return \%results;
    }

    ### Server user name checks
    if ((not defined $results{remote_user_name}) or (not length $results{remote_user_name})) {
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: server user name (env \$REMOTE_USER_NAME) is not defined or is empty!\n";
        close($fdlog);
        return \%results;
    }

    ### Server remote dir checks
    if ((not defined $results{remote_script_dir}) or (not length $results{remote_script_dir})) {
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: server scripts directory (env \$REMOTE_SCRIPT_DIR) is not defined or is empty!\n";
        close($fdlog);
        return \%results;
    }

    ### Check for the ssh executable
    if ((not defined $results{ssh_exec}) or (not length $results{ssh_exec}) or (not (-x $results{ssh_exec}))) {
        my $ssh_exec = qx(which ssh);
        if ((not defined $ssh_exec) or ($ssh_exec !~ m/^ .*\/ssh $/x)) {
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: Can not find SSH executable file!\n";
            close($fdlog);
            return \%results;
        }
        chomp($ssh_exec);
        $results{ssh_exec} = $ssh_exec;
    }

    ### Check for the scp executable
    if ((not defined $results{scp_exec}) or (not length $results{scp_exec}) or (not (-x $results{scp_exec}))) {
        my $scp_exec = qx(which scp);
        if ((not defined $scp_exec) or ($scp_exec !~ m/^ .*\/scp $/x)) {
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))."Global checks: ERROR: Can not find SCP executable file!\n";
            close($fdlog);
            return \%results;
        }
        chomp($scp_exec);
        $results{scp_exec} = $scp_exec;
    }

    $results{success} = 1;
    close($fdlog);

    return \%results;
}

1;
