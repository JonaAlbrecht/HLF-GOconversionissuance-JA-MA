FROM hyperledger/fabric-tools:latest
RUN apt-get update && apt-get install -y cron nano
RUN mkdir -p /custom/bin
COPY execute-hproducer.sh /custom/bin/execute-hproducer.sh
RUN chmod +x /custom/bin/execute-hproducer.sh
COPY ./crontab /etc/cron.d/crontab
RUN chmod 0644 /etc/cron.d/crontab
RUN crontab /etc/cron.d/crontab
RUN touch /var/log/cron.log
CMD cron && tail -f /var/log/cron.log