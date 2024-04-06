"use strict";

const cron = require("node-cron");
const { Gateway, Wallets } = require("fabric-network");
const FabricCAServices = require("fabric-ca-client");
const fs = require("fs");
const helper = require("./helper");

const channelName = "mychannel";
const chaincodeName = "conversion";

const certificate = fs.readFileSync(
  "./../crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp/signcerts/cert.pem",
  { encoding: "utf8" }
);
const SmartMeterID = "SmartMeter1@eproducer.GOnetwork.com";
const OwnerID = "eproducer.GOnetwork.com";

//}
var lastDatetime = new Date().getTime();

// Function to perform asset transfer
async function main() {
  console.log("Creating transaction");

  try {
    // load the network configuration
    // const ccpPath =path.resolve(__dirname, '..', 'config', 'connection-org1.json');
    // const ccpJSON = fs.readFileSync(ccpPath, 'utf8')
    const ccp = await helper.getCCP(); //JSON.parse(ccpJSON);

    // Create a new file system based wallet for managing identities.
    const walletPath = await helper.getWalletPath(); //path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);

    // Check to see if we've already enrolled the user.
    let identity = await wallet.get(username);
    if (!identity) {
      console.log(
        `An identity for the user ${username} does not exist in the wallet, so registering user`
      );
      await helper.getRegisteredUser(username, true);
      identity = await wallet.get(username);
      return;
    }

    const connectOptions = {
      wallet,
      identity: username,
      discovery: { enabled: true, asLocalhost: true },
      eventHandlerOptions: {
        commitTimeout: 100,
        strategy: DefaultEventHandlerStrategies.NETWORK_SCOPE_ALLFORTX,
      },
      // transaction: {
      //     strategy: createTransactionEventhandler()
      // }
    };

    // Create a new gateway for connecting to our peer node.
    const gateway = new Gateway();
    await gateway.connect(ccp, connectOptions);

    // Get the network (channel) our contract is deployed to.
    const network = await gateway.getNetwork(channelName);

    const contract = network.getContract(chaincodeName);

    try {
      var currentdate = new Date();
      var datetime =
        currentdate.getDay() +
        "/" +
        currentdate.getMonth() +
        "/" +
        currentdate.getFullYear() +
        " @ " +
        currentdate.getHours() +
        ":" +
        currentdate.getMinutes() +
        ":" +
        currentdate.getSeconds();
      let randomNumber1 = Math.floor(Math.random() * 1000);
      let randomNumber2 = Math.floor(Math.random());
      //maxOutput of production device in kW
      let maxOutput = 100.0;
      let Intervalms = new Date().getTime() - lastDatetime;
      let output =
        ((0.9 * maxOutput + 10 * randomNumber2) * Intervalms) / (100 * 3600);
      let assetID1 = `asset${randomNumber1}`;
      let result;
      let ElectricityGO = {
        AssetID: assetID1,
        CreationDateTime: datetime,
        OwnerID: OwnerID,
        AmountMWh: output,
        Emissions: emissions,
        ProductionMethod: "solar",
        SmartMeterID: SmartMeterID,
        SmartMeterCertificate: certificate,
      };
      let statefulTxn = contract.createTransaction("CreateAsset");
      //this line requires endorsement of the transaction from the issuer organisation
      statefulTxn.setEndorsingOrganizations(issuerMSP);
      let tmapData = Buffer.from(JSON.stringify(ElectricityGO));
      statefulTxn.setTransient({
        asset_properties: tmapData,
      });
      result = await statefulTxn.submit();
    } catch (createError) {
      console.log(`Failed to create Asset`);
      process.exit(1);
    }

    console.log("Submitting transaction " + assetID1);
    // Disconnect from the gateway
    await gateway.disconnect();
  } catch (error) {
    console.error(`Failed to submit asset transfer transaction: ${error}`);
    process.exit(2);
  }
}

// Cronjob, creating a createGO request every 50 seconds.
cron.schedule("50 * * * *", async () => {
  console.log(`Performing asset transfer at ${new Date().toISOString()}`);
  await main();
});

console.log("Cron job scheduled for asset transfer...");
