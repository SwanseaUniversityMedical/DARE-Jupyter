#!/bin/bash

launcherJar=( server/plugins/org.eclipse.equinox.launcher*.jar )

echo "Starting Cloudbeaver Server"

java ${JAVA_OPTS} -jar ${launcherJar} -product io.cloudbeaver.product.ce.product -web-config conf/cloudbeaver.conf -nl en -registryMultiLanguage