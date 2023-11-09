#! /bin/bash
KEYSTORE="${JAVA_HOME}/lib/security/cacerts"

if [ -d /certs ]
then
	if [ "$(ls -A /certs)" ]; then
		for cert in /certs/*
		do
			ALIAS="${cert##*/}"
			keytool -import -noprompt -trustcacerts -storepass changeit -file $cert -alias $ALIAS -keystore ${KEYSTORE}
			mv $cert /usr/local/share/ca-certificates/$ALIAS.crt
		done
	fi
else
	echo "Directory /certs not found."
fi

chmod 644 /usr/local/share/ca-certificates/*.crt
update-ca-certificates