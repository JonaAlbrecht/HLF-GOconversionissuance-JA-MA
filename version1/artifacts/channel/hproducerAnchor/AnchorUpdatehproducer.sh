cd $(dirname $0)

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
export PEER0_HPRODUCER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/eproducer-vm2/crypto-config/peerOrganizations/hproducer.GOnetwork.com/h-peers/h-peer0.hproducer.GOnetwork.com/tls/ca.crt
export FABRIC_CFG_PATH=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/artifacts/channel/config/

export CORE_PEER_LOCALMSPID=hproducerMSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HPRODUCER_CA
export CORE_PEER_MSPCONFIGPATH=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/Admin/oAdmin@hproducer.GOnetwork.com/msp
export CORE_PEER_ADDRESS=localhost:13051

export CHANNEL_NAME=$1

fetchChannelConfig() {
    peer channel fetch config ${PWD}/config_block.pb -o localhost:10050 --ordererTLSHostnameOverride orderer4.GOnetwork.com -c $CHANNEL_NAME --tls --cafile "$ORDERER_CA"
    configtxlator proto_decode --input ${PWD}/config_block.pb --type common.Block --output ${PWD}/config_block.json
    jq .data.data[0].payload.data.config ${PWD}/config_block.json >"${PWD}/hproducerMSPconfig.json"
}

createConfigUpdate() {
    configtxlator proto_encode --input "${PWD}/hproducerMSPconfig.json" --type common.Config --output ${PWD}/original_config.pb
    configtxlator proto_encode --input "${PWD}/hproducerMSPmodified_config.json" --type common.Config --output ${PWD}/modified_config.pb
    configtxlator compute_update --channel_id "${CHANNEL_NAME}" --original ${PWD}/original_config.pb --updated ${PWD}/modified_config.pb --output ${PWD}/config_update.pb
    configtxlator proto_decode --input ${PWD}/config_update.pb --type common.ConfigUpdate --output ${PWD}/config_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat ${PWD}/config_update.json)'}}}' | jq . > ${PWD}/config_update_in_envelope.json
    configtxlator proto_encode --input ${PWD}/config_update_in_envelope.json --type common.Envelope --output "${PWD}/hproducerMSPanchors.tx"
}

createAnchorPeerUpdate() {
    fetchChannelConfig
    jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'h-peer0.hproducer.GOnetwork'","port": '13051'}]},"version": "0"}}' ${PWD}/${CORE_PEER_LOCALMSPID}config.json > ${PWD}/${CORE_PEER_LOCALMSPID}modified_config.json
    createConfigUpdate
}

updateAnchorPeerhproducer() {
  peer channel update -o localhost:10050 --ordererTLSHostnameOverride orderer4.GOnetwork.com -c $CHANNEL_NAME -f ${PWD}/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA"
}

createAnchorPeerUpdate
updateAnchorPeerhproducer