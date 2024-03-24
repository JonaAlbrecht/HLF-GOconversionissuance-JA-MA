# Create all the crypto material

## On virtual machine 1

cd into ../HLF-GOconversionissuance-JA-MA/version1/setup1/e-producer-vm1/create-cryptomaterial-e-producer

Inside is a docker-compose.yaml and a bash script. 

First we run the docker-compose file: 

```docker-compose up -d```

This will create a docker container for the certificate authority (named ca.org1.example.com) of the electricity producer organisation. The CA will be listening on port7054. The public/private key of the CA are found under /fabric-ca/org1/msp/keystore/. We can check that the docker container is up using 

```docker ps```

If docker-compose up returns an error "permission denied while trying to connect to the Docker daemon socket" you need to run the following commands to enable permission for non-root users: 

```sudo groupadd docker```

```sudo usermod -aG docker $USER```

```newgrp docker```

And then rerun docker-compose. If the problem still persists you can try ```reboot```

**Then we run the bash script ./e-producer-org-certificates.sh** 

```./e-producer-org-certificates.sh```

The bash script creates the cryptomaterial for all users and peers in the electricity producer organisation using the binary 'fabric-ca-client' from the fabric-samples. The script is similar to Fabric's crypogen tool, it will:
1. makes directories (crypto-config) for all the cryptomaterial
2. enrolls ca.org1.example.com as the admin for this organisation providing the tls-cert.pem certificate
3. prints node organisation units into ../msp/config.yaml
4. uses fabric-ca-client binary to register peer0, peer1, user1 and admin user with the enrolled ca
5. generates msp and tls certificates for peer0, peer1, user1 and admin user 

## On virtual machine 2

Navigate to ../HLF-GOconversionissuance-JA-MA/version1/setup1/buyer-vm2/create-cryptomaterial-buyer

Run the docker-compose file for vm2

```docker-compose up -d```

Run the bash script 

```./buyer-org-certificates.sh```

## On Virtual machine 3

Navigate to ../HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3/create-cryptomaterial-issuer

Run the docker-compose file for vm2

```docker-compose up -d```

Run the bash script 

```./issuer-org-certificates.sh```


# On Virtual machine 4

Navigate to ../HLF-GOconversionissuance-JA-MA/version1/setup1/orderer-vm4/create-cryptomaterial-orderer

Run the docker-compose file for vm2

```docker-compose up -d```

Run the bash script 

```./orderer-org-certificates.sh```



## Create Channel Artifacts

We have to create the Genesis block and channel.tx file of the Blockchain before we join the different vms in the docker swarm network. Therefore, on each VM, we have to navigate into the orderer-vm4/create-cryptomaterial-orderer folder, run the docker container and create the cryptomaterial. 