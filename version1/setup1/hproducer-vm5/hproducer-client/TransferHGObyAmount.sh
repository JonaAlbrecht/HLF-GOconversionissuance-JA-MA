export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export PEER0_ISSUER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=mychannel
export CC_NAME="conversion"
export NeededAmount=$1
export Recipient=$2

setGlobalsForPeer0hproducer() {
    export CORE_PEER_LOCALMSPID=hproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/TrustedUser/hTrustedUser@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=h-peer0.hproducer.GOnetwork.com:13051
}

QueryPrivatehGOsbyAmountMWh() {
    
    setGlobalsForPeer0hproducer
    export QueryInput=$(echo -n "{\"NeededAmount\":\"$NeededAmount\",\"Collection\":\"privateDetails-$CORE_PEER_LOCALMSPID\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "QueryPrivatehGOsbyAmountMWh", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    
}


TransferHGOsbyAmount() {
    start=$(date +%s%N)
    export input=$(QueryPrivatehGOsbyAmountMWh)
    echo $input
    #remove brackets
    export intinput=${input:1:-1}
    #change commas into pluses
    export int2input="${intinput//,/+}"
    #remove quotation marks
    export int3input="${int2input//\"/}"
    #re-add outside quotationmarks
    export finalinput="\"$int3input\""
    echo $finalinput
    export TransferInput=$(echo -n "{\"HGOList\":$finalinput,\"Recipient\":\"$Recipient\",\"NeededKilos\":\"$NeededAmount\"}" | base64 | tr -d \\n)
    setGlobalsForPeer0eproducer
    peer chaincode invoke -o orderer4.GOnetwork.com:10050 \
        --ordererTLSHostnameOverride orderer4.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses h-peer0.hproducer.GOnetwork.com:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA  \
        --peerAddresses i-peer0.issuer.GOnetwork.com:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        -c '{"function": "TransferhGObyAmount","Args":[]}' \
        --transient "{\"TransferInput\":\"$TransferInput\"}" --waitForEvent
    end=$(date +%s%N)
    echo "ReadPubliceGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

TransferHGOsbyAmount