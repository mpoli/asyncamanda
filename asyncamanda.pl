#! /usr/bin/perl
# Copyright (c) 2014 Marco Poli.  All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
# 
# Author contact information: Marco Poli <polimarco _+@+_ gmail.com>
# Repository and documentation: https://github.com/mpoli/asyncamanda
#
# Contributions are welcomed!
#

our $VERSION = 0.1;

use lib '/usr/lib/amanda/perl';
use strict;
use warnings;

use Getopt::Long;

use FileHandle;

use Amanda::Config;
use Amanda::Cmdline;

use Net::OpenSSH;

sub usage {
    print <<EOF;
    USAGE: asyncamanda -i|--interval <interval value> -h|--host <[user@]host[:port]> [-k|--key <private_key_path>] -c|--command <command> -a|--amandates <amandates path>
	asyncamanda will check when the last amanda backup was performed, from the information available in the amandates file, and connect to the server and start a backup run if last backup was before the maximum interval.
	Arguments:
	    -i <interval value>                - the backup interval in hours
	    -h <[user[:password]@]host[:port]> - Host and user that runs the amanda backup (amdump) command
	    -k <private_key_path>  (optional)  - private key used to authenticate. i.e. \$HOME/.ssh/id_rsa
	    -c <command>                       - full line of the amdump command on the server. I.e. "/usr/sbin/amdump daily"
	    -a <amandates path>    - path to the local amandates file. Ex. /var/lib/amanda/amandates
EOF
    exit(1);
}

my $exit_code = 0;

# treating command line options
my $interval = '';
my $host = '';
my $key = '';
my $command = '';
my $amandates = '';

Getopt::Long::Configure(qw(auto_version));
GetOptions (
    'interval|i=i' => \$interval,
    'host|h=s' => \$host,
    'key|k=s' => \$key,
    'command|c=s' => \$command,
    'amandates|a=s' => \$amandates,
) or usage();

# If some of the option is missing, just show usage and quit
usage() if (@ARGV > 0 || !$interval || !$host || !$command || !$amandates);

open (AMANDATES, $amandates) or die "ERROR: Could not open $amandates. $!";

my $disk = '';
my $level = '';
my $timestamp = '';
my $most_recent = '';


# Browse amandates to check for most recent backup.
# TODO: There must be a better way to do this, and what happens if amandates gets too large? Sort and quicksearch, perhaps.
while (<AMANDATES>) {
    chomp;
    ($disk, $level, $timestamp) = split("\x20");
    
    if (!$most_recent || $timestamp > $most_recent) {
	$most_recent = $timestamp;
    }

#    print "Most recent: $most_recent\n";

}
close(AMANDATES);

# convert interval in hours to seconds
my $interval_sec = $interval * 60 * 60;

# if the most recent backup is older than the interval, make a backup run
if ((time() - $most_recent) > $interval_sec) {
    my $ssh = '';
    # execute the backup
    if (!$key){ # no key path was given as option
	$ssh = Net::OpenSSH->new($host);
    }
    else {  # login using public key authentication
	$ssh = Net::OpenSSH->new($host, key_path => $key);
    }

    $ssh->error and
	die "Couldn't establish SSH connection: " . $ssh->error;
    
    $ssh->system($command) or
	die "remote command failed: " . $ssh->error;
}

exit(0);
