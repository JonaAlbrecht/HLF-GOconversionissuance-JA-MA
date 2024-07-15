export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=$1
export CC_NAME="conversion"

setGlobalsForPeer0hproducer() {
    export CORE_PEER_LOCALMSPID=hproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser/hTrustedUser@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=h-peer0.hproducer.GOnetwork.com:13051
}

export hCancelID=$2

ReadCancelStatementHydrogen() {
    start=$(date +%s%N)
    setGlobalsForPeer0hproducer
    export QueryInput=$(echo -n "{\"Collection\":\"privateDetails-$CORE_PEER_LOCALMSPID\", \"hCancelID\":\"$hCancelID\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadCancelstatementfromCollectionHydrogen", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    end=$(date +%s%N)
    echo "ReadCancelStatementHydrogen Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

ReadCancelStatementHydrogen