# Bringing up the network

The network can be brought up and down using the network-up and network-down bash scripts. For a more detailed step-by-step guide on bringing up the network, follow the instructions on the rest of this page. **If you use the network-up script to bring up the network, do not execute any of the below commands** 

Cd into /usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/
Run `./network-up.sh`to bring up the network. Once you are finished testing, bring the network back down using `./network-down.sh`

## Create all the crypto material

cd into /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/create-cryptomaterial-issuer

Inside is a docker-compose.yaml and a bash script.

**First we run the docker-compose file:**

`docker-compose up -d`

This will create a docker container for the certificate authority (named ca.issuer.GOnetwork.com) of the issuing body. By Certificate Authority (CA), I am referring to the CA concept from the Hyperledger framework, given that the term is also used in the guarantee of origin space. The docker-compose up command will also create the crypto-material of the issuing body including the root certificate. After running docker-compose, this cryptomaterial can be found in ../create-cryptomaterial-issuer/fabric-ca as well as in the docker container. The CA container will be listening on port 7054. The public/private key of the CA are found under ../create-cryptomaterial-issuer/fabric-ca/org1/msp/keystore/. We use the -d flag (d referring to detached) such that our docker container runs in the background (as a daemon), similar to a server and doesnt obstruct our bash terminal execution.

We can check that the docker container is up using

`docker ps`

If docker-compose up returns an error "permission denied while trying to connect to the Docker daemon socket" you need to run the following commands to enable permission for non-root users:

`sudo groupadd docker`

`sudo usermod -aG docker $USER`

`newgrp docker`

And then rerun docker-compose. If the problem still persists you can try `reboot`

If you are re-running the project and you would like to delete the fabric-ca folder, you need to set permissions before deletion: `sudo chmod ugo+rwx /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/create-cryptomaterial-issuer/fabric-ca`

**Then we run the bash script ./issuer-org-certificates.sh**

`./issuer-org-certificates.sh`

The bash script creates the cryptomaterial for all users and peers in the issuing body organisation using the binary 'fabric-ca-client' from the fabric-samples. The script is similar to Fabric's crypogen tool, it will:

1. make directories (crypto-config) for all the cryptomaterial
2. enroll ca.issuer.GOnetwork.com as the certificate authority for this organisation providing the tls-cert.pem certificate
3. prints node organisation units into ../msp/config.yaml
4. uses fabric-ca-client binary to register peer0, peer1, user and admin user with the enrolled ca
5. generates msp and tls certificates for peer0, peer1, user and admin user

## Cryptomaterial for buyer org

From the current directory (../issuer-vm3/create-cryptomaterial-issuer) cd to the buyer directory using:

`cd ../../buyer-vm1/create-cryptomaterial-buyer`

The cryptomaterial for the buyer organisation is created using the root certificates of the issuing body ca. In a real-world scenario, the issuing body would generate this cryptomaterial and then send it to the buyer organisation via TLS-secured communication. Here, we are deploying on a single virtual machine. For the buyer, we enroll: an admin, 2 peers and one client which will later be used to run the client-side Nodejs application for interacting with the network. Run the shell script:

`./buyer-org-certificates.sh`

## Cryptomaterial for e-producer

`cd ../../eproducer-vm2/create-cryptomaterial-eproducer`

The cryptomaterial for the electricity producer organisation is created using the root certificates of the Issuing Body CA. In a real-world scenario, the issuing body would generate this cryptomaterial and then send it to the electricity producer organisation via TLS-secured communication. For the eproducer, we enroll: an admin, 2 peers and one Smart Meter. To the Smart Meter certificate we add several attributes (see line 45 of the bash script) which will be used to authenticate input data sent by the Smart Meter to the smart contract (attribute-based access control functions implemented using the pkg/cid/ClientIdentity Golang library from Hyperledger Fabric). Run the bash script:

`./create-cryptomaterial-eproducer.sh`

To see the attributes we enrolled, cd into the relevant folder in crypto-config:

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/eproducer-vm2/crypto-config/peerOrganizations/eproducer.GOnetwork.com/SmartMeter/SmartMeter1@eproducer.GOnetwork.com/msp/signcerts`

And then run: `keytool -printcert -file cert.pem`
to check the attributes registered with the certificate.

## Cryptomaterial for h-producer

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/hproducer-vm5/create-cryptomaterial-hproducer`

The cryptomaterial for the hydrogen producer organisation is created using the root certificates of the Issuing Body CA. For the hydrogen producer, we enroll: an admin, 2 peers and one Output Meter. To the Output Meter certificate we add several attributes (see line 45 of the bash script) which will be used to authenticate input data sent by the Smart Meter to the smart contract. Run the bash script:

`./create-cryptomaterial-hproducer.sh`

To see the attributes we enrolled, cd into the relevant folder in crypto-config:

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/hproducer-vm5/crypto-config/peerOrganizations/hproducer.GOnetwork.com/OutputMeter/OutputMeter1@hproducer.GOnetwork.com/msp/signcerts`

And then run: `keytool -printcert -file cert.pem`
to check the attributes registered with the certificate.

## Cryptomaterial Orderer

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/create-cryptomaterial-orderer`

The orderer organisation has its own Certificate Authority. This is to signalize that the orderer organization is independent even from the Issuing Bodies and truly under the control of the Blockchain consortium. The effect on decentralisation is minimal and the orderer cryptomaterial could just as much have been generated with the Issuing Body CA, however, different from the cryptomaterial of other organisations it doesnt NEED to.

We run:

`docker-compose up -d`

And then execute the bash script:

`./orderer-org-certificates.sh`

## Create Channel Artifacts

Next lets create the Channel Artifacts

`cd ../../../artifacts/channel`

We run the create-artifacts bash script. This will:

1. Generate the System Genesis block using the configtxgen tool with the orderergenesis profile from the configtx.yaml file and output a genesis.block file
2. Generate the channel configuration block and set the anchor peers (Peer 0) for each organisation

`./create-artifacts.sh`

## Creating the SmartMeter and Output Meter docker images

The Smart Meter and Output Meter docker containers simulate connected IoT devices sending verifiable data to the chain. Their certificates are issued as part of the issuer certificates, and the specific functions they invoke in the Smart Contract "CreateElectricityGO" and "AddHydrogentoBacklog" are protected by attribute-based access control such that they can only be invoked by them. To create the SmartMeter docker image we need to build the Smart Meter docker file which is in /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/SmartMeter-config. 

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/SmartMeter-config`

`docker build -t smartmeter .`

To create the Output Meter docker image: 

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/OutputMeter-config`

`docker build -t outputmeter .`

The SmartMeter and OutputMeter docker containers are brought up together with the other issuer docker containers in the docker-compose up command in the next step, using the created images. To view their configuration, see the docker-compose.yaml file in HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3` Aside from their custom docker image, their remaining configuration is similar to a client container, however

## Bring up the peer and couchDB containers

`cd ../../setup1/issuer-vm3`

`docker-compose up -d`

The first time it is run, this command will pull the fabric Docker images from the Docker hub (fabric-couchdb, fabric-peer)

`cd ../buyer-vm1`

`docker-compose up -d`

`cd ../eproducer-vm2`

`docker-compose up -d`

`cd ../hproducer-vm5`

`docker-compose up -d`

`cd ../orderer-vm4`

`docker-compose up -d`

This last command is going to pull the fabric-orderer Docker image from Docker hub.

**Looking at some of the ports**

Open a new terminal and open a google-chrome instance with `google-chrome-stable` (this is necessary assuming you are using a WSL Ubuntu VM on Windows). If your native system is linux, it might suffice to just open google chrome.

You can only look at ports running couchDB, a peer node port will not return anything (try it out by typing e.g. http://localhost:7051)
To look at CouchDB, type into the google search bar http://localhost:6984 to look at couchdb1 instance from buyer organisation
Or http://localhost:12984 to look at couchdb7 instance from hproducer organisation

**Creating the SmartMeter and OutputMeter**



## Bring up the channel

First, cd into the issuer-vm3 folder:

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3`

We need to run the createChannel.sh bash script to create the channel. It is the Issuing Body which creates the Channel.
The Script sets a number of environment variables and then uses the fabric commands 'peer channel create', 'peer channel join' and 'peer channel update' that are part of the fabric-binaries we downloaded at the beginning

`./createChannel.sh`

If you would like to look at the commands step by step (e.g. just execute peer channel create first) comment out the invocations of the bash functions 'joinChannel' and 'updateAnchorPeers' with the #

Now, lets join all other organisations to the channel:

`cd ../buyer-vm1`

`./joinChannel.sh`

`cd ../eproducer-vm2`

`./joinChannel.sh`

`cd ../hproducer-vm5`

`./joinChannel.sh`

## Deploy the chaincode

Next, lets deploy the chaincode from the issuing body directory. It is the issuing body that deploys the chaincode but approval from all organisations is needed.

`cd ../issuer-vm3`

Comment out the invocation of all functions after approveformyorg if not already the case.

`./deployChaincode.sh`

`cd ../buyer-vm1`

`./installAndApproveChaincode.sh`

`cd ../eproducer-vm2`

`./installAndApproveChaincode.sh`

`cd ../hproducer-vm5`

`./installAndApproveChaincode.sh`


**Troubleshooting**

`docker ps` should show you 23 docker containers. Run `docker ps -a` and see in the "Status" column whether any docker containers have status "exited with...". If that is so, try bringing up the specific docker container again with `docker container restart CONTAINER_ID`

Try bringing down the entire network, removing all containers and then restart from the beginning of the step 'Bring up the peer and couchDB containers'

`docker stop $(docker ps -a -q)`and then
`docker remove $(docker ps -a -q)` and maybe even:
`docker image prune`

You can also try removing the Docker images entirely:

`docker image ls` and then copy the image name into:
`docker rmi IMAGE_NAME`

