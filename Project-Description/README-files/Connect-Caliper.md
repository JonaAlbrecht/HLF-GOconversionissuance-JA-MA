Mostly, the below steps follow the caliper tutorial found here: [Caliper Tutorial](https://hyperledger.github.io/caliper/v0.6.0/fabric-tutorial/tutorials-fabric-existing/)

First, we need to cd into `cd /usr/local/go/src/github.com/JonaAlbrecht` and here `mkdir caliper-workspace`

within the caliper-workspace folder, create three folders named networks, benchmarks, and workload respectively

Install the Caliper CLI using `npm install --only=prod @hyperledger/caliper-cli@0.6.0`
this might suggest to you to run `sudo npm install -g npm@10.8.1` to upgrade some dependencies

Then bind the caliper software development kit to the fabric environment using: 

`npx caliper bind --caliper-bind-sut fabric:fabric-gateway`
