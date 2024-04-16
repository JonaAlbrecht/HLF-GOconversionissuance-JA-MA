export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export PEER0_EPRODUCER_CA=${PWD}/../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export PEER0_BUYER_CA=${PWD}/../buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/ca.crt
export PEER0_HPRODUCER_CA=${PWD}/../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/
export COLLECTION_CONFIGPATH=${PWD}/../../artifacts/private-data-collections/collection-config.json


export CHANNEL_NAME=mychannel
CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH="./../../artifacts/Mychaincode"
CC_NAME="conversion" 

setGlobalsForPeer0issuer() {
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
}
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
        --collections-config $COLLECTION_CONFIGPATH
}

commitChaincodeDefinition

queryCommitted() {
    setGlobalsForPeer0issuer
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}

}

queryCommitted

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
