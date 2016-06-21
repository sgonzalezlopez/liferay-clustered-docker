FROM centos

MAINTAINER AXA MedLA

# install liferay

ENV http_proxy http://${proxyHost}:${proxyPort}
ENV https_proxy http://${proxyHost}:${proxyHost}
ENV LIFERAY_HOME /opt/liferay 
ENV CATALINA_OPTS -Dhttp.proxyHost=${proxyHost} -Dhttp.proxyPort=${proxyPort} -Dhttps.proxyHost=${proxyHost} -Dhttps.proxyPort=${proxyPort}

RUN cd /opt \
&& curl -LO -x ${http_proxy} https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 \
&& chmod 777 /opt/confd-0.11.0-linux-amd64 \
&& mv confd-0.11.0-linux-amd64 confd \
&& mkdir -p /etc/confd/{conf.d,templates}

ADD /confd/portal-bundle.properties.tmpl /etc/confd/templates/
ADD /confd/portal-bundle.properties.toml /etc/confd/conf.d/
ADD /confd/cluster-config.xml.tmpl /etc/confd/templates/
ADD /confd/cluster-config.xml.toml /etc/confd/conf.d/
ADD /confd/portal-ext.properties.tmpl /etc/confd/templates/
ADD /confd/portal-ext.properties.toml /etc/confd/conf.d/


RUN yum -y update \
&& yum install -y unzip \ 
&& yum clean all

RUN cd /tmp \
&& curl --digest -x ${http_proxy} --user ${REPO_USER}:${REPO_PASS} -LO http://filerepo.osappext.pink.eu-central-1.aws.openpaas.axa-cloud.com/liferay-docker/jdk-7u79-linux-x64.rpm \
&& rpm -i /tmp/jdk-7u79-linux-x64.rpm \
&& rm -f /tmp/jdk-7u79-linux-x64.rpm

RUN cd /tmp \
&& curl --digest -x ${http_proxy} --user ${REPO_USER}:${REPO_PASS} -LO http://filerepo.osappext.pink.eu-central-1.aws.openpaas.axa-cloud.com/liferay-docker/liferay-portal-tomcat-6.2-ee-sp14-20151105114451508.zip \
&& unzip /tmp/liferay-portal-tomcat-6.2-ee-sp14-20151105114451508.zip -d /opt \
&& rm -f /tmp/liferay-portal-tomcat-6.2-ee-sp14-20151105114451508.zip \
&& ln -s /opt/liferay-portal-6.2-ee-sp14 /opt/liferay

RUN mkdir /opt/liferay/deploy/ \
&& cd /opt/liferay/deploy/ \
&& curl --digest -x ${http_proxy} --user ${REPO_USER}:${REPO_PASS} -LO http://filerepo.osappext.pink.eu-central-1.aws.openpaas.axa-cloud.com/liferay-docker/license-portaldevelopment-developer-6.2ee-axa.xml

RUN groupadd 1000 \
    && useradd -g 1000 -d $LIFERAY_HOME -s /bin/bash -c "Docker image user" 1000 \
    && chown -R 1000:1000 /opt/liferay \
    && chmod -R 777 /opt/liferay

USER 1000

ADD ejecuta.sh /opt/liferay/
RUN chown 1000:1000 /opt/liferay/ejecuta.sh \
&& chmod +x /opt/liferay/ejecuta.sh

#RUN /opt/confd -onetime -backend env

EXPOSE 8080 8009

WORKDIR $LIFERAY_HOME

ENTRYPOINT ["/opt/liferay/ejecuta.sh"]
