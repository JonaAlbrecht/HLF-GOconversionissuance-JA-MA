# For the issuer organisation, no frontend application was created. 
# A number of different example operations from the issuer organisation's side are exemplified in this script. 
# Make sure that the network has been brought up successfully and the chaincode was installed and committed. 


export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export PEER0_EPRODUCER_CA=${PWD}/../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export PEER0_BUYER_CA=${PWD}/../buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/ca.crt
export PEER0_HPRODUCER_CA=${PWD}/../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${PWD}/../../artifacts/private-data-collections/collection-config.json
export CHANNEL_NAME=mychannel

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH="./../../artifacts/Mychaincode"
CC_NAME="conversion"

setGlobalsForPeer0issuer() {
    export CORE_PEER_LOCALMSPID="issuerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
}


#To run any of the functions, uncomment the function invocation below (remove the hashtag, e.g. in front of ReadPubliceGO)
#and then execute the script from this working directory with ./issuerOperations.sh
# you could also past the environment variables into the terminal and then run the commands directly in the terminal

#Read Public eGO.
ReadPubliceGO() {
    start=$(date +%s%N)
    setGlobalsForPeer0issuer
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPubliceGO","Args":["eGO1"]}'
    end=$(date +%s%N)
    echo "GetcurrenteGOsList Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
    
}

#ReadPubliceGO


#This function returns a list of electricity GOs by a range (here set from 1 to 50)
GetcurrenteGOsList() {
    start=$(date +%s%N)
    setGlobalsForPeer0issuer
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "GetcurrenteGOsList","Args":["eGO1", "eGO50"]}'
    end=$(date +%s%N)
    echo "GetcurrenteGOsList Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

GetcurrenteGOsList

#This function should return permission denied. 
ReadPrivatefromCollectioneGO() {
    start=$(date +%s%N)
    setGlobalsForPeer0issuer
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPrivatefromCollectioneGO", "Args":["privateDetails-eGO", "eGO1"]}'
    end=$(date +%s%N)
    echo "ReadPrivatefromCollectioneGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#ReadPrivatefromCollectioneGO

ReadPublichGO() {
    start=$(date +%s%N)
    setGlobalsForPeer0issuer
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPublichGO", "Args":["hGO1"]}'
    end=$(date +%s%N)
    echo "ReadPrivatefromCollectioneGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#ReadPublichGO
