FROM python:2.7

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Start editing
USER root
COPY etc/timezone /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /usr/src/app
EXPOSE 5000

ENTRYPOINT ["python"]
CMD ["app.py"]
