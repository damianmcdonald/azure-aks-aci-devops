FROM jenkins/jenkins:lts
MAINTAINER Damian McDonald <damian.mcdonald1979@gmail.com>

# Copy assets
COPY --chown=jenkins:jenkins build/java/ /opt/java/
COPY --chown=jenkins:jenkins build/maven/ /opt/maven/
COPY --chown=jenkins:jenkins build/jenkins.sh /usr/local/bin/
COPY --chown=jenkins:jenkins build/.gitconfig /var/jenkins_home/
