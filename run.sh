#!/bin/bash

# -----------------------------------------------------------------------------------------------------------------------------
# GENERAL
# -----------------------------------------------------------------------------------------------------------------------------
#
# author: Sebastiaan Van Hoecke
# mail: sebastiaan@sevaho.io
#
# -----------------------------------------------------------------------------------------------------------------------------

if [[ $USER == "" || $PASS == "" ]]; then 

    echo "Set credentials!"
    echo "Example: "
    echo ""
    echo 'docker run -e USER="admin" -e PASS="admin" -p 80:80 -p 443:443 openvas'

    exit 1

else

    echo "Credentials are set."

fi

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
    /usr/sbin/openvasmd --create-user=$USER
    /usr/sbin/openvasmd --user=admin --new-password=$PASS

done

service cron restart

/usr/sbin/openvasmd --rebuild

curl -k https://svn.wald.intevation.org/svn/openvas/trunk/tools/openvas-check-setup | bash

gsad -f --listen=0.0.0.0 --mlisten=0.0.0.0 --mport=9390
