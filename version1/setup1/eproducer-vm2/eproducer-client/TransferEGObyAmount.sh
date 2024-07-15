export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_EPRODUCER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export PEER0_ISSUER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
#added hproducer and buyer as part of second design cycle
export PEER0_HPRODUCER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export PEER0_BUYER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=$1
export CC_NAME="conversion"
export NeededAmount=$2
export Recipient=$3

setGlobalsForPeer0eproducer() {
    export CORE_PEER_LOCALMSPID=eproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/TrustedUser/eTrustedUser@eproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=e-peer0.eproducer.GOnetwork.com:9051
}

QueryPrivateeGOsbyAmountMWh() {
    
    setGlobalsForPeer0eproducer
    export QueryInput=$(echo -n "{\"NeededAmount\":\"$NeededAmount\",\"Collection\":\"privateDetails-$CORE_PEER_LOCALMSPID\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "QueryPrivateeGOsbyAmountMWh", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    
}


TransferEGOsbyAmount() {
    start=$(date +%s%N)
    export input=$(QueryPrivateeGOsbyAmountMWh)
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
    export TransferInput=$(echo -n "{\"EGOList\":$finalinput,\"Recipient\":\"$Recipient\",\"Neededamount\":\"$NeededAmount\"}" | base64 | tr -d \\n)
    setGlobalsForPeer0eproducer
    peer chaincode invoke -o orderer2.GOnetwork.com:8050 \
        --ordererTLSHostnameOverride orderer2.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses i-peer0.issuer.GOnetwork.com:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        -c '{"function": "TransfereGObyAmount","Args":[]}' \
        --transient "{\"TransferInput\":\"$TransferInput\"}" --waitForEvent
    end=$(date +%s%N)
    echo "TransferEGObyAmount Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

TransferEGOsbyAmount


#--peerAddresses h-peer0.hproducer.GOnetwork.com:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
#--peerAddresses b-peer0.buyer.GOnetwork.com:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
#--peerAddresses e-peer0.eproducer.GOnetwork.com:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
