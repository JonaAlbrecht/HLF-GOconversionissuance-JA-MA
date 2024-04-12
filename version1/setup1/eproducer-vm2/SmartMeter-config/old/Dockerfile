FROM hyperledger/fabric-tools
RUN apt-get update && apt-get install -y cron
COPY execute.sh /opt
COPY crontab.txt /opt
RUN chmod 0644 /opt/execute.sh
RUN crontab /opt/crontab.txt
CMD ["cron", "-f"]