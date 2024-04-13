 
# A number of different example operations from the issuer organisation's side are exemplified in this script. 
# Make sure that the network has been brought up successfully and the chaincode was installed and committed. 


export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_BUYER_CA=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.eproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${PWD}/../../artifacts/private-data-collections/collection-config.json
export CHANNEL_NAME=mychannel

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH="./../../artifacts/Mychaincode"
CC_NAME="conversion"

setGlobalsForPeer0buyer() {
    export CORE_PEER_LOCALMSPID="buyerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/b-User1@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}


#To run any of the functions, uncomment the function invocation below (remove the hashtag, e.g. in front of ReadPubliceGO)
#and then execute the script from this working directory with ./issuerOperations.sh
# you could also past the environment variables into the terminal and then run the commands directly in the terminal



#ReadPubliceGO.
ReadPubliceGO() {
    start=$(date +%s%N)

    setGlobalsForPeer0buyer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPubliceGO","Args":["eGO2"]}'
    
    end=$(date +%s%N)
    echo "ReadPubliceGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#ReadPubliceGO


#This function returns a list of electricity GOs by a range (here set from 1 to 50)
GetcurrenteGOsList() {
    start=$(date +%s%N)
    setGlobalsForPeer0buyer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "GetcurrenteGOsList","Args":["eGO1", "eGO50"]}'
    end=$(date +%s%N)
    echo "GetcurrenteGOsList Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#GetcurrenteGOsList

ReadPrivatefromCollectioneGO() {
    setGlobalsForPeer0buyer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPrivatefromCollectioneGO", "Args":["privateDetails-buyer", "eGO1"]}'
}

#ReadPrivatefromCollectioneGO

QueryPrivateeGOsbyAmountMWh() {
    start=$(date +%s%N)
    setGlobalsForPeer0eproducer
    export QueryInput=$(echo -n "{\"NeededAmount\":\"200\",\"Collection\":\"privateDetails-eGO\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "QueryPrivateeGOsbyAmountMWh", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    end=$(date +%s%N)
    echo "QueryPrivateeGOsbyAmountMWh Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

#QueryPrivateeGOsbyAmountMWh

#With this function we transfer electricity GOs to the hproducer.
TransfereGO() {
    
    setGlobalsForPeer0buyer
    export TransferInput=$(echo -n "{\"EGOList\":\"eGO1+eGO10+eGO11+eGO12+eGO13\",\"Recipient\":\"hproducerMSP\",\"Neededamount\":200}" | base64 | tr -d \\n)
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        -c '{"function": "TransfereGO","Args":[]}' \
        --transient "{\"TransferInput\":\"$TransferInput\"}"

}

#TransfereGO