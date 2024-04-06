sudo apt install bc
export ID=$RANDOM
export CreationDateTime=$(date)
#maxEfficiency is 50MWh
export maxEfficiency=50
export randomLoss=$((1 + $RANDOM % 10))
export minute=60
export inbetween=$(($maxEfficiency - $randomLoss))
export AmountMWh=$(echo "scale=2 ; $inbetween / $minute" | bc)
#emission intensity of 50g of CO2 per KWh

export eGO=$(echo -n "{\"ID\":\"$ID\",\"CreationDateTime\":\"$CreationDateTime\",\"AmountMWh\":\"$AmountMWh\",\"Emissions\":\"$Emissions\",\"owner\":\"pavan\",\"price\":\"10000\")"} | base64 | tr -d \\n)
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_BUYER_CA=${PWD}/../buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.issuer.GOnetwork.com/tls/ca.crt
export PEER0_EPRODUCER_CA=${PWD}/../eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export PEER0_BUYER_CA=${PWD}/../buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.issuer.GOnetwork.com/tls/ca.crt
export PEER0_HPRODUCER_CA=${PWD}/../hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt

peer chaincode invoke -o localhost:7050 \
 --ordererTLSHostnameOverride orderer2.example.com \
 --tls $CORE_PEER_TLS_ENABLED \
 --cafile $ORDERER_CA \
 -C $CHANNEL_NAME -n ${CC_NAME} \
 --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BUYER_CA \
 --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_EPRODUCER_CA \
 --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ISSUER_CA \
 --peerAddresses localhost:13051 --tlsRootCertFiles $PEER0_HPRODUCER_CA \
 -c '{"function": "createElectricityGO", "Args":[]}' \
 --transient "{\"eGO\":\"$eGO\"}"

let "count +=1"