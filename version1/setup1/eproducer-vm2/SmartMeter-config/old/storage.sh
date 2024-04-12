#max Efficiency of 50MW as per certificate
export maxEfficiency=50
export randomLoss=$((1 + $RANDOM % 5))
export AmountMWh=$(($maxEfficiency - $randomLoss))
#emission intensity of 50kilos of CO2 per MWh
export EmissionIntensityElectricity=50
export Emissions=$(($AmountMWh * $EmissionIntensityElectricity))
#60 seconds elapsed as per Cronjob --> this could be made more credible by using the date function of bash
export ElapsedSeconds=60
export ElectricityProductionMethod="solar"
export eGO=$(echo -n "{\"AmountMWh\":\"$AmountMWh\",\"Emissions\":\"$Emissions\",\"ElapsedSeconds\":\"$ElapsedSeconds\",\"ElectricityProductionMethod\":\"$ElectricityProductionMethod\"}" | base64 | tr -d \\n)
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="eproducerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp
export CORE_PEER_ADDRESS=e-peer0.eproducer.GOnetwork.com:9051
export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export CHANNEL_NAME="mychannel"
export CC_NAME="conversion" 

peer chaincode invoke -o orderer2.GOnetwork.com:8050 \
 --ordererTLSHostnameOverride orderer2.GOnetwork.com \
 --tls \
 --cafile $ORDERER_CA -C mychannel -n conversion \
 --peerAddresses e-peer0.eproducer.GOnetwork.com:9051 --tlsRootCertFiles /etc/hyperledger/channel/crypto-config/peerOrganizations/eproducer.GOnetwork.com/e-peers/e-peer0.eproducer.GOnetwork.com/tls/ca.crt \
 --peerAddresses i-peer0.issuer.GOnetwork.com:11051 --tlsRootCertFiles /etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt \
 -c '{"function": "CreateElectricityGO", "Args":[]}' \
 --transient "{\"eGO\":\"$eGO\"}" 