FROM jboss/wildfly

LABEL Name=liferay Version=0.0.1 

# Environment
ENV     LIFERAY_VERSION="7.0.3 GA4" \
        LIFERAY_LCASE_VERSION="7.0-ga4" \
        LIFERAY_FULL_VERSION="7.0-ga4-20170613175008905" \
        LIFERAY_OSGI_SERVICE_TRACKER_VERSION="2.0.2" \
        LIFERAY_REGISTRY_API_VERSION="1.1.0" \
#Database
        POSTGRESQL_VERSION="42.1.4" \
        POSTGRESQL_SHA1SUM="1c7788d16b67d51f2f38ae99e474ece968bf715a" \
        MYSQL_VERSION="5.1.43" \
        MYSQL_SHA1SUM="dee9103eec0d877f3a21c82d4d9e9f4fbd2d6e0a" \
        MARIADB_SHA1SUM="639be502c0d191e1cc21e4e86d388486358fddf8" \
        MARIADB_VERSION="2.1.0" \
        HSQL_VERSION="2.4.0" \
        HSQL_SHA1SUM="195957160ed990dbc798207c0d577280d9919208" \
#PATH
        DOWNLOADS=/tmp/downloads \
        WILDFLY_HOME=/opt/jboss/wildfly \
        JBOSS_FILE=/opt/jboss/files 
#ARGS
ARG USERNAME=admin 
ARG PASSWORD=admin

USER root 

# Configurando Wildfly
COPY    files $JBOSS_FILE

        #Create folder
RUN     mkdir -p $DOWNLOADS && \
        mkdir -p $WILDFLY_HOME/modules/com/liferay/portal/main && \
        mkdir -p $WILDFLY_HOME/modules/system/layers/base/org/mariadb/main && \ 
        mkdir -p $WILDFLY_HOME/modules/system/layers/base/org/postgresql/main && \
        mkdir -p $WILDFLY_HOME/modules/system/layers/base/com/mysql/main && \
        mkdir -p $WILDFLY_HOME/modules/system/layers/base/org/hsqldb/main && \
        mkdir -p /opt/jboss/osgi/ && \
        # Install wget
        yum install -y wget && \
        mv $JBOSS_FILE/standalone.xml            $WILDFLY_HOME/standalone/configuration/ && \
        mv $JBOSS_FILE/server.policy             $WILDFLY_HOME/bin && \
        mv $JBOSS_FILE/standalone.conf           $WILDFLY_HOME/bin && \
        mv $JBOSS_FILE/liferay/module.xml        $WILDFLY_HOME/modules/com/liferay/portal/main && \
        mv $JBOSS_FILE/mariadb/module.xml        $WILDFLY_HOME/modules/system/layers/base/org/mariadb/main/ && \
        mv $JBOSS_FILE/mysql/module.xml          $WILDFLY_HOME/modules/system/layers/base/com/mysql/main/ && \
        mv $JBOSS_FILE/postgresql/module.xml     $WILDFLY_HOME/modules/system/layers/base/org/postgresql/main/ && \
        mv $JBOSS_FILE/hsqldb/module.xml         $WILDFLY_HOME/modules/system/layers/base/org/hsqldb/main/

WORKDIR $DOWNLOADS

#Download connectors 
RUN     wget "https://downloads.mariadb.com/Connectors/java/connector-java-$MARIADB_VERSION/mariadb-java-client-$MARIADB_VERSION.jar" -O  "mariadb-java-client.jar" \
        && sha1sum mariadb-java-client.jar > mariadb-java-client.jar.sha1sum \
        && sha1sum -c mariadb-java-client.jar.sha1sum \
        && mv mariadb-java-client.jar $WILDFLY_HOME/modules/system/layers/base/org/mariadb/main \
        && wget "https://jdbc.postgresql.org/download/postgresql-$POSTGRESQL_VERSION.jar" -O "postgresql.jar" \
        && sha1sum postgresql.jar > postgresql.jar.sha1sum \
        && sha1sum -c postgresql.jar.sha1sum \
        && cp postgresql.jar $WILDFLY_HOME/modules/com/liferay/portal/main \
        && mv postgresql.jar $WILDFLY_HOME/modules/system/layers/base/org/postgresql/main \
        && wget "http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.43/mysql-connector-java-$MYSQL_VERSION.jar" -O "mysql-connector-java.jar" \
        && sha1sum mysql-connector-java.jar > mysql-connector-java.jar.sha1sum \
        && sha1sum -c mysql-connector-java.jar.sha1sum \
        && mv mysql-connector-java.jar $WILDFLY_HOME/modules/system/layers/base/com/mysql/main && \
        wget "http://central.maven.org/maven2/org/hsqldb/hsqldb/$HSQL_VERSION/hsqldb-$HSQL_VERSION.jar" -O "hsqldb.jar" \
        && sha1sum hsqldb.jar > hsqldb.jar.sha1sum \
        && sha1sum -c hsqldb.jar.sha1sum \
        && cp hsqldb.jar $WILDFLY_HOME/modules/com/liferay/portal/main \
        && mv hsqldb.jar $WILDFLY_HOME/modules/system/layers/base/org/hsqldb/main/ && \
#Download liferay 
        wget "https://repository.liferay.com/nexus/content/repositories/liferay-public-releases/com/liferay/com.liferay.registry.api/$LIFERAY_REGISTRY_API_VERSION/com.liferay.registry.api-$LIFERAY_REGISTRY_API_VERSION.jar" -O "com.liferay.registry.api.jar" \
        && mv com.liferay.registry.api.jar -t $WILDFLY_HOME/modules/com/liferay/portal/main \
        && wget "http://central.maven.org/maven2/com/liferay/com.liferay.osgi.service.tracker.collections/$LIFERAY_OSGI_SERVICE_TRACKER_VERSION/com.liferay.osgi.service.tracker.collections-$LIFERAY_OSGI_SERVICE_TRACKER_VERSION.jar" -O "com.liferay.osgi.service.tracker.collections.jar" \
        && mv com.liferay.osgi.service.tracker.collections.jar -t $WILDFLY_HOME/modules/com/liferay/portal/main \
        && wget "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/$LIFERAY_VERSION/liferay-ce-portal-dependencies-$LIFERAY_FULL_VERSION.zip/download" -O "liferay-ce-portal-dependencies-$LIFERAY_FULL_VERSION.zip" \
        && unzip liferay-ce-portal-dependencies-$LIFERAY_FULL_VERSION.zip \
        && mv liferay-ce-portal-dependencies-$LIFERAY_LCASE_VERSION/* $WILDFLY_HOME/modules/com/liferay/portal/main \
        && wget "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/$LIFERAY_VERSION/liferay-ce-portal-osgi-$LIFERAY_FULL_VERSION.zip/download" -O "liferay-ce-portal-osgi-$LIFERAY_FULL_VERSION.zip" \
        && unzip liferay-ce-portal-osgi-$LIFERAY_FULL_VERSION.zip \
        && mv liferay-ce-portal-osgi-$LIFERAY_LCASE_VERSION/* /opt/jboss/osgi/ && \
        wget "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/$LIFERAY_VERSION/liferay-ce-portal-$LIFERAY_FULL_VERSION.war/download" -O "liferay-ce-portal-$LIFERAY_FULL_VERSION.war"  \
        && unzip liferay-ce-portal-$LIFERAY_FULL_VERSION.war -d $WILDFLY_HOME/standalone/deployments/ROOT.war \
        && rm liferay-ce-portal-$LIFERAY_FULL_VERSION.war \
        && echo "" > $WILDFLY_HOME/standalone/deployments/ROOT.war.dodeploy \
        && echo "jdbc.default.jndi.name=java:jboss/datasources/PostegresXADS"

# Clean and permissions
RUN     rm -rf $DOWNLOADS && chown -R jboss:0 $WILDFLY_HOME
RUN     /opt/jboss/wildfly/bin/add-user.sh $USERNAME $PASSWORD --silent

CMD     ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]