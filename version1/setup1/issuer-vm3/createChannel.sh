cd $(dirname $0)

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/

export CHANNEL_NAME=mychannel

setGlobalsForPeer0issuer(){
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
}

setGlobalsForPeer1issuer(){
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:12051
}

createChannel(){
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0issuer
    # If deploying on multiple VMs, replace "localhost" with orderer's vm IP address
    peer channel create -o localhost:9050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer3.GOnetwork.com \
    -f ./../../artifacts/channel/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

createChannel

joinChannel(){
    setGlobalsForPeer0issuer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer1issuer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
}

joinChannel

updateAnchorPeers(){
    setGlobalsForPeer0issuer
    # If deploying on multiple VMs, replace "localhost" with orderer's vm IP address
    peer channel update -o localhost:9050 --ordererTLSHostnameOverride orderer3.GOnetwork.com -c $CHANNEL_NAME -f ./../../artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
}

updateAnchorPeers