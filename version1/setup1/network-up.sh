#!/bin/bash

#this is a convenience script for bringing up the network quickly.

export DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1

sudo chmod 777 -R *

GREEN="\e[32m"
ENDCOLOR="\e[0m"

echo -e "${GREEN}Bringing up the fabric-ca docker containers ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3/create-cryptomaterial-issuer && docker-compose up -d
cd ${DIRECTORY}/orderer-vm4/create-cryptomaterial-orderer && docker-compose up -d

echo -e "${GREEN}Finished creating certificate authorities ${ENDCOLOR}"
sleep 1

echo -e "${GREEN}Creating the cryptomaterial for issuer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3/create-cryptomaterial-issuer
sudo chmod +x ./issuer-org-certificates.sh
sh ./issuer-org-certificates.sh

echo -e "${GREEN}Creating the cryptomaterial for buyer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/buyer-vm1/create-cryptomaterial-buyer
sudo chmod +x ./buyer-org-certificates.sh
sh ./buyer-org-certificates.sh

echo -e "${GREEN}Creating the cryptomaterial for eproducer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/eproducer-vm2/create-cryptomaterial-eproducer
sudo chmod +x ./create-cryptomaterial-eproducer.sh
sh ./create-cryptomaterial-eproducer.sh

echo -e "${GREEN}Creating the cryptomaterial for hproducer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/hproducer-vm5/create-cryptomaterial-hproducer
sudo chmod +x ./create-cryptomaterial-hproducer.sh
sh ./create-cryptomaterial-hproducer.sh

echo -e "${GREEN}Creating the cryptomaterial for orderer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/orderer-vm4/create-cryptomaterial-orderer
sudo chmod +x ./orderer-org-certificates.sh
sh ./orderer-org-certificates.sh

echo -e "${GREEN}Creating the channel artefacts ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/../artifacts/channel
sudo chmod +x ./create-artifacts.sh
sh ./create-artifacts.sh

echo -e "${GREEN}Creating the Smart Meter docker image ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/eproducer-vm2/SmartMeter-config && docker build -t smartmeter .

echo -e "${GREEN}Creating the Output Meter docker image ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/hproducer-vm5/OutputMeter-config && docker build -t outputmeter .

echo -e "${GREEN}Creating the peer, couchDB and client docker container for buyer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/buyer-vm1 && docker-compose up -d

echo -e "${GREEN}Creating the peer, couchDB and Smart Meter docker container for hydrogen producer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/eproducer-vm2 && docker-compose up -d

echo -e "${GREEN}Creating the peer and couchDB docker container for issuer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/issuer-vm3 && docker-compose up -d

echo -e "${GREEN}Creating the peer, couchDB and Output Meter docker container for hydrogen producer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/hproducer-vm5 && docker-compose up -d

echo -e "${GREEN}Creating the orderer docker containers ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/orderer-vm4 && docker-compose up -d

echo -e "${GREEN}Creating the channel: ${ENDCOLOR}"
sleep 1

echo -e "${GREEN}Creating the channel from issuer org: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3
sudo chmod +x ./createChannel.sh
sh ./createChannel.sh

echo -e "${GREEN}Buyer org joining the channel: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/buyer-vm1
sudo chmod +x ./joinChannel.sh
sh ./joinChannel.sh

echo -e "${GREEN}Eproducer org joining the channel: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/eproducer-vm2
sudo chmod +x ./joinChannel.sh
sh ./joinChannel.sh

echo -e "${GREEN}Hproducer org joining the channel: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/hproducer-vm5
sudo chmod +x ./joinChannel.sh
sh ./joinChannel.sh

#echo -e "${GREEN}Deploying the chaincode from issuer org: ${ENDCOLOR}"
#sleep 1

#cd ${DIRECTORY}/issuer-vm3
#sudo chmod +x ./deployChaincode.sh
#sh ./deployChaincode.sh

#echo -e "${GREEN}Installing and approving chaincode from buyer org: ${ENDCOLOR}"
#sleep 1

#cd ${DIRECTORY}/buyer-vm1
#sudo chmod +x ./installAndApproveChaincode.sh
#sh ./installAndApproveChaincode.sh

#echo -e "${GREEN}Installing and approving chaincode from eproducer org: ${ENDCOLOR}"
#sleep 1

#cd ${DIRECTORY}/eproducer-vm2
#sudo chmod +x ./installAndApproveChaincode.sh
#sh ./installAndApproveChaincode.sh

#echo -e "${GREEN}Installing and approving chaincode from hproducer org: ${ENDCOLOR}"
#sleep 1

#cd ${DIRECTORY}/hproducer-vm5
#sudo chmod +x ./installAndApproveChaincode.sh
#sh ./installAndApproveChaincode.sh

#echo -e "${GREEN}Committing and invoking the chaincode from issuer org: ${ENDCOLOR}"
#sleep 1

#cd ${DIRECTORY}/issuer-vm3
#sudo chmod +x ./commitChaincode.sh
#sh ./commitChaincode.sh