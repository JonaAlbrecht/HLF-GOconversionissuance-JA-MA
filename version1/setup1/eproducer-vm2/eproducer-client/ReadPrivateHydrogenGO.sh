export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_EPRODUCER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=$1
export CC_NAME="conversion"
export hGOID=$2

setGlobalsForPeer0eproducer() {
    export CORE_PEER_LOCALMSPID=eproducerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EPRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/TrustedUser/eTrustedUser@eproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=e-peer0.eproducer.GOnetwork.com:9051
}

ReadPrivatefromCollectionhGO() {
     start=$(date +%s%N)
    setGlobalsForPeer0eproducer
    export QueryInput=$(echo -n "{\"Collection\":\"privateDetails-$CORE_PEER_LOCALMSPID\", \"hGOID\":\"$hGOID\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPrivatefromCollectionhGO", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    end=$(date +%s%N)
    echo "ReadPrivatefromCollectioneGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

ReadPrivatefromCollectionhGO