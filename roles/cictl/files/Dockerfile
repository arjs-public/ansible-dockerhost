FROM jenkins:latest

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Start editing
# Install package here for cache
USER root
# ADD keys/id_rsa.pub /root/.ssh/authorized_keys
# COPY etc/smtp.conf /etc/ssmtp/ssmtp.conf
# RUN apt-get update && apt-get install -y ssmtp && apt-get clean
RUN apt-get update && apt-get install -y build-essential tzdata && apt-get clean
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
COPY get-pip.py /root/get-pip.py
RUN python /root/get-pip.py
RUN pip install virtualenv
RUN pip list
USER jenkins
COPY keys/id_rsa /var/jenkins_home/.ssh/id_rsa
COPY keys/id_rsa.pub /var/jenkins_home/.ssh/id_rsa.pub
COPY plugins_standard.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
RUN git config --global user.email linux.worker@aol.com
RUN git config --global user.name "Linux Worker"
RUN git config --global push.default simple
