export CORE_PEER_TLS_ENABLED=true
DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/hproducer-vm5
export ORDERER_CA=${DIRECTORY}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=${DIRECTORY}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${DIRECTORY}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${DIRECTORY}/../../artifacts/private-data-collections/collection-config.json

export CHANNEL_NAME=mychannel

setGlobalsForPeer0hproducer() {
    export CORE_PEER_LOCALMSPID=hproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/Admin/oAdmin@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:13051

}

setGlobalsForPeer1hproducer() {
    export CORE_PEER_LOCALMSPID=hproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/Admin/oAdmin@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:14051

}

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
    setGlobalsForPeer0hproducer
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on h-peer0.hproducer ===================== "
}
packageChaincode

echo "installing Chaincode on hproducer peer0... This may take a few minutes."

installChaincode() {
    setGlobalsForPeer0hproducer
    cd ${DIRECTORY} && peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on h-peer0.hproducer ===================== "

}

installChaincode

queryInstalled() {
    setGlobalsForPeer0hproducer
    cd ${DIRECTORY} && peer lifecycle chaincode queryinstalled >log.txt &
}

queryInstalled

approveForhproducer() {
    setGlobalsForPeer0hproducer

    # If deploying on several VMs, replace localhost with your orderer's vm IP address
    cd ${DIRECTORY} && peer lifecycle chaincode approveformyorg -o localhost:10050 \
        --ordererTLSHostnameOverride orderer4.GOnetwork.com --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --version ${VERSION} --init-required --package-id "fec8cde5ddc8d9143e8c619f91c9d8f5337eae999667e0d678819f5bc26f2519" \
        --sequence ${VERSION} --collections-config ${COLLECTION_CONFIGPATH}

    echo "===================== chaincode approved from hproducer ===================== "
}
# queryInstalled
approveForhproducer

checkCommitReadyness() {

    setGlobalsForPeer0hproducer
    cd ${DIRECTORY} && peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
        --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required \
        --collections-config ${COLLECTION_CONFIGPATH}
    echo "===================== checking commit readyness from hproducer ===================== "
}

checkCommitReadyness
