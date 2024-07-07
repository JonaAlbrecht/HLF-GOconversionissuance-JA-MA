setGlobalsOrderer1() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/tlscacerts/tls-localhost-9054-ca-orderer.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/server.key
}

setGlobalsOrderer2() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/tlscacerts/tls-localhost-9054-ca-orderer.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/server.key
}

setGlobalsOrderer3() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/tlscacerts/tls-localhost-9054-ca-orderer.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/server.key
}

setGlobalsOrderer4() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/tlscacerts/tls-localhost-9054-ca-orderer.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/server.key
}

# Delete existing artifacts --> if this has been forgotten
rm genesis.block mychannel.tx
rm -rf ../../channel-artifacts/*


# System channel
SYS_CHANNEL="sys-channel"

CHANNEL_NAME="mychannel"

echo $CHANNEL_NAME

# Generate System Genesis block using the configtxgen tool with flags:
# -profile from the configtx.yaml file to use for genesis block
# -configPath path to the configtx.yaml file
# -outputBlock path to write the genesis block to
configtxgen -profile OrdererGenesis -configPath . -channelID $SYS_CHANNEL  -outputBlock ./genesis.block


# Generate channel configuration block, anchor peers with flags:
configtxgen -profile BasicChannel -configPath . -outputCreateChannelTx ./mychannel.tx -channelID $CHANNEL_NAME

Orderer1() {
    setGlobalsOrderer1
    osnadmin channel join --channelID $SYS_CHANNEL --config-block ./genesis.block -o orderer.GOnetwork.com:7050 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

Orderer2() {
    setGlobalsOrderer2
    osnadmin channel join --channelID $SYS_CHANNEL --config-block ./genesis.block -o orderer2.GOnetwork.com:8050 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

Orderer3() {
    setGlobalsOrderer3
    osnadmin channel join --channelID $SYS_CHANNEL --config-block ./genesis.block -o orderer3.GOnetwork.com:9050 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

Orderer4() {
    setGlobalsOrderer4
    osnadmin channel join --channelID $SYS_CHANNEL --config-block ./genesis.block -o orderer4.GOnetwork.com:10050 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

Orderer1
Orderer2
Orderer3
Orderer4

#echo "#######    Generating anchor peer update for buyerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./buyerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg buyerMSP

#echo "#######    Generating anchor peer update for eproducerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./eproducerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg eproducerMSP

#echo "#######    Generating anchor peer update for issuerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./issuerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg issuerMSP

#echo "#######    Generating anchor peer update for hproducerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./hproducerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg hproducerMSP