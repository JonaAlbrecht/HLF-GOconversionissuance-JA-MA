
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${PWD}/../../artifacts/private-data-collections/collection-config.json

export CHANNEL_NAME=mychannel28

setGlobalsForPeer0issuer() {
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
}

setGlobalsForPeer1issuer() {
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:12051

}

presetup() {
    echo Vendoring Go dependencies ...
    pushd ./../../artifacts/Mychaincode
    GO111MODULE=on go mod vendor
    popd 
    echo Finished vendoring Go dependencies
}
presetup

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

echo "installing Chaincode on issuer peer0... This may take a few minutes."

installChaincode() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on i-peer0.issuer ===================== "

}

installChaincode

queryInstalled() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode queryinstalled >&${PWD}/log.txt
    cat ${PWD}/log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" ${PWD}/log.txt)
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
        --sequence ${VERSION} --collections-config $COLLECTION_CONFIGPATH
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
        --collections-config $COLLECTION_CONFIGPATH
    echo "===================== checking commit readyness from issuer ===================== "
}

checkCommitReadyness