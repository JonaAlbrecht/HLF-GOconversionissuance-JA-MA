The network setup was rolled back to the second design cycle state (plus the functionalities regarding cancellation, expiry and  verification that were added as part of the third cycle)

Lets start by navigating into the eproducer-client using: 

`docker exec -it eproducer-client bash`

We should immediately land in the directory that also all the bash scripts are stored.

We can use `ls` to get a list of all available scripts. 
First, lets obtain a list of all available GOs using: 

`./GetCurrenteGOList.sh`

We have to set the channel name command. The first time we bring up a network, this channel name is set to mychannel. The next time, you will have to define a different channel name during the channel creation process. therefore, because the channel name is a variable in the bash script, we have to pass the current channel name as an argument. 

This might return an empty list given that the Smart Meter cronjob is set such that an electricity GO is created only once a minute. so wait a little before you retry. 

Using `./ReadPubliceGO.sh eGO1` we can query the public information of the first created eGO. 

Using `./ReadPrivateElectricityGO.sh eGO1` we can query the private information of the first created eGO. 

To test that an unauthorized party couldnt access the private collection, lets go into the buyer container where the bash invocation scripts were parametrized such that we can enter the collection we would like to access, thereby being able to produce the access error. To this end, we need to first exit the eproducer container using `exit`

Enter the buyer-client container using `docker exec -it buyer-client bash`. 

From here, we can run for example `./ReadPrivateElectricityGO.sh eGO5 eproducerMSP` and this should return an error.

Lets head back to the eproducer-client using `exit` and then `docker exec -it eproducer-client bash`

In general, any of the scripts you see when doing `ls` can be called. To find out which parameters the script takes, navigate into e.g. the eproducer-client directory in eproducer-vm2, click on a script and see whether any of the environment variables takes $1, $2 and so on as inputs. If so, these scripts require the corresponding input value as parameter when the script is called. 
For example, ./TransferEGO.sh takes two inputs: the composite key of the GO to be transferred and the MSP name of the recipient. 

Using `./TransferEGO.sh eGO1 buyerMSP` we can transfer eGO1 to the buyer organisation and with `./TransferEGO.sh eGO1 hproducerMSP` to the hproducer organisation. 

Using `./TransferEGObyAmount.sh 100 buyerMSP` or  `./TransferEGObyAmount.sh 100 hproducerMSP` we can transfer a granular amount to the respective party. 

Lets now go into the hproducer container. To this end, we need to first exit the eproducer container using `exit`

Then we can run: `docker exec -it hproducer-client bash`

From within the hydrogen docker container, we can query the hydrogen backlog using: 

`./QueryHydrogenBacklog.sh`

We can also query that the correct GOs were transferred to us using `./ReadPrivateElectricityGO.sh eGO1`

If we have been transferred enough eGOs (e.g. assuming we have been transferred 100 Kwh), we can run the IssueHGO command with the amount of electricity input we would like to use: 
`./IssueHGO.sh 100`

we can query the issued hydrogen GO using:
`./ReadPublicHGO hGO1`

we can query the private information using: 
`./ReadPrivateHydrogenGO.sh hGO1`

We can query the created consumption declarations using:
`./ReadConsumptionDeclarationElectricity.sh eCon1`

Transfer it using `./TransferHGO.sh hGO1 eproducerMSP`

and also transfer by amount using `./TransferHGObyAmount.sh 100 eproducerMSP`

Lets go back to the eproducer client to try out the cancellation functions and see if our hydrogen GO and the associated consumption declarations were transferred. 

`./ReadPrivateHydrogenGO.sh hGO1`

`./ReadConsumptionDeclarationElectricity.sh eCon1`

We can cancel an amount of GOs using for example: 
`./ClaimRenewableattributesElectricity.sh 80`

We can read the cancellation statement using `ReadCancelStatementElectricity.sh eCancel1`





