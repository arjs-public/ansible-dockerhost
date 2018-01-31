FROM ubuntu:latest

#ADD keys/ssh_config /root/.ssh/ssh_config
ADD keys/id_rsa.pub /root/.ssh/authorized_keys
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server python2.7 tzdata && /etc/init.d/ssh start && /etc/init.d/ssh stop
RUN DEBIAN_FRONTEND=noninteractive apt-get remove -y python3 && apt-get clean && apt-get clean
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1

# COPY etc/timezone /etc/timezone
# RUN cat /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

EXPOSE 80
EXPOSE 443
# EXPOSE 8080
# EXPOSE 8443
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
