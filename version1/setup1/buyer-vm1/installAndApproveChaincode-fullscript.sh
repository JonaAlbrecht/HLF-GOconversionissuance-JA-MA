export CORE_PEER_TLS_ENABLED=true
DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/buyer-vm1
export ORDERER_CA=${DIRECTORY}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_BUYER_CA=${DIRECTORY}/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${DIRECTORY}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${DIRECTORY}/../../artifacts/private-data-collections/collection-config.json


export CHANNEL_NAME=mychannel

setGlobalsForPeer0buyer() {
    export CORE_PEER_LOCALMSPID=buyerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:7051

}

setGlobalsForPeer1buyer() {
    export CORE_PEER_LOCALMSPID=buyerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${DIRECTORY}/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:8051

}

presetup() {
    echo Vendoring Go dependencies ...
    pushd ./../../artifacts/Mychaincode
    GO111MODULE=on go mod vendor
    popd
    echo Finished vendoring Go dependencies
}
# presetup

export CHANNEL_NAME="mychannel"
export CC_RUNTIME_LANGUAGE="golang"
export VERSION="1"
export CC_SRC_PATH="${DIRECTORY}/../../artifacts/Mychaincode"
export CC_NAME="conversion"

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0buyer
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on b-peer0.buyer ===================== "
}
packageChaincode

echo "installing Chaincode on buyer peer0... This may take a few minutes."

installChaincode() {
    setGlobalsForPeer0buyer
    cd ${DIRECTORY} && peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on b-peer0.buyer ===================== "

}

installChaincode

queryInstalled() {
    setGlobalsForPeer0buyer
    cd ${DIRECTORY} && peer lifecycle chaincode queryinstalled >log.txt &
}
queryInstalled

approveForbuyer() {
    setGlobalsForPeer0buyer

    cd ${DIRECTORY} && peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.GOnetwork.com --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --version ${VERSION} --init-required --package-id "fec8cde5ddc8d9143e8c619f91c9d8f5337eae999667e0d678819f5bc26f2519" \
        --sequence ${VERSION} --collections-config ${COLLECTION_CONFIGPATH}

    echo "===================== chaincode approved from buyer ===================== "
}
# queryInstalled
approveForbuyer

checkCommitReadyness() {

    setGlobalsForPeer0buyer
    cd ${DIRECTORY} && peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required \
        --collections-config ${COLLECTION_CONFIGPATH}
    echo "===================== checking commit readyness from buyer ===================== "
}

checkCommitReadyness
