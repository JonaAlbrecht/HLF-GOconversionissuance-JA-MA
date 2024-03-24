export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_BUYER_CA=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/peers/peer0.buyer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../artifacts/channel/config/

export CHANNEL_NAME=mychannel

setGlobalsForPeer0buyer(){
    export CORE_PEER_LOCALMSPID="buyerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/users/Admin@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1buyer(){
    export CORE_PEER_LOCALMSPID="buyerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/buyer.GOnetwork.com/users/Admin@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
}

createChannel(){
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0buyer
    
    #replace given IP address with IP address of the orderer vm
    # If deploying on single machine, replac orderer's vm IP address with "localhost"
    peer channel create -o 34.125.58.24:7050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.GOnetwork.com \
    -f ./../../artifacts/channel/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

createChannel

joinChannel(){
    setGlobalsForPeer0buyer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer1buyer
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
}

joinChannel

updateAnchorPeers(){
    setGlobalsForPeer0buyer
    #replace given IP address with IP address of the orderer vm
    # If deploying on single machine, replac orderer's vm IP address with "localhost"
    peer channel update -o 34.125.58.24:7050 --ordererTLSHostnameOverride orderer.GOnetwork.com -c $CHANNEL_NAME -f ./../../artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
}

updateAnchorPeers

# removeOldCrypto

#createChannel
#joinChannel
#updateAnchorPeers