FROM redis:latest
MAINTAINER alex rj s at aol com

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Start editing
USER root
COPY etc/timezone /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
