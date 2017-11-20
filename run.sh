#!/bin/bash

# -----------------------------------------------------------------------------------------------------------------------------
# GENERAL
# -----------------------------------------------------------------------------------------------------------------------------
#
# author: Sebastiaan Van Hoecke
# mail: sebastiaan@sevaho.io
#
# -----------------------------------------------------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------------------------------------------------------

install () {

    sed -i 's/# unixsocket \/var\/run\/redis\/redis.sock/unixsocket \/tmp\/redis.sock/' /etc/redis/redis.conf
    service redis-server restart

    /usr/sbin/openvas-mkcert -q
    /usr/sbin/openvas-nvt-sync
    /usr/sbin/openvas-scapdata-sync
    /usr/sbin/openvas-certdata-sync

    service openvas-scanner restart

    /usr/sbin/openvasmd --update
    /usr/sbin/openvasmd --rebuild
    /usr/bin/openvas-mkcert-client -ni

    service openvas-manager restart

    mkdir -p /var/spool/cron/crontabs
    echo "0 1 * * * openvas-nvt-sync" >> /var/spool/cron/crontabs/root
    echo "0 1 * * * openvas-scapdata-sync" >> /var/spool/cron/crontabs/root
    echo "0 1 * * * openvas-certdata-sync" >> /var/spool/cron/crontabs/root
    echo "0 1 * * * openvasmd --rebuild" >> /var/spool/cron/crontabs/root

    while [[ $(openvasmd --get-users) == "" ]]; do

        echo "Setting up user credentials"
        /usr/sbin/openvasmd --create-user=$user
        /usr/sbin/openvasmd --user=admin --new-password=$pass

    done

    service cron restart

    /usr/sbin/openvasmd --rebuild

}

check_args () {

    if [[ "$#" -eq "0" ]]; then

        usage

    fi

    while getopts :u:p: opt; do

        case $opt in

            u)  user="$OPTARG";;
            p)  pass="$OPTARG";;
            ?)  usage;; 

        esac

    done

    shift "$(expr $OPTIND - 1)"

    [[ $user == "" || $pass == "" ]] && usage

}

usage () {

cat << _EOF_
Usage: ${0} [OPTIONS]... [ARGS]...

    install openvas

OPTIONS:

    -u <user>          set the username
    -p <pass>          set the password

EXAMPLES:

    run -u admin -p admin123

_EOF_

exit 1

}

# -----------------------------------------------------------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------------------------------------------------------

main () {

    local user=
    local pass=

    check_args "${@}"
    install

    curl -k https://svn.wald.intevation.org/svn/openvas/trunk/tools/openvas-check-setup | bash

    gsad -f --listen=0.0.0.0 --mlisten=0.0.0.0 --mport=9390

}

main "${@}"
