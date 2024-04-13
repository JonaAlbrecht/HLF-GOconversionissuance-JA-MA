# For the eproducer organisation, no frontend application was created. 
# A number of different example operations from the issuer organisation's side are exemplified in this script. 
# Make sure that the network has been brought up successfully and the chaincode was installed and committed. 


export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${PWD}/../../artifacts/private-data-collections/collection-config.json
export CHANNEL_NAME=mychannel

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH="./../../artifacts/Mychaincode"
CC_NAME="conversion"

setGlobalsForPeer0hproducer() {
    export CORE_PEER_LOCALMSPID="hproducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser/hTrustedUser@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:13051
}


#To run any of the functions, uncomment the function invocation below (remove the hashtag, e.g. in front of ReadPubliceGO)
#and then execute the script from this working directory with ./issuerOperations.sh
# you could also past the environment variables into the terminal and then run the commands directly in the terminal



#ReadPubliceGO.
ReadPubliceGO() {
    start=$(date +%s%N)

    setGlobalsForPeer0hproducer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPubliceGO","Args":["eGO2"]}'
    
    end=$(date +%s%N)
    echo "ReadPubliceGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#ReadPubliceGO


#This function returns a list of electricity GOs by a range (here set from 1 to 50)
GetcurrenteGOsList() {
    start=$(date +%s%N)
    setGlobalsForPeer0hproducer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "GetcurrenteGOsList","Args":["eGO1", "eGO50"]}'
    end=$(date +%s%N)
    echo "GetcurrenteGOsList Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#GetcurrenteGOsList

ReadPrivatefromCollectioneGO() {
    setGlobalsForPeer0hproducer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPrivatefromCollectioneGO", "Args":["privateDetails-hGO", "eGO1"]}'
}

ReadPrivatefromCollectioneGO


IssuehGO() {
    
    setGlobalsForPeer0hproducer
    export TransferInput=$(echo -n "{\"EGOList\":\"eGO1+eGO2+eGO3+eGO4+eGO5\",\"Recipient\":\"hproducerMSP\",\"Neededamount\":200}" | base64 | tr -d \\n)
    peer chaincode invoke -o localhost:8050 \
        --ordererTLSHostnameOverride orderer2.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
        -c '{"function": "TransfereGO","Args":[]}' \
        --transient "{\"TransferInput\":\"$TransferInput\"}"

}

#TransferhGO



QueryPrivatehGOsbyAmountMWh() {
    start=$(date +%s%N)
    setGlobalsForPeer0hproducer
    export QueryInput=$(echo -n "{\"NeededAmount\":\"200\",\"Collection\":\"privateDetails-hGO\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "QueryPrivateeGOsbyAmountMWh", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    end=$(date +%s%N)
    echo "QueryPrivateeGOsbyAmountMWh Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#QueryPrivateeGOsbyAmountMWh

#With this function we transfer electricity GOs to the hproducer.
TransferhGO() {
    
    setGlobalsForPeer0hproducer
    export TransferInput=$(echo -n "{\"EGOList\":\"eGO1+eGO2+eGO3+eGO4+eGO5\",\"Recipient\":\"hproducerMSP\",\"Neededamount\":200}" | base64 | tr -d \\n)
    peer chaincode invoke -o localhost:8050 \
        --ordererTLSHostnameOverride orderer2.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
        -c '{"function": "TransfereGO","Args":[]}' \
        --transient "{\"TransferInput\":\"$TransferInput\"}"

}

#TransferhGO