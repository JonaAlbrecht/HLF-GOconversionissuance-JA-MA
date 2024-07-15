# Bringing up the network

As of the second design cycle, the network could be brought up and down using the network-up and network-down bash scripts. As part of the third design cycle, the convenience script had to be split into two parts.  

Cd into /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/
First, we need to set some docker permissions: 

`sudo groupadd docker`

`sudo usermod -aG docker $USER`

`newgrp docker`


Run `./network-upsplit1.sh`to bring up the network. Now, navigate into the crypto material of the orderer, to: usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/keystore/ 
Right-click on the name of the privatekey file, choose the option "Copy Path", navigate in the file explorer (not in the terminal) to artifacts/channel/create-artifacts.sh, click on the file and replace the value of the first environment variable, i.e. export ORDERER_ADMIN_TLS_PRIVATE_KEY=, with the value of the path you just copied. 

Now, execute `./network-upsplit2.sh`. Whenever you bring up the network, you will need to repeat this step of posting the orderer admin private key

The last step that should have been executed is "Setting anchor peer for issuer", please check a little bit that none of the steps here returned an error. Next, we will deploy and commit the chaincode. Please switch to the deploying and committing the chaincode md file next. The below explanations are only necessary when you bring up the network a second time.   

Once you are finished testing, bring the network back down using `./network-down.sh` If docker-compose up returns an error "permission denied while trying to connect to the Docker daemon socket" you need to run the commands listed in the "run docker compose file" section and you should also install the Docker VS code extension

For the first channel, you do not need to update the channel name. If you bring up a second channel (even after deleting the first one) you need to set the channel environment variable to a new channel name. To do this find the line saying `export CHANNEL_NAME=mychannel` and change mychannel to e.g. mychannel1. This needs to be done in the network-upsplit1.sh and network-upsplit2.sh scripts, in the deployChaincode.sh script in issuer-vm3, in the execute.sh script of issuer-vm3/SmartMeter-config, in the execute-hproducer.sh script of issuer-vm3/OutputMeter-config, in the installAndApproveChaincode.sh script of hproducer-vm5,  in the installAndApproveChaincode.sh script of eproducer-vm2 and in the installAndApproveChaincode.sh script of buyer-vm1.

When bringing this new channel down, make sure to set `export CHANNEL_NAME=mychannel` also equal to the channel name you just worked with in the network-down.sh script.  

If you would like to understand the network setup in more detail, follow the below steps and look at the involved files.

If you bring up the network step-by-step following the below steps, do not also bring up the network using the convenience script

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

Next lets create the Channel Artifacts. To do so, given that in the third design cycle, we bring up the channel using the osnadmin command, we first need to cd into the orderer-vm4 directory and run `docker-compose up -d`

Next, we want to do `cd ../../../artifacts/channel`. in the file explorer, navigate into the crypto material of the orderer, to: usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/crypto-config/ordererOrganizations/GOnetwork.com/users/Admin@GOnetwork.com/tls/keystore/ 
Right-click on the name of the privatekey file, choose the option "Copy Path", navigate in the file explorer to artifacts/channel/create-artifacts.sh, click on the file and replace the value of the first environment variable, i.e. export ORDERER_ADMIN_TLS_PRIVATE_KEY=, with the value of the path you just copied.

We run the create-artifacts bash script.

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



## Bring up the channel

First, cd into the issuer-vm3 folder:

`cd /usr/local/go/src/github.com/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3`

We need to run the createChannel.sh bash script to create the channel.
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

Now, we need to set the anchor peers. To this end do

`cd /usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/artifacts/channel/buyerAnchor`

and execute `./AnchorUpdatebuyer.sh`

then `cd ../eproducerAnchor` and execute `./AnchorUpdateeproducer.sh`

then `cd ../hproducerAnchor` and execute `./AnchorUpdatehproducer.sh`

then `cd ../issuerAnchor` and execute `./AnchorUpdateissuer.sh`


**Troubleshooting**

`docker ps` should show you 23 docker containers. Run `docker ps -a` and see in the "Status" column whether any docker containers have status "exited with...". If that is so, try bringing up the specific docker container again with `docker container restart CONTAINER_ID`

Try bringing down the entire network, removing all containers and then restart from the beginning of the step 'Bring up the peer and couchDB containers'

`docker stop $(docker ps -a -q)`and then
`docker remove $(docker ps -a -q)` and maybe even:
`docker image prune`

You can also try removing the Docker images entirely:

`docker image ls` and then copy the image name into:
`docker rmi IMAGE_NAME`


**Looking at some of the ports**

Open a new terminal and open a google-chrome instance with `google-chrome-stable` (this is necessary assuming you are using a WSL Ubuntu VM on Windows). If your native system is linux, it might suffice to just open google chrome.

You can only look at ports running couchDB, a peer node port will not return anything (try it out by typing e.g. http://localhost:7051)
To look at CouchDB, type into the google search bar http://localhost:6984 to look at couchdb1 instance from buyer organisation
Or http://localhost:12984 to look at couchdb7 instance from hproducer organisation