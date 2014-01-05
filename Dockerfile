FROM debian
MAINTAINER Tim Horton <hortont424@gmail.com>

RUN echo "deb http://ftp.debian.org/debian stable main" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y nginx supervisor

RUN mkdir -p /var/log/supervisor

ADD nginx.conf /etc/nginx/nginx.conf
ADD supervisord.conf /etc/supervisor/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n"]