# Create all the crypto material

## On virtual machine 1

cd into ../HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/create-cryptomaterial-issuer

Inside is a docker-compose.yaml and a bash script.

First we run the docker-compose file:

`docker-compose up -d`

This will create a docker container for the certificate authority (named ca.issuer.GOnetwork.com) of the issuing body. It will also create the crypto-material of the issuing body (folder called fabric-ca inside create-cryptomaterial-issuer) including the root certificate used to create all other identities in the network. The CA will be listening on port 7054. The public/private key of the CA are found under /fabric-ca/org1/msp/keystore/. We can check that the docker container is up using

`docker ps`

If docker-compose up returns an error "permission denied while trying to connect to the Docker daemon socket" you need to run the following commands to enable permission for non-root users:

`sudo groupadd docker`

`sudo usermod -aG docker $USER`

`newgrp docker`

And then rerun docker-compose. If the problem still persists you can try `reboot`

If you are re-running the project and you would like to delete the fabric-ca folder, you need to set permissions before deletion: `sudo chmod ugo+rwx /home/yourusername/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/create-cryptomaterial-issuer/fabric-ca`

**Then we run the bash script ./e-producer-org-certificates.sh**

`./issuer-org-certificates.sh`

The bash script creates the cryptomaterial for all users and peers in the issuing body organisation using the binary 'fabric-ca-client' from the fabric-samples. The script is similar to Fabric's crypogen tool, it will:

1. make directories (crypto-config) for all the cryptomaterial
2. enrolls ca.issuer.GOnetwork.com as the admin for this organisation providing the tls-cert.pem certificate
3. prints node organisation units into ../msp/config.yaml
4. uses fabric-ca-client binary to register peer0, peer1, user1 and admin user with the enrolled ca
5. generates msp and tls certificates for peer0, peer1, user1 and admin user

## Cryptomaterial for buyer org

`cd ../../buyer-vm1/create-cryptomaterial-buyer`

The cryptomaterial for the buyer organisation is created using the root certificates of the issuing body ca, i.e. in a real-world scenario, the certificates cannot be issued without this certificate. For the buyer, we enroll: an admin, 2 peers and one client which will later be used to run the client-side application for interacting with the network. Run the shell script:

`./buyer-org-certificates.sh`

## Cryptomaterial for e-producer

`cd ../../eproducer-vm2/create-cryptomaterial-eproducer`

The cryptomaterial for the electricity producer organisation is created using the root certificates of the issuing body ca, i.e. in a real-world scenario, the certificates cannot be issued without this certificate. For the eproducer, we enroll: an admin, 2 peers and one Smart Meter. To the Smart Meter certificate we add several attributes (see line 45 of the bash script) which will be used to authenticate input data sent by the Smart Meter to the smart contract.

`./create-cryptomaterial-eproducer.sh`

To see the attributes we enrolled, cd into the relevant folder in crypto-config:

`cd /home/jonalinux/HLF-GOconversionissuance-JA-MA/version1/setup1/eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp/signcerts`

And then run: `keytool -printcert -file cert.pem`
to check the attributes registered with the certificate.

## Cryptomaterial for h-producer

`cd ../../hproducer-vm5/create-cryptomaterial-hproducer`

The cryptomaterial for the hydrogen producer organisation is created using the root certificates of the issuing body ca. For the hydrogen producer, we enroll: an admin, 2 peers and one Output Meter. To the Output Meter certificate we add several attributes (see line 45 of the bash script) which will be used to authenticate input data sent by the Smart Meter to the smart contract.

`./create-cryptomaterial-hproducer.sh`

To see the attributes we enrolled, cd into the relevant folder in crypto-config:

`cd /home/jonalinux/HLF-GOconversionissuance-JA-MA/version1/setup1/eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp/signcerts`

And then run: `keytool -printcert -file cert.pem`
to check the attributes registered with the certificate.

## Create Channel Artifacts

We have to create the Genesis block and channel.tx file of the Blockchain before we join the different vms in the docker swarm network. Therefore, on each VM, we have to navigate into the orderer-vm4/create-cryptomaterial-orderer folder, run the docker container and create the cryptomaterial.
