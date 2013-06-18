package PilotCheckParams;

use strict;
use warnings;
use POSIX;

my $short_pilite_dir = '.piLite';
my $short_pilite_conf_dir = 'conf';
my $short_pilite_log_filename = 'pilite.log';
my $short_pilite_conf_filename = 'pilite.conf';
my $short_pilite_user_working_dir = 'workdir';

sub get_current_pilite_user {
    my $required_params_count = shift;
    my $args = shift;
    if ($#{$args} > $required_params_count-1) {
        return $args->[$required_params_count];
    } else {
        return $ENV{USER};
    }
}

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
    my $full_pilite_log_filename = shift;
    ### Check if a job definition is defined
    if ((not defined $job_file_name) or (not length $job_file_name)) {
        my $fdlog;
        open($fdlog, ">>", $full_pilite_log_filename);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." pilot-job-submit: ERROR:\n";
        print $fdlog "usage: pilot-job-submit job_definition.js ...\n\n";
        print $fdlog " Submit a job to Pilot service.\n";
        close($fdlog);
        return 0;
    }

    ### Check if a job definition file exists
    if (not(-e $job_file_name)) {
        my $fdlog;
        open($fdlog, ">>", $full_pilite_log_filename);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." pilot-job-submit: ERROR: job definition file not found: '".$job_file_name."'\n";
        close($fdlog);
        return 0;
    }
    return 1;
}

sub get_job_name_by_id {
    my $local_pilite_user_dir = shift;
    my $job_id = shift;
    my $full_pilite_log_filename = shift;
    my $local_full_job_dir = $local_pilite_user_dir.'/'.$job_id;
    my $local_job_description = $local_full_job_dir.'/'.$job_id;
    my $fd;
    if (not(open($fd, $local_job_description))) {
        my $fdlog;
        open($fdlog, ">>", $full_pilite_log_filename);
        print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." Global checks: ERROR: Can not open file: ".$local_job_description."\n";
        close($fdlog);
        return "";
    }
    my $short_job_name = <$fd>;
    close($fd);
    if ((not defined $short_job_name) or (not length $short_job_name) or (not (-e $local_full_job_dir.'/'.$short_job_name))) {
        my $fdlog;
        open($fdlog, ">>", $full_pilite_log_filename);
        if ((not defined $short_job_name) or (not length $short_job_name)) {
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." Global checks: ERROR: job file for the job with ID=".$job_id." is not defined\n";
        } else {
            print $fdlog strftime("%Y-%m-%d %H:%M:%S", localtime(time))." Global checks: ERROR: job file for the job with ID=".$job_id." does not exist\n";
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
    my $full_pilite_conf_dir = $user_home_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir;
    my $full_pilite_conf_filename = $full_pilite_conf_dir.'/'.$short_pilite_conf_filename;
    my $full_pilite_log_filename = $full_pilite_conf_dir.'/'.$short_pilite_log_filename;

    if ((defined $user_home_dir) and (length $user_home_dir) and 
        (-e $user_home_dir) and (-e $user_home_dir.'/'.$short_pilite_dir) and (-e $user_home_dir.'/'.$short_pilite_dir.'/'.$short_pilite_conf_dir) and
        (-e $full_pilite_conf_filename)) {
        my $fd;
        if (open($fd, $full_pilite_conf_filename)) {
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
    $results{full_pilite_dir} = $user_home_dir.'/'.$short_pilite_dir;
    $results{short_pilite_dir} = $short_pilite_dir;
    $results{short_pilite_conf_dir} = $short_pilite_conf_dir;
    $results{full_pilite_log_file} = $full_pilite_log_filename;
    $results{short_pilite_user_working_dir} = $short_pilite_user_working_dir;

    ### Check if the piLite conf directory exists
    if (not (-e $full_pilite_conf_dir)) {
        mkdir $full_pilite_conf_dir;
    }

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
