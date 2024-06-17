#this is a convenience script for bringing the network down. 

RED="\e[31m"
ENDCOLOR="\e[0m"

# setting read, write, execute permissions on all files in the repository such that they can all be deleted

echo -e "${RED}Stopping docker containers${ENDCOLOR}"
sleep 1
docker stop $(docker ps -a -q)

echo -e "${RED}Removing docker containers${ENDCOLOR}"
sleep 1
docker remove $(docker ps -a -q)

echo -e "${RED}Removing relevant images${ENDCOLOR}"
sleep 1
docker rmi $(docker images | grep 'dev')
docker rmi $(docker images | grep 'smartmeter')
docker rmi $(docker images | grep 'outputmeter')

echo
echo -e "${RED}Removing crypto-config folders${ENDCOLOR}"
sudo chmod 777 -R *
rm -rf ./orderer-vm4/crypto-config
rm -rf ./issuer-vm3/crypto-config
rm -rf ./eproducer-vm2/crypto-config
rm -rf ./buyer-vm1/crypto-config
rm -rf ./hproducer-vm5/crypto-config

echo 
echo -e "${RED}Removing fabric-ca folders${ENDCOLOR}"
rm -rf ./issuer-vm3/create-cryptomaterial-issuer/fabric-ca
rm -rf ./orderer-vm4/create-cryptomaterial-orderer/fabric-ca
rm -rf ./buyer-vm1/create-cryptomaterial-buyer/fabric-ca
rm -rf ./eproducer-vm2/create-cryptomaterial-eproducer/fabric-ca
rm -rf ./hproducer-vm5/create-cryptomaterial-hproducer/fabric-ca

echo
echo -e "${RED}Removing chaincode packaged tar files${ENDCOLOR}"
rm ./buyer-vm1/conversion.tar.gz
rm ./eproducer-vm2/conversion.tar.gz
rm ./issuer-vm3/conversion.tar.gz
rm ./hproducer-vm5/conversion.tar.gz

echo
echo -e "${RED}Removing mychannel.block files${ENDCOLOR}"
rm ./buyer-vm1/channel-artifacts/mychannel.block
rm ./eproducer-vm2/channel-artifacts/mychannel.block
rm ./issuer-vm3/channel-artifacts/mychannel.block
rm ./hproducer-vm5/channel-artifacts/mychannel.block

echo -e "${RED}Removing channel artifacts${ENDCOLOR}"
rm ./../artifacts/channel/mychannel.tx
rm ./../artifacts/channel/genesis.block
rm ./../artifacts/channel/buyerMSPanchors.tx
rm ./../artifacts/channel/eproducerMSPanchors.tx
rm ./../artifacts/channel/hproducerMSPanchors.tx
rm ./../artifacts/channel/issuerMSPanchors.tx

echo -e "${RED}Removing chaincode vendoring${ENDCOLOR}"
rm -rf ./../artifacts/Mychaincode/vendor

# Uncomment these lines if doing caliper test run
echo -e "${RED}Removing crypto config in testing folder"
cd ${PWD}/../../ && sudo chmod 777 -R * && rm -rf ./testing/crypto-config
