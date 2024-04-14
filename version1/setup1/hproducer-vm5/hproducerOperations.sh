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


ReadPrivatefromCollectioneGO() {
    start=$(date +%s%N)
    setGlobalsForPeer0hproducer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPrivatefromCollectioneGO", "Args":["privateDetails-hGO", "eGO1"]}'
    end=$(date +%s%N)
    echo "ReadPrivatefromCollectioneGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#ReadPrivatefromCollectioneGO

#Query the Hydrogen Backlog created by the OutputMeter 
QueryHydrogenBacklog() {
    start=$(date +%s%N)

    setGlobalsForPeer0hproducer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "QueryHydrogenBacklog","Args":[]}'
    
    end=$(date +%s%N)
    echo "QueryHydrogenBacklog Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

QueryHydrogenBacklog


#This function is necessary prior to Backlog issuing. Needed Amount should correspond AmountMWh output from Query Hydrogen Backlog function. 
QueryPrivateeGOsbyAmountMWh() {
    start=$(date +%s%N)
    setGlobalsForPeer0eproducer
    export QueryInput=$(echo -n "{\"NeededAmount\":\"100\",\"Collection\":\"privateDetails-eGO\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "QueryPrivateeGOsbyAmountMWh", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    end=$(date +%s%N)
    echo "QueryPrivateeGOsbyAmountMWh Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#QueryPrivateeGOsbyAmountMWh


IssuehGO() {
    start=$(date +%s%N)
    setGlobalsForPeer0hproducer
    export TransferInput=$(echo -n "{\"EGOList\":\"eGO1+eGO2+eGO3+eGO4+eGO5\",\"Recipient\":\"hproducerMSP\",\"Neededamount\":200}" | base64 | tr -d \\n)
    peer chaincode invoke -o localhost:8050 \
        --ordererTLSHostnameOverride orderer2.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
        -c '{"function": "TransfereGO","Args":[]}' \
        --transient "{\"TransferInput\":\"$TransferInput\"}"
    end=$(date +%s%N)
    echo "IssuehGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}
#IssuehGO



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