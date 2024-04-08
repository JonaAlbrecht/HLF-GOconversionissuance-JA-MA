FROM ubuntu:latest
RUN apt-get update && apt-get install -y cron curl
COPY work.sh /opt
COPY crontab.txt /opt
RUN crontab /opt/crontab.txt
CMD ["cron", "-f"]
RUN curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh
RUN ./install-fabric.sh binary