FROM ubuntu:latest

#ADD keys/ssh_config /root/.ssh/ssh_config
ADD keys/id_rsa.pub /root/.ssh/authorized_keys
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server python2.7 && /etc/init.d/ssh start && /etc/init.d/ssh stop
RUN DEBIAN_FRONTEND=noninteractive apt-get remove -y python3 && apt-get clean && apt-get clean
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1

# COPY etc/timezone /etc/timezone
# RUN dpkg-reconfigure -f noninteractive tzdata
RUN test -f /usr/bin/timedatectl && /usr/bin/timedatectl set-timezone "Europe/Berlin" || true
RUN which timedatectl && /usr/bin/timedatectl || true

EXPOSE 80
EXPOSE 443
# EXPOSE 8080
# EXPOSE 8443
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
