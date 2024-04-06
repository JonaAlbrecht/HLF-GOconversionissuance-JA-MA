export CAR=$(echo -n "{\"key\":\1234\",\"make\":\"Telsa\",\"model\":\"Tesla A1\",\"color\":\"White\",\"owner\":\"pavan\",\"price\":\"10000\")"} | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 \
 --ordererTLSHostnameOverride orderer.example.com \
 --tls $CORE_PEER_TLS_ENABLED \
 --cafile $ORDERER_CA \
 -C $CHANNEL_NAME -n ${CC_NAME} \
 --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
 --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
 -c '{"function": "createElectricityGO", "Args":[]}' \
 --transient "{\"car\":\"$CAR\"}"

