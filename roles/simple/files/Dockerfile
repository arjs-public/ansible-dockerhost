FROM ubuntu:latest

#ADD keys/ssh_config /root/.ssh/ssh_config
ADD keys/id_rsa.pub /root/.ssh/authorized_keys
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server tzdata && apt-get clean && /etc/init.d/ssh start && /etc/init.d/ssh stop

COPY etc/timezone /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

EXPOSE 80
EXPOSE 443
EXPOSE 8080
EXPOSE 8443
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
