FROM tomcat:8.5.47-jdk8-adoptopenjdk-openj9
MAINTAINER Damian McDonald <damian.mcdonald1979@gmail.com>

# Copy assets
COPY --chown=root:root build/context.xml /usr/local/tomcat/webapps/host-manager/META-INF/
COPY --chown=root:root build/context.xml /usr/local/tomcat/webapps/manager/META-INF/
COPY --chown=root:root build/sample-app-ci-cd.war /usr/local/tomcat/webapps/
COPY --chown=root:root build/sample-app-svn-git.war /usr/local/tomcat/webapps/
COPY --chown=root:root build/server.xml /usr/local/tomcat/conf/
COPY --chown=root:root build/tomcat-users.xml /usr/local/tomcat/conf/
