"use strict";

const fs = require("fs");
const path = require("path");
var { Wallets } = require("fabric-network");

const buildConnectionProfile = async (org) => {
  const jsonName = "ccp-" + org + ".json";
  const ccpPath = path.join(process.cwd(), "ccpandcerts", jsonName);
  const read = fs.readFileSync(ccpPath, "utf-8");
  const ccp = JSON.parse(read);

  return ccp;
};

const getWalletPath = async (org) => {
  const walletname = org + "-wallet";
  const walletPath = path.join(process.cwd(), walletname);
  return walletPath;
};

const readCertificateintoWallet = async (org, username) => {
  const walletPath = await getWalletPath(org);
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  const user = await wallet.get(username);
  if (user) {
    var response = {
      success: true,
      message: username + " already read into wallet",
    };
    return response;
  }
  const JSONNAME = "client-cert-" + org + ".json";
  const CertNAME = org + "-client";
  const certpath = path.resolve(process.cwd(), "ccpandcerts", JSONNAME);
  const certread = fs.readFileSync(certpath, "utf-8");
  const certs = JSON.parse(certread);
  const PEMcert = certs.clients[CertNAME].certificate.pem;
  const privkey = certs.clients[CertNAME].certificate.private_key;

  const x509Identity = {
    credentials: {
      certificate: PEMcert,
      privateKey: privkey,
    },
    mspId: "buyerMSP",
    type: "X.509",
  };
  await wallet.put(username, x509Identity);
  var response = {
    success: true,
    message: username + " enrolled Successfully",
  };
  return response;
};

const buildWallet = async (Wallets, walletpath) => {
  let wallet;
  if (walletpath) {
    wallet = await Wallets.newFileSystemWallet(walletpath);
    console.log(`Built a file system wallet at ${walletpath}`);
  } else {
    wallet = await Wallets.newInMemoryWallet();
    console.log("Built an in memory wallet");
  }

  return wallet;
};

exports.readCertificateintoWallet = readCertificateintoWallet;
module.exports = {
  buildConnectionProfile: buildConnectionProfile,
  buildWallet: buildWallet,
  getWalletPath: getWalletPath,
  readCertificateintoWallet: readCertificateintoWallet,
};
