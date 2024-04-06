export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_EPRODUCER_CA=${PWD}/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/

export CHANNEL_NAME=mychannel

setGlobalsForPeer0eproducer() {
    export CORE_PEER_LOCALMSPID="eproducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/Admin@eproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}

setGlobalsForPeer1eproducer() {
    export CORE_PEER_LOCALMSPID="eproducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/Admin@eproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:10051

}

fetchChannelBlock() {
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0eproducer
    #replace given IP address with IP address of the orderer vm
    # If deploying on single machine, replace orderer's vm IP address with "localhost"
    peer channel fetch 0 ./channel-artifacts/$CHANNEL_NAME.block -o localhost:8050 \
        --ordererTLSHostnameOverride orderer2.GOnetwork.com \
        -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
}

# fetchChannelBlock

joinChannel() {
    setGlobalsForPeer0eproducer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

    setGlobalsForPeer1eproducer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

}

# joinChannel

updateAnchorPeers() {
    setGlobalsForPeer0eproducer
    #replace given IP address with IP address of the orderer vm
    # If deploying on single machine, replace orderer's vm IP address with "localhost"
    peer channel update -o localhost:8050 --ordererTLSHostnameOverride orderer2.GOnetwork.com \
        -c $CHANNEL_NAME -f ./../../artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA

}

#updateAnchorPeers

fetchChannelBlock
joinChannel
updateAnchorPeers
