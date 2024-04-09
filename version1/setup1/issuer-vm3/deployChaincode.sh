export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export PEER0_EPRODUCER_CA=${PWD}/../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export PEER0_BUYER_CA=${PWD}/../buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/ca.crt
export PEER0_HPRODUCER_CA=${PWD}/../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${PWD}/../../artifacts/private-data-collections/collection-config.json


export CHANNEL_NAME=mychannel

setGlobalsForPeer0issuer() {
    export CORE_PEER_LOCALMSPID="issuerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
}

setGlobalsForPeer1issuer() {
    export CORE_PEER_LOCALMSPID="issuerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:12051

}

# setGlobalsForPeer0eproducer() {
#     export CORE_PEER_LOCALMSPID="eproducerMSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
#     export CORE_PEER_MSPCONFIGPATH=${PWD}/../../artifacts/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-users/Admin@eproducer.GOnetwork.com/msp
#     export CORE_PEER_ADDRESS=localhost:9051

# }

# setGlobalsForPeer1eproducer() {
#     export CORE_PEER_LOCALMSPID="eproducerMSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
#     export CORE_PEER_MSPCONFIGPATH=${PWD}/../../artifacts/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-users/Admin@eproducer.GOnetwork.com/msp
#     export CORE_PEER_ADDRESS=localhost:10051

# }

presetup() {
    echo Vendoring Go dependencies ...
    pushd ./../../artifacts/Mychaincode
    GO111MODULE=on go mod vendor
    popd
    echo Finished vendoring Go dependencies
}
presetup

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH="./../../artifacts/Mychaincode"
CC_NAME="conversion" 

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0issuer
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on i-peer0.issuer ===================== "
}
packageChaincode

installChaincode() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on i-peer0.issuer ===================== "

}

installChaincode

queryInstalled() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed successful on i-peer0.issuer on channel ===================== "
}

queryInstalled

approveForissuer() {
    setGlobalsForPeer0issuer
    # set -x
    # Replace with current orderer VM IP address or change to localhost if deploying on single machine
    peer lifecycle chaincode approveformyorg -o localhost:9050 \
        --ordererTLSHostnameOverride orderer3.GOnetwork.com --tls \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --init-required --package-id ${PACKAGE_ID} \
        --sequence ${VERSION} --collections-config ${COLLECTION_CONFIGPATH}
    # set +x

    echo "===================== chaincode approved from issuer ===================== "

}

#queryInstalled
approveForissuer

checkCommitReadyness() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode checkcommitreadiness \
        --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --sequence ${VERSION} --output json --init-required \
        --collections-config ${COLLECTION_CONFIGPATH}
    echo "===================== checking commit readyness from issuer ===================== "
}

#checkCommitReadyness

commitChaincodeDefinition() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode commit -o localhost:9050 --ordererTLSHostnameOverride orderer3.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        --peerAddresses localhost:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
        --version ${VERSION} --sequence ${VERSION} --init-required \
        --collections-config ${COLLECTION_CONFIGPATH}
}

#commitChaincodeDefinition

queryCommitted() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}

}

#queryCommitted

chaincodeInvokeInit() {
    setGlobalsForPeer0issuer
    peer chaincode invoke -o localhost:9050 \
        --ordererTLSHostnameOverride orderer3.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        --peerAddresses localhost:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
        --isInit -c '{"Args":[]}'

}

 # --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \

#chaincodeInvokeInit

chaincodeInvoke() {
    setGlobalsForPeer0issuer

    peer chaincode invoke -o localhost:9050 \
        --ordererTLSHostnameOverride orderer3.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA   \
        --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        --peerAddresses localhost:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
        -c '{"function": "createElectricityGO","Args":[]}'

    ## Init ledger
    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.GOnetwork.com \
    #     --tls $CORE_PEER_TLS_ENABLED \
    #     --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME} \
    #     --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
    #     --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
    #     -c '{"function": "initLedger","Args":[]}'

}

#chaincodeInvoke

chaincodeQuery() {
    setGlobalsForPeer0issuer

    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "getcurrenteGOsList","Args":["eGO1", "eGO50"]}'
 
}

#chaincodeQuery