export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_BUYER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/ca.crt
export PEER0_ISSUER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=mychannel
export CC_NAME="conversion"

setGlobalsForPeer0buyer() {
    export CORE_PEER_LOCALMSPID=buyerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=b-peer0.buyer.GOnetwork.com:7051
}

export CancelAmount=$1
# MSP is parametrized for buyerorganisation such that one can check the access to other private collections of other organisations
# this will throw "access denied" messages
# to use functions as usual type "buyerMSP" in Position 2 after function invocation, type "eproducerMSP" or "hproducerMSP" otherwise 
export MSP=$2

QueryPrivatehGOsbyAmountMWh() {
    
    setGlobalsForPeer0eproducer
    export QueryInput=$(echo -n "{\"NeededAmount\":\"$CancelAmount\",\"Collection\":\"privateDetails-$MSP\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "QueryPrivatehGOsbyAmount", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    
}


ClaimRenewableattributesHydrogen() {
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
    export ClaimRenewables=$(echo -n "{\"Collection\":\"privateDetails-$MSP\",\"EGOList\":\"$finalinput\",\"Cancelamount\":\"$Cancelamount\"}" | base64 | tr -d \\n)
    setGlobalsForPeer0eproducer
    peer chaincode invoke -o orderer.GOnetwork.com:7050 \
        --ordererTLSHostnameOverride orderer.GOnetwork.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses b-peer0.buyer.GOnetwork.com:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
        --peerAddresses i-peer0.issuer.GOnetwork.com:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
        -c '{"function": "ClaimRenewableattributesHydrogen","Args":[]}' \
        --transient "{\"ClaimRenewables\":\"$ClaimRenewables\"}" --waitForEvent
    end=$(date +%s%N)
    echo "ClaimRenewableattributesElectricity Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

ClaimRenewableattributesHydrogen
