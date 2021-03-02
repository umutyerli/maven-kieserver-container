#FROM docker.artifactory.apps.ecicd.dso.ncps.us-cert.gov/openjdk/openjdk-8-rhel8:latest
FROM registry.redhat.io/openjdk/openjdk-11-rhel8:latest
#FROM docker-registry.default.svc:5000/openshift/openjdk-8-rhel8:latest
EXPOSE 8080
ENV HOME /opt/app
ENV M2_HOME /home/jboss/.m2
ENV KJAR_VERSION 1.0.0-SNAPSHOT
#ENV TRACE_VERSION 1.0-SNAPSHOT
ENV KJAR_ARTIFACT mortgages:mortgages:${KJAR_VERSION}
WORKDIR /opt/app

USER root

# Add kie server jar
COPY kie-server/target/*.jar /opt/app/target/app.jar

# Copy settings.xml into maven home
COPY kie-server/src/main/docker/settings.xml ${M2_HOME}/settings.xml

# Add kjar and pom.xml into maven local cache
RUN mkdir -p ${M2_HOME}/repository/mortgages/mortgages/${KJAR_VERSION}
#COPY /tmp/my.jar ${M2_HOME}/repository/mortgages/mortgages/${KJAR_VERSION}/mortgages-${KJAR_VERSION}.jar
#COPY /tmp/pom.xml ${M2_HOME}/repository/mortgages/mortgages/${KJAR_VERSION}/mortgages-${KJAR_VERSION}.pom
RUN touch ${M2_HOME}/repository/mortgages/mortgages/${KJAR_VERSION}/resolver-status.properties

# Download KIE JAR
RUN curl -u admin:admin123 -L -X GET 'http://nexus-route-test1.apps.cluster-5287.5287.sandbox1757.opentlc.com/service/rest/v1/search/assets/download?sort=version&repository=maven-snapshots&group=mortgages&name=mortgages&maven.baseVersion=1.0.0-SNAPSHOT&maven.extension=jar' --output ${M2_HOME}/repository/mortgages/mortgages/${KJAR_VERSION}/mortgages-${KJAR_VERSION}.jar

# Download KIE POM
RUN curl -u admin:admin123 -L -X GET 'http://nexus-route-test1.apps.cluster-5287.5287.sandbox1757.opentlc.com/service/rest/v1/search/assets/download?sort=version&repository=maven-snapshots&group=mortgages&name=mortgages&maven.baseVersion=1.0.0-SNAPSHOT&maven.extension=pom' --output ${M2_HOME}/repository/mortgages/mortgages/${KJAR_VERSION}/mortgages-${KJAR_VERSION}.pom

#RUN mkdir -p ${M2_HOME}/repository/com/malware/trace-event-listeners/${TRACE_VERSION}
#COPY trace-event-listeners/target/trace-event-listeners-${TRACE_VERSION}.jar ${M2_HOME}/repository/com/malware/trace-event-listeners/${TRACE_VERSION}/trace-event-listeners-${TRACE_VERSION}.jar
#COPY trace-event-listeners/pom.xml ${M2_HOME}/repository/com/malware/trace-event-listeners/${TRACE_VERSION}/trace-event-listeners-${TRACE_VERSION}.pom
#RUN touch ${M2_HOME}/repository/com/malware/trace-event-listeners/${TRACE_VERSION}/resolver-status.properties

# Add kie server state xml
COPY kie-server/mortgages-service.xml /opt/app/mortgages-service.xml

# Set correct file permissions on deployment and maven local cache
RUN chown -R jboss:jboss /opt/app
RUN chown -R jboss:jboss ${M2_HOME}
RUN chmod -R 777 ${M2_HOME}

USER jboss

ENTRYPOINT java -jar -Dspring.profiles.active=openshift -Dkie.maven.settings.custom=/home/jboss/.m2/settings.xml -Dorg.guvnor.m2repo.dir=/home/jboss/.m2/repository /opt/app/target/app.jar