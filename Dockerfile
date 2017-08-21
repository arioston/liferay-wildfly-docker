FROM jboss/wildfly

LABEL Name=liferay Version=0.0.1 

# Environment
ENV LIFERAY_VERSION "7.0.3 GA4"
ENV LIFERAY_LCASE_VERSION "7.0-ga4"
ENV LIFERAY_FULL_VERSION "7.0-ga4-20170613175008905"
ENV LIFERAY_OSGI_SERVICE_TRACKER_VERSION "2.0.2"
ENV LIFERAY_REGISTRY_API_VERSION "1.1.0"

#Database
ENV POSTGRESQL_VERSION "42.1.4"
ENV POSTGRESQL_SHA1SUM "1c7788d16b67d51f2f38ae99e474ece968bf715a"

ENV MYSQL_VERSION "5.1.43"
ENV MYSQL_SHA1SUM "dee9103eec0d877f3a21c82d4d9e9f4fbd2d6e0a"

ENV MARIADB_SHA1SUM "639be502c0d191e1cc21e4e86d388486358fddf8"
ENV MARIADB_VERSION "2.1.0"

#PATH
ENV DOWNLOADS   /tmp/downloads
ENV WILDFLY_HOME  /opt/jboss/wildfly
ENV JBOSS_FILE /opt/jboss/files

#ARGS
ARG USERNAME=admin 
ARG PASSWORD=admin

USER root 

#Create folder
RUN mkdir $DOWNLOADS &&  mkdir -p $WILDFLY_HOME/modules/com/liferay/portal/main

# Install wget
RUN yum install -y wget

# Configurando Wildfly
COPY files/module.xml $WILDFLY_HOME/modules/com/liferay/portal/main
COPY files/standalone.xml $WILDFLY_HOME/standalone/configuration/
COPY files/server.policy $WILDFLY_HOME/bin
COPY files/standalone.conf $WILDFLY_HOME/bin

WORKDIR $DOWNLOADS

#Download connectors 
RUN wget "https://downloads.mariadb.com/Connectors/java/connector-java-$MARIADB_VERSION/mariadb-java-client-$MARIADB_VERSION.jar" -O  "mariadb-java-client.jar" \
    && sha1sum mariadb-java-client.jar > mariadb-java-client.jar.sha1sum \
    && sha1sum -c mariadb-java-client.jar.sha1sum \
    && mv mariadb-java-client.jar $WILDFLY_HOME/modules/com/liferay/portal/main \
    && wget "https://jdbc.postgresql.org/download/postgresql-$POSTGRESQL_VERSION.jar" -O "postgresql.jar" \
    && sha1sum postgresql.jar > postgresql.jar.sha1sum \
    && sha1sum -c postgresql.jar.sha1sum \
    && mv postgresql.jar $WILDFLY_HOME/modules/com/liferay/portal/main \
    && wget "http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.43/mysql-connector-java-$MYSQL_VERSION.jar" -O "mysql-connector-java.jar" \
    && sha1sum mysql-connector-java.jar > mysql-connector-java.jar.sha1sum \
    && sha1sum -c mysql-connector-java.jar.sha1sum \
    && mv mysql-connector-java.jar $WILDFLY_HOME/modules/com/liferay/portal/main

#Download liferay 
RUN wget "https://repository.liferay.com/nexus/content/repositories/liferay-public-releases/com/liferay/com.liferay.registry.api/$LIFERAY_REGISTRY_API_VERSION/com.liferay.registry.api-$LIFERAY_REGISTRY_API_VERSION.jar" -O "com.liferay.registry.api.jar" \
    && mv com.liferay.registry.api.jar -t $WILDFLY_HOME/modules/com/liferay/portal/main \
    && wget "http://central.maven.org/maven2/com/liferay/com.liferay.osgi.service.tracker.collections/$LIFERAY_OSGI_SERVICE_TRACKER_VERSION/com.liferay.osgi.service.tracker.collections-$LIFERAY_OSGI_SERVICE_TRACKER_VERSION.jar" -O "com.liferay.osgi.service.tracker.collections.jar" \
    && mv com.liferay.osgi.service.tracker.collections.jar -t $WILDFLY_HOME/modules/com/liferay/portal/main \
    && wget "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/$LIFERAY_VERSION/liferay-ce-portal-dependencies-$LIFERAY_FULL_VERSION.zip/download" -O "liferay-ce-portal-dependencies-$LIFERAY_FULL_VERSION.zip" \
    && unzip liferay-ce-portal-dependencies-$LIFERAY_FULL_VERSION.zip \
    && mv liferay-ce-portal-dependencies-$LIFERAY_LCASE_VERSION/* $WILDFLY_HOME/modules/com/liferay/portal/main \
    && wget "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/$LIFERAY_VERSION/liferay-ce-portal-osgi-$LIFERAY_FULL_VERSION.zip/download" -O "liferay-ce-portal-osgi-$LIFERAY_FULL_VERSION.zip" \
    && unzip liferay-ce-portal-osgi-$LIFERAY_FULL_VERSION.zip \
    && mkdir $WILDFLY_HOME/modules/com/liferay/osgi \
    && mv liferay-ce-portal-osgi-$LIFERAY_LCASE_VERSION/* $WILDFLY_HOME/modules/com/liferay/osgi/

RUN wget "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/$LIFERAY_VERSION/liferay-ce-portal-$LIFERAY_FULL_VERSION.war/download" -O "liferay-ce-portal-$LIFERAY_FULL_VERSION.war"  \
    && unzip liferay-ce-portal-$LIFERAY_FULL_VERSION.war -d $WILDFLY_HOME/standalone/deployments/ROOT.war \
    && rm liferay-ce-portal-$LIFERAY_FULL_VERSION.war \
    && echo "" > ROOT.war.dodeploy \
    && mv ROOT.war.dodeploy $WILDFLY_HOME/standalone/deployments

# Clean and permissions
RUN rm -rf $DOWNLOADS && chown -R jboss:0 $WILDFLY_HOME

# Configure wildfly adm
RUN /opt/jboss/wildfly/bin/add-user.sh $USERNAME $PASSWORD --silent
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]