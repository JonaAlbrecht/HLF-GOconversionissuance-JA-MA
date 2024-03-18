## 2. Installing all Prequisites, Fabric-Sample, Binaries and Docker Images 

Im using docker version 25.0.4, docker-compose version 1.26.2, go 1.22.1, npm 10.2.4, python 2.7.18

Open the remote connection to VM1 in VS code (in the bottom left it should say: "SSH:vm1"). And open a terminal. We now need to install all the prerequisites on the VM. 

```sudo apt-get install curl```
```sudo apt-get install nodejs```
```sudo apt-get install npm```
```sudo apt-get install python```

**Docker**

Im using the "install using the apt repository" method from the [Docker documentation](https://docs.docker.com/engine/install/ubuntu/) to install docker

```sudo apt-get update```
```sudo apt-get install ca-certificates curl```
```sudo install -m 0755 -d /etc/apt/keyrings```

```sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc```

```sudo chmod a+r /etc/apt/keyrings/docker.asc```

```  
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```sudo apt-get update```

```sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin```

```docker --version```
```docker-compose --version```

**Golang Installation**

We cant follow the normal [installation method](https://go.dev/doc/install) of downloading the tar ball onto our machine bc we are in VM. This command downloads the appropriate tar ball onto the VM and installs it: 


```wget -c https://go.dev/dl/go1.22.1.linux-amd64.tar.gz -O - | tar -xz```

Move go into usr/local with following command such that our path points at the correct place. Otherwise you can also change the GOPATH below to /home/username/go

```sudo mv go/ /usr/local```

Now add the following lines into the .bashrc file (/home/username/.bashrc) which configures the terminal. 

```export GOPATH=/usr/local/go*```

```export PATH=$PATH:$GOPATH/bin```

Since we will need this as well, also add this line to .bashrc:

```export PATH="/home/yourusername/fabric-samples/bin:$PATH"*```


**Fabric-Samples repo, Binaries and Docker Images**

I follow the installation process in the [Fabric Documentation](https://hyperledger-fabric.readthedocs.io/en/latest/install.html).

Get the install script: 

```curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh```

Run without any flag to install all docker images, binaries and the samples repository: 

```./install-fabric.sh```


**The [Fabric Documentation](https://hyperledger-fabric.readthedocs.io/en/latest/index.html) provides excellent tutorials on how to use the fabric-samples.**



# Creating the other VMs 





