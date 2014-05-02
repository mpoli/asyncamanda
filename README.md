asyncamanda
===========

AMANDA for the roaming laptop and road warrior. Check for last backup run and connect to the amanda server and execute the backup command if overdue. Use with anacron or alike.

Amanda has no native way of dealing with hosts that aren't available when the backup run occurs. If the host is not available, it will have to wait until the next scheduled backup run to be backed up.

Especially when dealing with notebooks/laptops or even desktops that aren't always online, this can become a huge limitation, with weeks going by without backup runs being performed.

asyncamanda changes the way backups for these machines are done: the client will actively start the backup cycle, when it is available, and will call amdump on amanda server when it is online.

The recommended way of execution is to setup Anacron to run 

#Pre-requisites#

* OpenSSH

* Net::OpenSSH

* A GNUTAR Amanda backup dumptype (will not work with other backup methods)

* Password or preferably public-key login access to the user amanda runs backup with on the server

* Anacron, cron or alike

#Installation#

* Drop the script anywhere you know about. System-wide execution paths like usr/bin or /usr/sbin or /usr/local/bin or /usr/local/sbin are recommended. 

* Check the first line and point it to your perl interpreter, right after the she-bang (the #! characters).

* Make sure the user that executes the script has read access to the amandates file, and that it can connect using public-key authentication to the server. 

* If you don't have a private/public key already generated (i.e. in $HOME/.ssh/id_rsa):

    ssh-keygen -t rsa

Create it in the suggested place ($HOME/.ssh/id_rsa) if you don't know what you are doing. Leave the passphrase empty otherwise the script will not be able to use the key without human intervention.

* Now copy the file $HOME/.ssh/id_rsa.pub you just generated in the CLIENT as the $HOME/.ssh/authorized_keys file in the SERVER, under the $HOME of the user that will be used to run amdump (described in the configuration directive of amanda.conf). If there is already a authorized_keys file in place, just append with a:

    cat id_rsa.pub >> $HOME/.ssh/authorized_keys

* Verify that you can connect, in the CLIENT:

    ssh -i $HOME/.ssh/id_rsa <user@SERVER>

This step is important as you will be verifying the server's identity and as such OpenSSH will not bug you next time asking, which would break the script.

* As an optional step you can run:

    ssh-add ~/.ssh/id_rsa

So this key will be added to the ssh-agent and you will not need to provide it as the -k|--key option to the script, openssh will automatically try to use it at every connection it makes.

* Install Net::OpenSSH

    cpan install Net::OpenSSH

* Create the directory ~/.libnet-openssh-perl and change its ownership to the user. Pay attention on the fact that backup users usually have home directories owned by root. This is okay, as long as you create this dir under the home directory and change its ownership to the user that amanda uses as its backup user.

* Configure it in Anacron, as described in the Execution section below.

#Execution#

asyncamanda should be run by something like anacron.

It is recommended that you create a config file specific for the machine using asyncamanda, so that when you invoke the amdump command it won't take the execution cycle of other disks/partitions/machines out of sync.

##Usage##

    asyncamanda -i|--interval <interval value> -h|--host <[user@]host[:port]> [-k|--key <private_key_path>] -c|--command <command> -a|--amandates <amandates path>

###Arguments###
    -i <interval value>                - the backup interval in hours
    -h <[user[:password]@]host[:port]> - Host and user that runs the amanda backup (amdump) command
    -k <private_key_path>  (optional)  - private key used to authenticate. i.e. \$HOME/.ssh/id_rsa
    -c <command>                       - full line of the amdump command on the server. I.e. "/usr/sbin/amdump daily"
    -a <amandates path>    - path to the local amandates file. Ex. /var/lib/amanda/amandates

###Example###

    asyncamanda.pl -i 24 -h amanda.example.com -k ~/.ssh/id_rsa -c "/usr/sbin/amdump daily" -a /var/lib/amanda/amandates

##Anacron##

The following Anacron config will run the script once daily 20 minutes after boot.

    # cat /etc/anacrontab
    1       20      asyncamanda.daily      /usr/bin/perl /var/backups/asyncamanda.pl -i 24 -h amanda.example.com -k /var/backups/.ssh/id_rsa -c "/usr/sbin/amdump daily" -a /var/lib/amanda/amandates

#Bugs/Caveats#

* If the script is run more than once while a backup is being performed and is not finished, it will start another instance of the amdump program.

* Due to having to connect to the server using the backup-user, it is recommended that you create a user to run only for the machines using this script, for secutiry reasons. Given that amanda selects the user from the amanda.conf file, this shouldn't be hard.

* Having a specific config in the server for the machine running this script will prevent optimal bandwidth management by the amanda scheduler.

* Need to improve the interval entrance option.
