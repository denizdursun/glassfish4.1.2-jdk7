#!/bin/bash

set -e

ADMIN_PASS=${ADMIN_PASS}
CH_PWFILE="./.admin_pw_changed"
env DB_NAME=""
env DB_PASSWORD=""
env DB_PORT=""
env DB_USER=""
env DB_SERVER=""
env XMS="128m"
env XMX="256m"
env MAX_PERM="64m"

function change_admin_password() {

    echo ""
    echo "=> Changing admin password..."
    /usr/local/bin/change_admin_pass.expect ${ADMIN_PASS}
    echo "=> Done."
    echo ""
    echo "=> Enabling secure admin..."
    /usr/local/bin/asadmin_cmd.expect ${ADMIN_PASS} login
    asadmin enable-secure-admin
    echo "=> Done."

    touch $CH_PWFILE

    echo "========================================================================"
    echo "You can now connect to this Glassfish server using:"
    echo ""
    echo "     admin:$ADMIN_PASS"
    echo ""
    echo "Please remember to change the above password as soon as possible!"
    echo "========================================================================"
    
}

function create_javadb(){
    echo "login"
    /usr/local/bin/asadmin_cmd.expect ${ADMIN_PASS} login
    echo "creating java connection-pool EbysPool"
    asadmin create-jdbc-connection-pool \
        --datasourceclassname org.postgresql.ds.PGSimpleDataSource \
        --restype javax.sql.DataSource \
        --property portNumber=$DB_PORT:password=$DB_PASSWORD:user=$DB_USER:serverName=$DB_SERVER:databaseName=$DB_NAME:LockTimeOut=2000:connectionAttributes=\;create\\=true AppPool
    echo "delete jvm options"
    asadmin delete-jvm-options -XX:MaxPermSize=192m:-XX:NewRatio=2:-Xmx512m:-client
    echo "creating jvm options"
    asadmin create-jvm-options -Xmx$XMX:-Xms$XMS:-Duser.language=en:-Duser.region=us:-Duser.timezone=Europe/Minsk:-XX\\:MaxPermSize=$MAX_PERM:-XX\\:NewRatio=8:-server

    echo "creating java resource wedding-site-db"
    asadmin create-jdbc-resource --connectionpoolid EbysPool jdbc/app
    echo done
}

if [[ ! -f ${CH_PWFILE} ]]; then

    echo "=> Setting up the container for the first time..."
    asadmin start-domain
    change_admin_password
    create_javadb
    asadmin stop-domain
    echo "=> Done."
fi

echo "=> Starting the glassfish server..."
asadmin start-database
asadmin start-domain
echo "=> Done."