# Bring up the channel and commit the chaincode

## Bring up the channel

First, cd into the issuer-vm3 folder:

`cd /home/yourusername/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3`

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

`./deployChaincode.sh`
