export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/

export CHANNEL_NAME=mychannel

setGlobalsForPeer0hproducer() {
    export CORE_PEER_LOCALMSPID="hproducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/oAdmin@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:13051

}

setGlobalsForPeer1hproducer() {
    export CORE_PEER_LOCALMSPID="hproducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/oAdmin@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:14051

}

fetchChannelBlock() {
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0hproducer
    #replace given IP address with IP address of the orderer vm
    # If deploying on single machine, replace orderer's vm IP address with "localhost"
    peer channel fetch 0 ./channel-artifacts/$CHANNEL_NAME.block -o localhost:10050 \
        --ordererTLSHostnameOverride orderer4.GOnetwork.com \
        -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
}

# fetchChannelBlock

joinChannel() {
    setGlobalsForPeer0hproducer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

    setGlobalsForPeer1hproducer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

}

# joinChannel

updateAnchorPeers() {
    setGlobalsForPeer0hproducer
    #replace given IP address with IP address of the orderer vm
    # If deploying on single machine, replace orderer's vm IP address with "localhost"
    peer channel update -o localhost:10050 --ordererTLSHostnameOverride orderer4.GOnetwork.com \
        -c $CHANNEL_NAME -f ./../../artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA

}

#updateAnchorPeers

fetchChannelBlock
joinChannel
updateAnchorPeers
