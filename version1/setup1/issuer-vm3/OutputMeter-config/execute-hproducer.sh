execute () {
    
    start=$(date +%s%N)
    #maxOutput = 10000 kilos of hydrogen per hour as per certificate
    export maxOutput=$((10000))
    export randomLoss1=$((1 + $RANDOM % 1000))
    export Kilosproducedperhour=$(($maxOutput - $randomLoss1))
    export Kilosproduced=$(($Kilosproducedperhour/60))
    #emission intensity of 4 kilos of CO2 per Kilos produced
    export EmissionIntensityHydrogen=4
    export EmissionsHydrogen=$(($Kilosproduced * $EmissionIntensityHydrogen))
    export kwhperkilo=50
    export UsedMWh=$(($Kilosproduced*$kwhperkilo/1000))
    export ElapsedSeconds=60
    export HydrogenProductionMethod="PEMelectrolyser"
    export hGO=$(echo -n "{\"Kilosproduced\":\"$Kilosproduced\",\"EmissionsHydrogen\":\"$EmissionsHydrogen\",\"UsedMWh\":\"$UsedMWh\",\"HydrogenProductionMethod\":\"$HydrogenProductionMethod\",\"ElapsedSeconds\":\"$ElapsedSeconds\"}" | base64 | tr -d \\n)
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID=issuerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com/msp
    export CORE_PEER_ADDRESS=i-peer0.issuer.GOnetwork.com:11051
    export ORDERER_CA=/etc/hyperledger/channel/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
    export CHANNEL_NAME=mychannel
    export CC_NAME="conversion" 

    peer chaincode invoke -o orderer3.GOnetwork.com:9050 \
     --ordererTLSHostnameOverride orderer3.GOnetwork.com \
     --tls $CORE_PEER_TLS_ENABLED \
     --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} \
     --peerAddresses i-peer0.issuer.GOnetwork.com:11051 --tlsRootCertFiles /etc/hyperledger/channel/crypto-config/peerOrganizations/issuer.GOnetwork.com/i-peers/i-peer0.issuer.GOnetwork.com/tls/ca.crt \
     --peerAddresses h-peer0.hproducer.GOnetwork.com:13051 --tlsRootCertFiles /etc/hyperledger/channel/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt \
     -c '{"function": "addHydrogentoBacklog", "Args":[]}' \
     --transient "{\"hGO\":\"$hGO\"}" --waitForEvent
    
    end=$(date +%s%N)
    echo "Elapsed time: $(($(($end-$start))/1000000)) ms" >> /custom/bin/time.txt
}

execute