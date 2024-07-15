#!/bin/bash

#this is a convenience script for bringing up the network quickly.

export DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1

sudo chmod 777 -R *

export CHANNEL_NAME=mychannel28


GREEN="\e[32m"
ENDCOLOR="\e[0m"
echo
echo -e "${GREEN}Bringing up the fabric-ca docker containers ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3/create-cryptomaterial-issuer && docker-compose up -d
cd ${DIRECTORY}/orderer-vm4/create-cryptomaterial-orderer && docker-compose up -d
cd ${DIRECTORY}/buyer-vm1/create-cryptomaterial-buyer && docker-compose up -d
cd ${DIRECTORY}/eproducer-vm2/create-cryptomaterial-eproducer && docker-compose up -d
cd ${DIRECTORY}/hproducer-vm5/create-cryptomaterial-hproducer && docker-compose up -d
echo
echo -e "${GREEN}Finished creating certificate authorities ${ENDCOLOR}"
sleep 1
echo
echo -e "${GREEN}Creating the cryptomaterial for buyer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/buyer-vm1/create-cryptomaterial-buyer
sudo chmod +x ./buyer-org-certificates.sh
sh ./buyer-org-certificates.sh
echo
echo -e "${GREEN}Creating the cryptomaterial for eproducer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/eproducer-vm2/create-cryptomaterial-eproducer
sudo chmod +x ./create-cryptomaterial-eproducer.sh
sh ./create-cryptomaterial-eproducer.sh
echo
echo -e "${GREEN}Creating the cryptomaterial for hproducer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/hproducer-vm5/create-cryptomaterial-hproducer
sudo chmod +x ./create-cryptomaterial-hproducer.sh
sh ./create-cryptomaterial-hproducer.sh
echo
echo -e "${GREEN}Creating the cryptomaterial for orderer ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/orderer-vm4/create-cryptomaterial-orderer
sudo chmod +x ./orderer-org-certificates.sh
sh ./orderer-org-certificates.sh
echo
echo -e "${GREEN}Creating the cryptomaterial for issuer, this includes the Smart Meter and Output Meter${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3/create-cryptomaterial-issuer
sudo chmod +x ./issuer-org-certificates.sh
sh ./issuer-org-certificates.sh