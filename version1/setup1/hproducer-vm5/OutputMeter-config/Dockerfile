FROM hyperledger/fabric-tools
RUN apt-get update && apt-get install -y cron
COPY execute-hproducer.sh /opt
COPY crontab-hproducer.txt /opt
RUN crontab /opt/crontab-hproducer.txt
CMD ["cron", "-f"]