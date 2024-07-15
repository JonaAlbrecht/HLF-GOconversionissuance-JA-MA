export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=$1
export CC_NAME="conversion"

setGlobalsForPeer0issuer() {
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=i-peer0.issuer.GOnetwork.com:11051
}


#This function returns a list of electricity GOs by a range (here set from 0 to 50)
GetcurrenteGOsList() {
    start=$(date +%s%N)
    setGlobalsForPeer0issuer
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "GetcurrenteGOsList","Args":["eGO0", "eGO99"]}'
    end=$(date +%s%N)
    echo "GetcurrenteGOsList Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

GetcurrenteGOsList