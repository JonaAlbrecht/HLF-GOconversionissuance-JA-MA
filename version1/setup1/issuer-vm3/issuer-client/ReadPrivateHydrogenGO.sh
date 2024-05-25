export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/etc/hyperledger/channel/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_ISSUER_CA=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
export CHANNEL_NAME=mychannel
export CC_NAME="conversion"

setGlobalsForPeer0issuer() {
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ISSUER_CA
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-users/Admin@issuer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=i-peer0.issuer.GOnetwork.com:11051
}

export hGOID=$1
export MSP=$2

#This function should return permission denied if e.g. MSP="buyerMSP" and "no GOs found" if MSP="issuerMSP"
ReadPrivatefromCollectionhGO() {
     start=$(date +%s%N)
    setGlobalsForPeer0eproducer
    export QueryInput=$(echo -n "{\"Collection\":\"privateDetails-$MSP\", \"hGOID\":\"$hGOID\"}" | base64 | tr -d \\n)
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "ReadPrivatefromCollectionhGO", "Args":[]}' --transient "{\"QueryInput\":\"$QueryInput\"}"
    end=$(date +%s%N)
    echo "ReadPrivatefromCollectioneGO Elapsed time: $(($(($end-$start))/1000000)) ms" >> time.txt
}

ReadPrivatefromCollectionhGO