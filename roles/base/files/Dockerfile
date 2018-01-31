FROM ubuntu

ADD keys/id_rsa.pub /root/.ssh/authorized_keys
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server tzdata && apt-get clean && /etc/init.d/ssh start && /etc/init.d/ssh stop
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
