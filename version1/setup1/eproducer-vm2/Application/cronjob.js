"use strict";

const cron = require("node-cron");
const { Gateway, Wallets } = require("fabric-network");
const FabricCAServices = require('fabric-ca-client');
const path = require("path");


const MSPID = "buyerMSP"; 
const WALLET_PATH = path.join(__dirname, "wallet"); // Path to your wallet directory
const CONNECTION_PROFILE_PATH = path.resolve(__dirname, "connection.json"); // Path to your connection profile JSON file



const channelName = process.env.CHANNEL_NAME || 'mychannel';
const chaincodeName = process.env.CHAINCODE_NAME || 'basic';
const assetName = "your_asset_name"; // Replace with the asset you want to transfer
const fromWalletIdentity = "your_wallet_identity"; // Identity to perform the transfer from
const toWalletIdentity = "recipient_wallet_identity"; // Identity to transfer the asset to

// Function to perform asset transfer
async function main() {
  try {
    // Load connection profile and wallet --> there is an easier way to do this somewhere in Pavan basic network stuff
    const ccp = buildCCPOrg1();
    const wallet = await Wallets.newFileSystemWallet(WALLET_PATH);

    // Check if identity exists in the wallet
    const identity = await wallet.get(fromWalletIdentity);
    if (!identity) {
      console.error(`Identity ${fromWalletIdentity} not found in wallet`);
      return;
    }

    // Connect to the gateway using connection profile and wallet
    const gateway = new Gateway();
    await gateway.connect(ccp, {
      wallet,
      identity: fromWalletIdentity,
      discovery: { enabled: true, asLocalhost: true },
    });

    // Access the network
    const network = await gateway.getNetwork("mychannel"); // Replace with your channel name

    // Get contract from the network
    const contract = network.getContract(chaincodeName);


    
    console.log('Adding Assets to work with:\n--> Submit Transaction: CreateAsset ' + assetID1);
    let statefulTxn = contract.createTransaction('CreateAsset');
    //this line requires endorsement of the transaction from both buyer and issuer organisation        
    statefulTxn.setEndorsingOrganizations(buyerMSP, issuerMSP);
    let tmapData = Buffer.from(JSON.stringify(asset1Data));
            statefulTxn.setTransient({
                asset_properties: tmapData
            });
            result = await statefulTxn.submit();

    // Submit asset transfer transaction
    await contract.submitTransaction(
      "TransferAsset",
      assetName,
      toWalletIdentity
    );

    console.log(
      `Asset transfer of ${assetName} to ${toWalletIdentity} successful`
    );

    // Disconnect from the gateway
    await gateway.disconnect();
  } catch (error) {
    console.error(`Failed to submit asset transfer transaction: ${error}`);
    process.exit(1);
  }
}

// Cronjob, creating a createGO request every 50 seconds. 
cron.schedule("50 * * * *", async () => {
  console.log(`Performing asset transfer at ${new Date().toISOString()}`);
  await main();
});

console.log("Cron job scheduled for asset transfer...");
