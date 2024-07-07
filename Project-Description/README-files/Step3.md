# Deploying and committing the Chaincode

Unfortunately, the next few steps could not be included into the convenience script because for some reason, artificially setting the current working directory does not work for the peer chaincode install command and this command can only be executed from the correct working directory (i.e the directory, the shell script invoking the command is actually in). 

Assuming you are currently in: /usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1 do 

`cd issuer-vm3`

`./deployChaincode.sh`

IF you receive the error: "gopath entry is relative; must be absolute path" you need to navigate back to your .bashrc and .profile files and delete the line export GOPATH=usr/local/go. 

Now lets install the chaincode on the peers of the other organisations: 

`cd ../buyer-vm1`

`./installAndApproveChaincode.sh`

`cd ../eproducer-vm2`

`./installAndApproveChaincode.sh`

`cd ../hproducer-vm5`

`./installAndApproveChaincode.sh`

Having installed the chaincode on one peer per organisation and each organisation having approved the chaincode definition, the issuer organisation now commits this chaincode definition to the ledger. To this end, we need to enter the issuer-client (Command line interface) by running:

`docker exec -it issuer-client bash`

If this returns a permission denied error we need to re-run the docker permission commands from the last section: 

