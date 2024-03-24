export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_BUYER_CA=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/peers/peer0.buyer.GOnetwork.com/tls/ca.crt
export PEER0_EPRODUCER_CA=${PWD}/../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/peers/peer0.eproducer.GOnetwork.com/tls/ca.crt
export PEER0_ISSUER_CA=${PWD}/../issuer-vm3/crypto-config/peerOrganizations/issuer.GOnetwork.com/peers/peer0.issuer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/


export CHANNEL_NAME=mychannel

setGlobalsForPeer0buyer() {
    export CORE_PEER_LOCALMSPID="buyerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/users/Admin@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1buyer() {
    export CORE_PEER_LOCALMSPID="buyerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/users/Admin@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:8051

}

# setGlobalsForPeer0eproducer() {
#     export CORE_PEER_LOCALMSPID="eproducerMSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
#     export CORE_PEER_MSPCONFIGPATH=${PWD}/../../artifacts/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/users/Admin@eproducer.GOnetwork.com/msp
#     export CORE_PEER_ADDRESS=localhost:9051

# }

# setGlobalsForPeer1eproducer() {
#     export CORE_PEER_LOCALMSPID="eproducerMSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
#     export CORE_PEER_MSPCONFIGPATH=${PWD}/../../artifacts/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/users/Admin@eproducer.GOnetwork.com/msp
#     export CORE_PEER_ADDRESS=localhost:10051

# }

presetup() {
    echo Vendoring Go dependencies ...
    pushd ./../../artifacts/src/github.com/fabcar/go
    GO111MODULE=on go mod vendor
    popd
    echo Finished vendoring Go dependencies
}
presetup

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="8"
CC_SRC_PATH="./../../artifacts/src/github.com/fabcar/go"
CC_NAME="fabcar"

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0buyer
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on peer0.buyer ===================== "
}
packageChaincode

installChaincode() {
    setGlobalsForPeer0buyer
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.buyer ===================== "

}

installChaincode

queryInstalled() {
    setGlobalsForPeer0buyer
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed successful on peer0.buyer on channel ===================== "
}

queryInstalled

approveForbuyer() {
    setGlobalsForPeer0buyer
    # set -x
    # Replace with current orderer VM IP address or change to localhost if deploying on single machine
    peer lifecycle chaincode approveformyorg -o 34.125.58.24:7050 \
        --ordererTLSHostnameOverride orderer.GOnetwork.com --tls \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --init-required --package-id ${PACKAGE_ID} \
        --sequence ${VERSION}
    # set +x

    echo "===================== chaincode approved from buyer ===================== "

}

queryInstalled
approveForbuyer

checkCommitReadyness() {
    setGlobalsForPeer0buyer
    peer lifecycle chaincode checkcommitreadiness \
        --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --sequence ${VERSION} --output json --init-required
    echo "===================== checking commit readyness from buyer ===================== "
}

#checkCommitReadyness

commitChaincodeDefinition() {
    setGlobalsForPeer0buyer
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
        --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        --version ${VERSION} --sequence ${VERSION} --init-required
}

#commitChaincodeDefinition

queryCommitted() {
    setGlobalsForPeer0buyer
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}

}

#queryCommitted

chaincodeInvokeInit() {
    setGlobalsForPeer0buyer
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
         --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        --isInit -c '{"Args":[]}'

}

 # --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \

# chaincodeInvokeInit

chaincodeInvoke() {
    setGlobalsForPeer0buyer

    ## Create Car
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA   \
        --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        -c '{"function": "createCar","Args":["Car-ABCDEEE", "Audi", "R8", "Red", "Sandip"]}'

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

# chaincodeInvoke

chaincodeQuery() {
    setGlobalsForPeer0buyer

    # Query Car by Id
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "queryCar","Args":["CAR0"]}'
 
}

# chaincodeQuery

# Run this function if you add any new dependency in chaincode
# presetup

# packageChaincode
# installChaincode
# queryInstalled
# approveForbuyer
# checkCommitReadyness
# approveForeproducer
# checkCommitReadyness
# commitChaincodeDefinition
# queryCommitted
# chaincodeInvokeInit
# sleep 5
# chaincodeInvoke
# sleep 3
# chaincodeQuery
