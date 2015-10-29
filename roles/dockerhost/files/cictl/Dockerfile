FROM jenkins:latest
MAINTAINER alex rj s at aol com

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Start editing
# Install package here for cache
USER root
# ADD keys/id_rsa.pub /root/.ssh/authorized_keys
# COPY etc/smtp.conf /etc/ssmtp/ssmtp.conf
# RUN apt-get update && apt-get install -y ssmtp && apt-get clean
COPY etc/timezone /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
