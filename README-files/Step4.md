# 6. Installing the metering devices

At this stage, we have to bring up the Metering device docker containers for the eproducer and hproducer organisation.
The Metering devices are simulated as their own docker containers. To this end, a custom docker image was built, using the docker fabric-tools image as its base.

The Smart Meter docker containers uses a cron job to periodically (every minute) execute a bash-script that invokes the chaincode and randomizes a production output around the audited production device information specified in the certificate issued by the Issuing Body.

## Installing the Electricity Smart Meter

cd into the SmartMeter-config folder:

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/eproducer-vm2/SmartMeter-config`

Sometimes, bash scripts have the wrong execute permissions, so to be safe run:

`sudo chmod 777 -R *`

Build the custom image

`docker build -t smartmeter .`

Bring up a container using the custom image with docker-compose using the -daemon flag to make it a background process

`docker-compose up -d`

## Installing the Hydrogen Smart Meter

cd into the OutputMeter-config folder:

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/hproducer-vm5/OutputMeter-config`

Sometimes, bash scripts have the wrong execute permissions, so to be safe run:

`sudo chmod 777 -R *`

build the custom image for the OutputMeter using

`docker build -t outputmeter .`
