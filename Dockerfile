FROM debian:stretch-slim

MAINTAINER Sebastiaan Van Hoecke

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y
RUN apt-get install nano cron sqlite3 net-tools nsis ssh xsltproc texlive-latex-extra curl redis-server openvas-scanner openvas-manager openvas-cli greenbone-security-assistant -y

EXPOSE 9390 80 443

ADD ["entrypoint.sh", "/root/"]
ADD ["run.sh", "/bin/run"]

ENTRYPOINT ["/root/entrypoint.sh"]
