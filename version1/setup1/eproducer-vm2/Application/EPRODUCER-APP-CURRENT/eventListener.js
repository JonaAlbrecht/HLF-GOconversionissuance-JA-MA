const { Gateway, Wallets } = require("fabric-network");
const fs = require("fs");
const path = require("path");
const log4js = require("log4js");
const logger = log4js.getLogger("BasicNetwork");
const util = require("util");
const http = require("http");
const crypto = require("crypto");

const helper = require("./app/helper");

async function eventListener() {
  const org_name = "eproducer";
  const username = "auto-conversion-handler";
  const ccp = await helper.getCCP(org_name);

  // Create a new file system based wallet for managing identities.
  const walletPath = await helper.getWalletPath(org_name); //.join(process.cwd(), 'wallet');
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  console.log(`Wallet path: ${walletPath}`);

  // Check to see if we've already enrolled the user.
  //GOTTA ENROLL A DUMMY USER HERE BC we are not passing an API request!!!
  let identity = await wallet.get(username);
  if (!identity) {
    console.log(
      `An identity for the user ${username} does not exist in the wallet, so registering user`
    );
    const returnarray = await helper.getRegisteredUser(
      username,
      org_name,
      true
    );
    identity = await wallet.get(username);
    console.log("Run the registerUser.js application before retrying");
  }
  // Create a new gateway for connecting to our peer node.
  const gateway = new Gateway();
  gateway.connect(ccp, {
    wallet,
    identity: username,
    discovery: { enabled: true, asLocalhost: false },
  });

  // Get the network (channel) our contract is deployed to.
  const network = gateway.getNetwork("mychannel");

  // Get the contract from the network.
  const contract = network.getContract("attempt");

  contract.addContractListener(async (event) => {
    if ((event.eventName = "hGOproposal")) {
      const hGOIDproposal = event.payload.toString("utf-8");
      //invoke smart contract function that queries used MWh from the hGO owner
      const x509cert = returnarray[1];
      const publicKey = crypto
        .createPublicKey(x509cert)
        .export({ type: "pkcs1", format: "pem" });

      let result;
      result = await contract.submitTransaction(
        "requestUsedMWh",
        hGOIDproposal
      );
    } else if ((event.eventName = "queryeGO")) {
      const querytask = event.payload.toString("utf-8");
    }
  });
}

const server = http.createServer(function (req, res) {
  res.setHeader("Content-type", "application/json");
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.writeHead(200); //status code
  let dataObj = { id: 123, name: "Bob", email: "bob@work.org" };
  let data = JSON.stringify(dataObj);
  res.end(data);
});

server.listen(1234, function () {
  console.log("Listening on port 1234");
});

server.timeout = 240000;
