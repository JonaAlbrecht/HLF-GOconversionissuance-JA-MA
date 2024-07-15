const { Gateway, Wallets } = require("fabric-network");
const {
  buildConnectionProfile,
  buildWallet,
  getWalletPath,
  readCertificateintoWallet,
} = require("./modules/gateway.js");

const channelname = "mychannel15";
const chaincode = "conversion";

async function buildGateway(org, username) {
  const ccp = buildConnectionProfile(org);
  let response;
  response = readCertificateintoWallet(org, username);
  if ((await response).success == false) {
    console.log((await response).message);
    process.exit(1);
  }

  const walletPath = await getWalletPath(org);
  const wallet = await buildWallet(Wallets, walletPath);
  try {
    const gateway = new Gateway();
    await gateway.connect(ccp, {
      identity: username,
      wallet: wallet,
      discovery: { enabled: true, asLocalhost: true },
    });

    return gateway;
  } catch (error) {
    console.error(`error building gateway: ${error}`);
  }
}

async function ReadPrivatefromCollectioneGO(assetKey, collection) {
  try {
    const resultBuffer = await contract.evaluateTransaction(
      "ReadPrivatefromCollectioneGO",
      assetKey,
      collection
    );
    const asset = JSON.parse(resultBuffer.toString("utf8"));
    console.log(
      `"Private Details of asset:" ${assetKey} ${JSON.stringify(asset)}`
    );
  } catch (evalError) {
    console.log(`Error reading private electricity GO details: ${evalError}`);
  }
}

async function ReadPublicEGO(assetKey) {
  try {
    const resultBuffer = await contract.evaluateTransaction(
      "ReadPublicEGO",
      assetKey
    );
    const asset = JSON.parse(resultBuffer.toString("utf8"));
    console.log(
      `"Public Details of asset:" ${assetKey} ${JSON.stringify(asset)}`
    );
  } catch (evalError) {
    console.log(`Error reading public electricity GO details: ${evalError}`);
  }
}

async function GetCurrenteGOList(startKey, endKey) {
  try {
    const resultBuffer = await contract.evaluateTransaction(
      "GetCurrenteGOList",
      startKey,
      endKey
    );
    const asset = JSON.parse(resultBuffer.toString("utf8"));
    console.log(`"Current eGO List is:" ${assetKey} ${JSON.stringify(asset)}`);
  } catch (evalError) {
    console.log(`Error reading public electricity GO details: ${evalError}`);
  }
}

async function QueryPrivateeGOsbyAmountMWh(Neededamount, Collection) {
  try {
    const resultBuffer = await contract.evaluateTransaction(
      "QueryPrivateeGOsbyAmountMWh",
      Neededamount,
      Collection
    );
    const result = JSON.parse(resultBuffer.toString("utf8"));
    return result;
  } catch (evalError) {
    console.log(`Error reading public electricity GO details: ${evalError}`);
  }
}

async function main() {
  try {
    const org = "buyer";
    const issuer = "issuer";
    const username = "Admin@buyer.GOnetwork.com";
    var args = process.argv;
    const ccfunction = args[0];
    const gateway = await buildGateway(org, username);
    const network = await gateway.getNetwork(channelname);
    const contract = network.getContract(chaincode);

    try {
      let transaction;
      let assetKey;
      if (ccfunction == "ReadPrivatefromCollectioneGO") {
        assetKey = args[1];
        let collection = args[2];
        await ReadPrivatefromCollectioneGO(assetKey, collection);
      } else if (ccfunction == "ReadPublicEGO") {
        assetKey = args[1];
        await ReadPublicEGO(assetKey);
      } else if (ccfunction == "GetCurrenteGOList") {
        const startKey = "eGO1";
        const endKey = "eGO50";
        await GetCurrenteGOList(startKey, endKey);
      } else if (ccfunction == "TransferEGO") {
        transaction = contract.createTransaction("TransferEGO");
        transaction.setEndorsingorganizations(org, issuer);
        let EGO = args[1];
        let Recipient = args[2];
        let txdata = { EGO: EGO, Recipient: Recipient };
        let TransferInput = Buffer.from(JSON.stringify(txdata));
        transaction.setTransient({
          TransferInput: TransferInput,
        });
        (result = await transaction.submit()), process.exit[1];
      } else if (ccfunction == "TransfereGObyAmount") {
        let Neededamount = args[1];
        let Collection = args[2];
        let Recipient = args[3];
        result = await QueryPrivateeGOsbyAmountMWh(Neededamount, Collection);
        let txdata = {
          EGOList: result,
          Recipient: Recipient,
          Neededamount: Neededamount,
        };
        transaction = contract.createTransaction("TransferEGObyAmount");
        transaction.setEndorsingorganizations(org, issuer);
        let TransferInput = Buffer.from(JSON.stringify(txdata));
        transaction.setTransient({
          TransferInput: TransferInput,
        });
      }
    } finally {
      gateway.disconnect();
    }
  } catch (error) {
    console.log(`Caught the error: \n ${error}`);
    process.exit(1);
  }
}

main();
