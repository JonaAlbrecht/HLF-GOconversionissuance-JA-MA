export CORE_PEER_TLS_ENABLED=true
DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3
export ORDERER_CA=${DIRECTORY}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=${DIRECTORY}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${DIRECTORY}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${DIRECTORY}/../../artifacts/private-data-collections/collection-config.json


export CHANNEL_NAME=mychannel

setGlobalsForPeer0issuer() {
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
}

setGlobalsForPeer1issuer() {
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:12051

}

presetup() {
    echo Vendoring Go dependencies ...
    #bc it is in relationship to current working directory which is different when deploying the network-up script
    cd ${DIRECTORY}/../../artifacts/Mychaincode
    GO111MODULE=on go mod vendor
    cd ${DIRECTORY} 
    echo Finished vendoring Go dependencies
}
presetup

export CC_RUNTIME_LANGUAGE="golang"
export VERSION="1"
export CC_SRC_PATH="$DIRECTORY/../../artifacts/Mychaincode"
export CC_NAME="conversion" 

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0issuer
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on i-peer0.issuer ===================== "
}
packageChaincode

echo "installing Chaincode on issuer peer0... This may take a few minutes."

installChaincode() {
    setGlobalsForPeer0issuer
    cd ${DIRECTORY} && peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on i-peer0.issuer ===================== "

}

installChaincode

queryInstalled() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode queryinstalled >log.txt &
}
queryInstalled 

approveForissuer() {
    setGlobalsForPeer0issuer
    # Replace with current orderer VM IP address or change to localhost if deploying on single machine
    cd ${DIRECTORY} && peer lifecycle chaincode approveformyorg -o localhost:9050 \
        --ordererTLSHostnameOverride orderer3.GOnetwork.com --tls \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --init-required --package-id "fec8cde5ddc8d9143e8c619f91c9d8f5337eae999667e0d678819f5bc26f2519" \
        --sequence ${VERSION} --collections-config $COLLECTION_CONFIGPATH

    echo "===================== chaincode approved from issuer ===================== "

}

#queryInstalled
approveForissuer

checkCommitReadyness() {
    setGlobalsForPeer0issuer
    cd ${DIRECTORY} && peer lifecycle chaincode checkcommitreadiness \
        --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --sequence ${VERSION} --output json --init-required \
        --collections-config $COLLECTION_CONFIGPATH
    echo "===================== checking commit readyness from issuer ===================== "
}

checkCommitReadyness