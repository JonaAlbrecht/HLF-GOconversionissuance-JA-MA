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

export eCancelID=$1
# MSP is parametrized for buyerorganisation such that one can check the access to other private collections of other organisations
# this will throw "access denied" messages
# to use functions as usual type "buyerMSP" in Position 2 after function invocation, type "eproducerMSP" or "hproducerMSP" otherwise 
export MSP=$2

ReadCancelStatementElectricity() {
    start=$(date +%s%N)
    setGlobalsForPeer0buyer
    export QueryInput=$(echo -n "{\"Collection\":\"privateDetails-$MSP\", \"eCancelID\":\"$eCancelID\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadCancelstatementfromCollectionElectricity", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    end=$(date +%s%N)
    echo "ReadCancelStatementElectricity Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

ReadCancelStatementElectricity