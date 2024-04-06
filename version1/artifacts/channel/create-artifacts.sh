
chmod -R 0755 ./crypto-config
# Delete existing artifacts
rm -rf ./crypto-config
rm genesis.block mychannel.tx
rm -rf ../../channel-artifacts/*

#Generate Crypto artifacts for organizations
cryptogen generate --config=./crypto-config.yaml --output=./crypto-config/



# System channel
SYS_CHANNEL="sys-channel"

CHANNEL_NAME="mychannel"

echo $CHANNEL_NAME

# Generate System Genesis block
configtxgen -profile OrdererGenesis -configPath . -channelID $SYS_CHANNEL  -outputBlock ./genesis.block


# Generate channel configuration block
configtxgen -profile BasicChannel -configPath . -outputCreateChannelTx ./mychannel.tx -channelID $CHANNEL_NAME

echo "#######    Generating anchor peer update for buyerMSP  ##########"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./buyerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg buyerMSP

echo "#######    Generating anchor peer update for eproducerMSP  ##########"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./eproducerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg eproducerMSP

echo "#######    Generating anchor peer update for issuerMSP  ##########"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./issuerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg issuerMSP

echo "#######    Generating anchor peer update for hproducerMSP  ##########"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./hproducerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg hproducerMSP