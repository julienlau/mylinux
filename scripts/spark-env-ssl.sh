#!/bin/bash
# inputs : copy all your custom ssl cert in /usr/local/share/ca-certificates/ and this script will update linux and java ssl certs

set -e

if [[ -z "${SPARK_HOME}" ]] ; then
    echo "please set SPARK_HOME"
    exit 9
fi

if [[ ! -z `ls /usr/local/share/ca-certificates/ 2>/dev/null` ]] ; then
    update-ca-certificates --verbose

    for PEM_FILE in `ls /usr/local/share/ca-certificates/ 2>/dev/null`; do
        echo "adding /usr/local/share/ca-certificates/${PEM_FILE} to java cacert"
        PASSWORD="changeit"
        JAVA_HOME=$(readlink -f `which java` | sed "s:/bin/java::")
        KEYSTORE="$JAVA_HOME/lib/security/cacerts"

        CERTS=$(grep 'END CERTIFICATE' /usr/local/share/ca-certificates/$PEM_FILE| wc -l)

        # To process multiple certs with keytool, you need to extract
        # each one from the PEM file and import it into the Java KeyStore.
        for N in $(seq 0 $(($CERTS - 1))); do
            ALIAS="$(basename $PEM_FILE)-$N"
            echo "Adding to keystore with alias:$ALIAS"
            # generates a keytool warning: use -cacerts option to access cacerts keystore
            # cat /usr/local/share/ca-certificates/$PEM_FILE |
            #     awk "n==$N { print }; /END CERTIFICATE/ { n++ }" |
            #     keytool -noprompt -import -trustcacerts -alias $ALIAS -keystore $KEYSTORE -storepass $PASSWORD

            # for JDK 9+ keytool option -cacerts is necessary
            cat /usr/local/share/ca-certificates/$PEM_FILE |
                awk "n==$N { print }; /END CERTIFICATE/ { n++ }" |
                keytool -noprompt -import -trustcacerts -cacerts -alias $ALIAS -storepass $PASSWORD
        done
    done
    echo "export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt" >> ${SPARK_HOME}/conf/spark-env.sh

else
    echo "no local cert found"
fi
