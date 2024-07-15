As mentioned, as a result of the third design cycle, all application bash scripts have the channel name added as an additional parameter.

Lets start by navigating into the eproducer-client using: 

`docker exec -it eproducer-client bash`

We should immediately land in the directory that also all the bash scripts are stored.

We can used `ls` to get a list of all available scripts. 
First, lets obtain a list of all available GOs using: 

`./GetCurrenteGOList.sh mychannel`

We have to set the channel name command. The first time we bring up a network, this channel name is set to mychannel. The next time, you will have to define a different channel name during the channel creation process. therefore, because the channel name is a variable in the bash script, we have to pass the current channel name as an argument. 

This might return an empty list given that the Smart Meter cronjob is set such that an electricity GO is created only once a minute. so wait a little before you retry. 

Using `./ReadPubliceGO.sh mychannel eGO1` we can query the public information of the first created eGO. 

Using `./ReadPrivateElectricityGO.sh mychannel eGO1` we can query the private information of the first created eGO. 

Using `./TransferEGO.sh mychannel eGO1 buyerMSP` we can transfer eGO1 to the buyer organisation and with `./TransferEGO.sh mychannel eGO1 hproducerMSP` to the hproducer organisation. 