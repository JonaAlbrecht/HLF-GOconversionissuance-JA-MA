export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export PEER0_ISSUER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=$1
export CC_NAME="conversion"
export hGO=$2
export Recipient=$3

setGlobalsForPeer0hproducer() {
    export CORE_PEER_LOCALMSPID=hproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser/hTrustedUser@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=h-peer0.hproducer.GOnetwork.com:13051
}

TransferhGO() {
    start=$(date +%s%N)
    setGlobalsForPeer0hproducer
    export TransferInput=$(echo -n "{\"EGO\":\"$hGO\",\"Recipient\":\"$Recipient\"}" | base64 | tr -d \\n)
    peer chaincode invoke -o orderer4.GOnetwork.com:10050 \
        --ordererTLSHostnameOverride orderer4.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses h-peer0.hproducer.GOnetwork.com:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
        --peerAddresses i-peer0.issuer.GOnetwork.com:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        -c '{"function": "TransferhGO","Args":[]}' \
        --transient "{\"TransferInput\":\"$TransferInput\"}" --waitForEvent
    end=$(date +%s%N)
    echo "ReadPublichGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

TransferhGO