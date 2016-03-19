FROM redis:latest

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Start editing
USER root
COPY etc/timezone /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
