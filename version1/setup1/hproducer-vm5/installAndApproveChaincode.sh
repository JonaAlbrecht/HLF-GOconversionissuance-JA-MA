export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${PWD}/../../artifacts/private-data-collections/collection-config.json

export CHANNEL_NAME=mychannel

setGlobalsForPeer0hproducer() {
    export CORE_PEER_LOCALMSPID="hproducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/Admin@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}

setGlobalsForPeer1hproducer() {
    export CORE_PEER_LOCALMSPID="hproducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/Admin@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:10051

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
CC_SRC_PATH="./../../artifacts/Mychaincode"
CC_NAME="conversion"

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0hproducer
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on h-peer0.hproducer ===================== "
}
# packageChaincode

installChaincode() {
    setGlobalsForPeer0hproducer
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on h-peer0.hproducer ===================== "

}

# installChaincode

queryInstalled() {
    setGlobalsForPeer0hproducer
    peer lifecycle chaincode queryinstalled >&log.txt

    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed successful on h-peer0.hproducer on channel ===================== "
}

# queryInstalled

approveForhproducer() {
    setGlobalsForPeer0hproducer

    # If deploying on several VMs, replace localhost with your orderer's vm IP address
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer4.GOnetwork.com --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --version ${VERSION} --init-required --package-id ${PACKAGE_ID} \
        --sequence ${VERSION} --collections-config ${COLLECTION_CONFIGPATH}

    echo "===================== chaincode approved from hproducer ===================== "
}
# queryInstalled
# approveForeproducer

checkCommitReadyness() {

    setGlobalsForPeer0hproducer
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
        --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required \
        --collections-config ${COLLECTION_CONFIGPATH}
    echo "===================== checking commit readyness from eproducer ===================== "
}

# checkCommitReadyness
