import * as grpc from "@grpc/grpc-js";
import * as crypto from "node:crypto";
import { connect, Identity, signers } from "@hyperledger/fabric-gateway";
import { promises as fs } from "node:fs";
import { TextDecoder } from "node:util";

const utf8Decoder = new TextDecoder();

async function main(): Promise<void> {
  const credentials = await fs.readFile(
    "/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp/signcerts/cert.pem"
  );
  const identity: Identity = { mspId: "buyerMSP", credentials };

  const privateKeyPem = await fs.readFile(
    "/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp/keystore/99394ddac6c7d30b2100be62e40c72bd77cc6af40ccddc3828ea210a0910798a_sk"
  );
  const privateKey = crypto.createPrivateKey(privateKeyPem);
  const signer = signers.newPrivateKeySigner(privateKey);

  const tlsRootCert = await fs.readFile(
    "/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/buyer-vm1/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-peers/b-peer0.buyer.GOnetwork.com/tls/tlscacerts/tls-localhost-7054-ca-buyer-GOnetwork-com.pem"
  );
  const client = new grpc.Client(
    "gateway.GOnetwork.com:1337",
    grpc.credentials.createSsl(tlsRootCert)
  );

  const gateway = connect({ identity, signer, client });
  try {
    const network = gateway.getNetwork("channelName");
    const contract = network.getContract("chaincodeName");

    const putResult = await contract.submitTransaction(
      "put",
      "time",
      new Date().toISOString()
    );
    console.log("Put result:", utf8Decoder.decode(putResult));

    const getResult = await contract.evaluateTransaction("get", "time");
    console.log("Get result:", utf8Decoder.decode(getResult));
  } finally {
    gateway.close();
    client.close();
  }
}

main().catch(console.error);
