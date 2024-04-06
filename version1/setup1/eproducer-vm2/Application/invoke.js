const {
  Gateway,
  Wallets,
  TxEventHandler,
  GatewayOptions,
  DefaultEventHandlerStrategies,
  TxEventHandlerFactory,
} = require("fabric-network");
const fs = require("fs");
const path = require("path");
const util = require("util");
const helper = require("./helper");

async function main(fcn, username, transientData) {
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
    const network = await gateway.getNetwork("mychannel");

    const contract = network.getContract("conversion");

    let eGOData = JSON.parse(transientData);
    console.log(`GO data is : ${JSON.stringify(eGOData)}`);
    let key = Object.keys(eGOData)[0];
    const transientDataBuffer = {};
    transientDataBuffer[key] = Buffer.from(JSON.stringify(eGOData.key));
    result = await contract
      .createTransaction(fcn)
      .setTransient(transientDataBuffer)
      .submit();
    message = `Successfully submitted transient data`;

    await gateway.disconnect();

    result = JSON.parse(result.toString());

    let response = {
      message: message,
      result,
    };

    return response;
  } catch (error) {
    console.log(`Getting error: ${error}`);
    return error.message;
  }
}

// Cronjob, creating a createGO request every 50 seconds.
cron.schedule("50 * * * *", async () => {
  console.log(`Performing asset transfer at ${new Date().toISOString()}`);
  await main();
});

console.log("Cron job scheduled for asset transfer...");
