#!/bin/bash

#this is a convenience script for bringing up the network quickly.

export DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1

sudo chmod 777 -R *

export CHANNEL_NAME=mychannel28


GREEN="\e[32m"
ENDCOLOR="\e[0m"

echo -e "${GREEN}Creating the orderer docker containers ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/orderer-vm4 && docker-compose up -d

echo -e "${GREEN}Creating the channel artefacts ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/../artifacts/channel
sudo chmod +x ./create-artifacts.sh
sh ./create-artifacts.sh $CHANNEL_NAME

echo -e "${GREEN}Creating the Smart Meter docker image ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3/SmartMeter-config && docker build -t smartmeter .
echo
echo -e "${GREEN}Creating the Output Meter docker image ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3/OutputMeter-config && docker build -t outputmeter .
echo



echo -e "${GREEN}Creating the peer, couchDB and client docker container for buyer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/buyer-vm1 && docker-compose up -d
echo
echo -e "${GREEN}Creating the peer, couchDB and Smart Meter docker container for hydrogen producer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/eproducer-vm2 && docker-compose up -d
echo
echo -e "${GREEN}Creating the peer and couchDB docker container for issuer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/issuer-vm3 && docker-compose up -d
echo
echo -e "${GREEN}Creating the peer, couchDB and Output Meter docker container for hydrogen producer org ${ENDCOLOR}"
sleep 1
cd ${DIRECTORY}/hproducer-vm5 && docker-compose up -d
echo

echo
echo -e "${GREEN}Creating the channel: ${ENDCOLOR}"
sleep 1
echo
echo -e "${GREEN}Creating the channel from issuer org: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/issuer-vm3
sudo chmod +x ./createChannel.sh
sh ./createChannel.sh $CHANNEL_NAME
echo
echo -e "${GREEN}Buyer org joining the channel: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/buyer-vm1
sudo chmod +x ./joinChannel.sh
sh ./joinChannel.sh $CHANNEL_NAME
echo
echo -e "${GREEN}Eproducer org joining the channel: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/eproducer-vm2
sudo chmod +x ./joinChannel.sh
sh ./joinChannel.sh $CHANNEL_NAME
echo
echo -e "${GREEN}Hproducer org joining the channel: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/hproducer-vm5
sudo chmod +x ./joinChannel.sh
sh ./joinChannel.sh $CHANNEL_NAME

echo -e "${GREEN}Setting anchor peer for buyer: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/../artifacts/channel/buyerAnchor
sudo chmod +x ./AnchorUpdatebuyer.sh
sh ./AnchorUpdatebuyer.sh $CHANNEL_NAME

echo -e "${GREEN}Setting anchor peer for eproducer: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/../artifacts/channel/eproducerAnchor
sudo chmod +x ./AnchorUpdateeproducer.sh
sh ./AnchorUpdateeproducer.sh $CHANNEL_NAME

echo -e "${GREEN}Setting anchor peer for hproducer: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/../artifacts/channel/hproducerAnchor
sudo chmod +x ./AnchorUpdatehproducer.sh
sh ./AnchorUpdatehproducer.sh $CHANNEL_NAME

echo -e "${GREEN}Setting anchor peer for issuer: ${ENDCOLOR}"
sleep 1

cd ${DIRECTORY}/../artifacts/channel/issuerAnchor
sudo chmod +x ./AnchorUpdateissuer.sh
sh ./AnchorUpdateissuer.sh $CHANNEL_NAME

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
