"use strict";

var { Gateway, Wallets } = require("fabric-network");
const path = require("path");
const FabricCAServices = require("fabric-ca-client");
const fs = require("fs");

const util = require("util");

const getCCP = async (org) => {
  let ccpPath;
  if (org == "buyer") {
    ccpPath = path.resolve(__dirname, "..", "config", "connection-buyer.json");
  } else if (org == "eproducer") {
    ccpPath = path.resolve(
      __dirname,
      "..",
      "config",
      "connection-eproducer.json"
    );
  } else if (org == "hproducer") {
    ccpPath = path.resolve(
      __dirname,
      "..",
      "config",
      "connection-hproducer.json"
    );
  } else return null;
  const ccpJSON = fs.readFileSync(ccpPath, "utf8");
  const ccp = JSON.parse(ccpJSON);
  return ccp;
};

const getCaUrl = async (org, ccp) => {
  let caURL;
  if (org == "buyer") {
    caURL = ccp.certificateAuthorities["ca.issuer.GOnetwork.com"].url;
  } else if (org == "eproducer") {
    caURL = ccp.certificateAuthorities["ca.issuer.GOnetwork.com"].url;
  } else if (org == "hproducer") {
    caURL = ccp.certificateAuthorities["ca.issuer.GOnetwork.com"].url;
  } else return null;
  return caURL;
};

const getWalletPath = async (org) => {
  let walletPath;
  if (org == "buyer") {
    walletPath = path.join(process.cwd(), "buyer-wallet");
  } else if (org == "eproducer") {
    walletPath = path.join(process.cwd(), "eproducer-wallet");
  } else return null;
  return walletPath;
};

const getAffiliation = async (org) => {
  return org == "buyer" ? "buyer.department1" : "eproducer.department1";
};

const getRegisteredUser = async (username, userOrg, isJson) => {
  let ccp = await getCCP(userOrg);

  const caURL = await getCaUrl(userOrg, ccp);
  const ca = new FabricCAServices(caURL);

  const walletPath = await getWalletPath(userOrg);
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  console.log(`Wallet path: ${walletPath}`);

  const userIdentity = await wallet.get(username);
  if (userIdentity) {
    console.log(
      `An identity for the user ${username} already exists in the wallet`
    );
    var response = {
      success: true,
      message: username + " enrolled Successfully",
    };
    return response;
  }

  // Check to see if we've already enrolled the admin user.
  let adminIdentity = await wallet.get("admin");
  if (!adminIdentity) {
    console.log(
      'An identity for the admin user "admin" does not exist in the wallet'
    );
    await enrollAdmin(userOrg, ccp);
    adminIdentity = await wallet.get("admin");
    console.log("Admin Enrolled Successfully");
  }

  // build a user object for authenticating with the CA
  const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
  const adminUser = await provider.getUserContext(adminIdentity, "admin");
  let secret;
  try {
    if (username == "superuser") {
      // Register the user, enroll the user, and import the new identity into the wallet.
      secret = await ca.register(
        {
          affiliation: "buyer.department1",
          enrollmentID: username,
          role: "client",
          attrs: [{ name: "role", value: "admin", ecert: true }],
        },
        adminUser
      );
    } else {
      secret = await ca.register(
        {
          affiliation: await getAffiliation(userOrg),
          enrollmentID: username,
          role: "client",
        },
        adminUser
      );
    }
  } catch (error) {
    return error.message;
  }

  let enrollment;
  if (username == "user1") {
    enrollment = await ca.enroll({
      enrollmentID: username,
      enrollmentSecret: secret,
      attr_reqs: [{ name: "role", optional: false }],
    });
  } else {
    enrollment = await ca.enroll({
      enrollmentID: username,
      enrollmentSecret: secret,
    });
  }

  let x509Identity;
  if (userOrg == "buyer") {
    x509Identity = {
      credentials: {
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
      },
      mspId: "buyerMSP",
      type: "X.509",
    };
  } else if (userOrg == "eproducer") {
    x509Identity = {
      credentials: {
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
      },
      mspId: "eproducerMSP",
      type: "X.509",
    };
  } else if (userOrg == "hproducer") {
    x509Identity = {
      credentials: {
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
      },
      mspId: "hproducerMSP",
      type: "X.509",
    };
  }

  await wallet.put(username, x509Identity);
  console.log(
    `Successfully registered and enrolled admin user ${username} and imported it into the wallet`
  );

  var response = {
    success: true,
    message: username + " enrolled Successfully",
  };
  return response;
};

const isUserRegistered = async (username, userOrg) => {
  const walletPath = await getWalletPath(userOrg);
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  console.log(`Wallet path: ${walletPath}`);

  const userIdentity = await wallet.get(username);
  if (userIdentity) {
    console.log(`An identity for the user ${username} exists in the wallet`);
    return true;
  }
  return false;
};

const getCaInfo = async (org, ccp) => {
  let caInfo;
  if (org == "buyer") {
    caInfo = ccp.certificateAuthorities["ca.buyer.GOnetwork.com"];
  } else if (org == "eproducer") {
    caInfo = ccp.certificateAuthorities["ca.issuer.GOnetwork.com"];
  } else if (org == "hproducer") {
    caInfo = ccp.certificateAuthorities["ca.issuer.GOnetwork.com"];
  } else return null;
  return caInfo;
};

const enrollAdmin = async (org, ccp) => {
  console.log("calling enroll Admin method");

  try {
    const caInfo = await getCaInfo(org, ccp);
    const caTLSCACerts = caInfo.tlsCACerts.pem;
    const ca = new FabricCAServices(
      caInfo.url,
      { trustedRoots: caTLSCACerts, verify: false },
      caInfo.caName
    );

    // Create a new file system based wallet for managing identities.
    const walletPath = await getWalletPath(org); //path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);

    // Check to see if we've already enrolled the admin user.
    const identity = await wallet.get("admin");
    if (identity) {
      console.log(
        'An identity for the admin user "admin" already exists in the wallet'
      );
      return;
    }

    // Enroll the admin user, and import the new identity into the wallet.
    const enrollment = await ca.enroll({
      enrollmentID: "admin",
      enrollmentSecret: "adminpw",
    });
    let x509Identity;
    if (org == "buyer") {
      x509Identity = {
        credentials: {
          certificate: enrollment.certificate,
          privateKey: enrollment.key.toBytes(),
        },
        mspId: "buyerMSP",
        type: "X.509",
      };
    } else if (org == "eproducer") {
      x509Identity = {
        credentials: {
          certificate: enrollment.certificate,
          privateKey: enrollment.key.toBytes(),
        },
        mspId: "eproducerMSP",
        type: "X.509",
      };
    }

    await wallet.put("admin", x509Identity);
    console.log(
      'Successfully enrolled admin user "admin" and imported it into the wallet'
    );
    return;
  } catch (error) {
    console.error(`Failed to enroll admin user "admin": ${error}`);
  }
};

const registerAndGetSecret = async (username, userOrg) => {
  let ccp = await getCCP(userOrg);

  const caURL = await getCaUrl(userOrg, ccp);
  const ca = new FabricCAServices(caURL);

  const walletPath = await getWalletPath(userOrg);
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  console.log(`Wallet path: ${walletPath}`);

  const userIdentity = await wallet.get(username);
  if (userIdentity) {
    console.log(
      `An identity for the user ${username} already exists in the wallet`
    );
    var response = {
      success: true,
      message: username + " enrolled Successfully",
    };
    return response;
  }

  // Check to see if we've already enrolled the admin user.
  let adminIdentity = await wallet.get("admin");
  if (!adminIdentity) {
    console.log(
      'An identity for the admin user "admin" does not exist in the wallet'
    );
    await enrollAdmin(userOrg, ccp);
    adminIdentity = await wallet.get("admin");
    console.log("Admin Enrolled Successfully");
  }

  // build a user object for authenticating with the CA
  const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
  const adminUser = await provider.getUserContext(adminIdentity, "admin");
  let secret;
  try {
    // Register the user, enroll the user, and import the new identity into the wallet.
    secret = await ca.register(
      {
        affiliation: await getAffiliation(userOrg),
        enrollmentID: username,
        role: "client",
      },
      adminUser
    );
    // const secret = await ca.register({ affiliation: 'buyer.department1', enrollmentID: username, role: 'client', attrs: [{ name: 'role', value: 'approver', ecert: true }] }, adminUser);
  } catch (error) {
    return error.message;
  }

  var response = {
    success: true,
    message: username + " enrolled Successfully",
    secret: secret,
  };
  return response;
};

exports.getRegisteredUser = getRegisteredUser;

module.exports = {
  getCCP: getCCP,
  getWalletPath: getWalletPath,
  getRegisteredUser: getRegisteredUser,
  isUserRegistered: isUserRegistered,
  registerAndGetSecret: registerAndGetSecret,
};
