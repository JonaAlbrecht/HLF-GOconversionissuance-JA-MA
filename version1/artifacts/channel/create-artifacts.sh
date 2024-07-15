export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/keystore/7034cadc9b745eaa8efaaec9c3077b2f234cfa0ca118dcc03d597239f2bcd178_sk

setGlobalsOrderer1() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
}


setGlobalsOrderer2() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
}

setGlobalsOrderer3() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
}

setGlobalsOrderer4() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/signcerts/cert.pem
}

# Delete existing artifacts --> if this has been forgotten
rm mychannel.block mychannel.tx
rm -rf ../../channel-artifacts/*

export CHANNEL_NAME=$1

echo $CHANNEL_NAME

# Generate System Genesis block using the configtxgen tool with flags:
# -profile from the configtx.yaml file to use for genesis block
# -configPath path to the configtx.yaml file
# -outputBlock path to write the genesis block to
configtxgen -profile ChannelUsingRaft -channelID $CHANNEL_NAME  -outputBlock ./${CHANNEL_NAME}.block

orderer1() {
    setGlobalsOrderer1
    osnadmin channel join --channelID $CHANNEL_NAME -o localhost:7053 --config-block ./${CHANNEL_NAME}.block --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

orderer2() {
    setGlobalsOrderer2
    osnadmin channel join --channelID $CHANNEL_NAME -o localhost:8053 --config-block ./${CHANNEL_NAME}.block --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

orderer3() {
    setGlobalsOrderer3
    osnadmin channel join --channelID $CHANNEL_NAME -o localhost:9053 --config-block ./${CHANNEL_NAME}.block  --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

orderer4() {
    setGlobalsOrderer4
    osnadmin channel join --channelID $CHANNEL_NAME -o localhost:10053 --config-block ./${CHANNEL_NAME}.block  --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

orderer1
orderer2
orderer3
orderer4


#echo "#######    Generating anchor peer update for buyerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./buyerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg buyerMSP

#echo "#######    Generating anchor peer update for eproducerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./eproducerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg eproducerMSP

#echo "#######    Generating anchor peer update for issuerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./issuerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg issuerMSP

#echo "#######    Generating anchor peer update for hproducerMSP  ##########"
#configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./hproducerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg hproducerMSP


oldsetGlobalsOrderer1() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer.GOnetwork.com/tls/server.key
}


oldsetGlobalsOrderer2() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer2.GOnetwork.com/tls/server.key
}

oldsetGlobalsOrderer3() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer3.GOnetwork.com/tls/server.key
}

oldsetGlobalsOrderer4() {
    export ORDERER_CA=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/msp/tlscacerts/tlsca.GOnetwork.com-cert.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/orderers/orderer4.GOnetwork.com/tls/server.key
}