export CORE_PEER_TLS_ENABLED=true
DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/eproducer-vm2
export ORDERER_CA=${DIRECTORY}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_EPRODUCER_CA=${DIRECTORY}/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${DIRECTORY}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${DIRECTORY}/../../artifacts/private-data-collections/collection-config.json

export CHANNEL_NAME=mychannel

setGlobalsForPeer0eproducer() {
    export CORE_PEER_LOCALMSPID=eproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/eproducer.GOnetwork.com/Admin/Admin@eproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}

setGlobalsForPeer1eproducer() {
    export CORE_PEER_LOCALMSPID=eproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/eproducer.GOnetwork.com/Admin/Admin@eproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:10051

}

#presetup not necessary if deploying on single machine. GO dependencies are already vendored by running deployChaincode script
#if deploying on multi-host uncomment the presetup invocation below
presetup() {
    echo Vendoring Go dependencies ...
    pushd ./../../artifacts/Mychaincode
    GO111MODULE=on go mod vendor
    popd
    echo Finished vendoring Go dependencies
}
# presetup

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH="${DIRECTORY}/../../artifacts/Mychaincode"
CC_NAME="conversion"

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0eproducer
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on e-peer0.eproducer ===================== "
}
packageChaincode

echo "Installing Chaincode on eproducer peer0... This may take a few minutes"

installChaincode() {
    setGlobalsForPeer0eproducer
    cd ${DIRECTORY} && peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on e-peer0.eproducer ===================== "

}

installChaincode

queryInstalled() {
    setGlobalsForPeer0eproducer
    peer lifecycle chaincode queryinstalled >log.txt &
}

queryInstalled

approveForeproducer() {
    setGlobalsForPeer0eproducer

    # Replace localhost with your orderer's vm IP address
    cd ${DIRECTORY} && peer lifecycle chaincode approveformyorg -o localhost:8050 \
        --ordererTLSHostnameOverride orderer2.GOnetwork.com --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --version ${VERSION} --init-required --package-id "fec8cde5ddc8d9143e8c619f91c9d8f5337eae999667e0d678819f5bc26f2519./" \
        --sequence ${VERSION} --collections-config ${COLLECTION_CONFIGPATH}

    echo "===================== chaincode approved from eproducer ===================== "
}
# queryInstalled
approveForeproducer

checkCommitReadyness() {

    setGlobalsForPeer0eproducer
    cd ${DIRECTORY} && peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
        --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required \
        --collections-config ${COLLECTION_CONFIGPATH}
    echo "===================== checking commit readyness from eproducer ===================== "
}

checkCommitReadyness
