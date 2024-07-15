#this is a convenience script for bringing the network down. 

RED="\e[31m"
ENDCOLOR="\e[0m"

# setting read, write, execute permissions on all files in the repository such that they can all be deleted

export CHANNEL_NAME=mychannel26

export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/keystore/05e0a0e316e27446af30987043eedc588690782b53c650b750de9cc7e2437bf1_sk

setGlobalsOrderer1() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
    
}


setGlobalsOrderer2() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
}

setGlobalsOrderer3() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
}

setGlobalsOrderer4() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
}

removeforOrderer1() {
    setGlobalsOrderer1
    osnadmin channel remove --channelID $CHANNEL_NAME -o localhost:7053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
}

removeforOrderer2() {
    setGlobalsOrderer2
    osnadmin channel remove --channelID $CHANNEL_NAME -o localhost:8053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
}

removeforOrderer3() {
    setGlobalsOrderer3
    osnadmin channel remove --channelID $CHANNEL_NAME -o localhost:9053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
}

removeforOrderer4() {
    setGlobalsOrderer4
    osnadmin channel remove --channelID $CHANNEL_NAME -o localhost:10053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
}

removeforOrderer1
removeforOrderer2
removeforOrderer3
removeforOrderer4

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
rm ./buyer-vm1/mychannel_oldest.block
rm ./eproducer-vm2/mychannel_oldest.block
rm ./issuer-vm3/mychannel_oldest.block
rm ./hproducer-vm5/mychannel_oldest.block

echo -e "${RED}Removing channel artifacts${ENDCOLOR}"
rm ./../artifacts/channel/$CHANNEL_NAME.tx
rm ./../artifacts/channel/$CHANNEL_NAME.block

rm ./../artifacts/channel/buyerAnchor/buyerMSPanchors.tx
rm ./../artifacts/channel/buyerAnchor/buyerMSPconfig.json
rm ./../artifacts/channel/buyerAnchor/buyerMSPmodified_config.json
rm ./../artifacts/channel/buyerAnchor/config_block.json
rm ./../artifacts/channel/buyerAnchor/config_block.pb
rm ./../artifacts/channel/buyerAnchor/config_update_in_envelope.json
rm ./../artifacts/channel/buyerAnchor/config_update.json
rm ./../artifacts/channel/buyerAnchor/config_update.pb
rm ./../artifacts/channel/buyerAnchor/modified_config.pb
rm ./../artifacts/channel/buyerAnchor/original_config.pb

rm ./../artifacts/channel/eproducerAnchor/eproducerMSPanchors.tx
rm ./../artifacts/channel/eproducerAnchor/eproducerMSPconfig.json
rm ./../artifacts/channel/eproducerAnchor/eproducerMSPmodified_config.json
rm ./../artifacts/channel/eproducerAnchor/config_block.json
rm ./../artifacts/channel/eproducerAnchor/config_block.pb
rm ./../artifacts/channel/eproducerAnchor/config_update_in_envelope.json
rm ./../artifacts/channel/eproducerAnchor/config_update.json
rm ./../artifacts/channel/eproducerAnchor/config_update.pb
rm ./../artifacts/channel/eproducerAnchor/modified_config.pb
rm ./../artifacts/channel/eproducerAnchor/original_config.pb

rm ./../artifacts/channel/hproducerAnchor/hproducerMSPanchors.tx
rm ./../artifacts/channel/hproducerAnchor/hproducerMSPconfig.json
rm ./../artifacts/channel/hproducerAnchor/hproducerMSPmodified_config.json
rm ./../artifacts/channel/hproducerAnchor/config_block.json
rm ./../artifacts/channel/hproducerAnchor/config_block.pb
rm ./../artifacts/channel/hproducerAnchor/config_update_in_envelope.json
rm ./../artifacts/channel/hproducerAnchor/config_update.json
rm ./../artifacts/channel/hproducerAnchor/config_update.pb
rm ./../artifacts/channel/hproducerAnchor/modified_config.pb
rm ./../artifacts/channel/hproducerAnchor/original_config.pb

rm ./../artifacts/channel/issuerAnchor/issuerMSPanchors.tx
rm ./../artifacts/channel/issuerAnchor/issuerMSPconfig.json
rm ./../artifacts/channel/issuerAnchor/issuerMSPmodified_config.json
rm ./../artifacts/channel/issuerAnchor/config_block.json
rm ./../artifacts/channel/issuerAnchor/config_block.pb
rm ./../artifacts/channel/issuerAnchor/config_update_in_envelope.json
rm ./../artifacts/channel/issuerAnchor/config_update.json
rm ./../artifacts/channel/issuerAnchor/config_update.pb
rm ./../artifacts/channel/issuerAnchor/modified_config.pb
rm ./../artifacts/channel/issuerAnchor/original_config.pb

echo -e "${RED}Removing chaincode vendoring${ENDCOLOR}"
rm -rf ./../artifacts/Mychaincode/vendor

# Uncomment these lines if doing caliper test run
echo -e "${RED}Removing crypto config in testing folder"
cd ${PWD}/../../ && sudo chmod 777 -R * && rm -rf ./testing/crypto-config

