#!/bin/sh
/opt/confd -onetime -backend env
/opt/liferay/tomcat-7.0.42/bin/catalina.sh run
