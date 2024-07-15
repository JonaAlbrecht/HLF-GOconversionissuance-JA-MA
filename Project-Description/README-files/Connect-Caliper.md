Mostly, the below steps follow the caliper tutorial found here: [Caliper Tutorial](https://hyperledger.github.io/caliper/v0.6.0/fabric-tutorial/tutorials-fabric-existing/)

First, we need to cd into `cd /usr/local/go/src/github.com/JonaAlbrecht` and here `mkdir caliper-workspace`

within the caliper-workspace folder, create three folders named networks, benchmarks, and workload respectively

Install the Caliper CLI using `npm install --only=prod @hyperledger/caliper-cli@0.6.0`
this might suggest to you to run `sudo npm install -g npm@10.8.1` to upgrade some dependencies

Then bind the caliper software development kit to the fabric environment using: 

`npx caliper bind --caliper-bind-sut fabric:fabric-gateway`


Copy the bench-config.yaml into the benchmarks folder, the network-config.yaml into the networks folder, the connection-profiles folder also into the networks folder, and the CONTENT of the functions folder (not the functions folder itself) into the workload folder. Copy the crypto-config folder from the testing folder into the caliper-workspace, navigate to /usr/local/go/src/github.com/JonaAlbrecht/caliper-workspace/crypto-config/peerOrganizations/buyer.GOnetwork.com/b-users/Admin@buyer.GOnetwork.com/msp/keystore/privatekeyname' and copy that path into the network-config file in the section containing the path to the client private key

Then execute: 

`npx caliper launch manager --caliper-workspace ./ --caliper-networkconfig networks/network-config.yaml --caliper-benchconfig benchmarks/bench-config.yaml --caliper-flow-only-test`