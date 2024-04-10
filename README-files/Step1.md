## 1. Installing all Prequisites, Fabric-Sample, Binaries and Docker Images

Im using docker version 25.0.4, docker-compose version 1.26.2, go 1.22.1, npm 10.2.4, python 2.7.18

Open a terminal on your WSL:Ubuntu connection. We now need to install all the prerequisites:

`sudo apt-get install curl`
`sudo apt-get install nodejs`
`sudo apt-get install npm`

**Docker**

Im using the "install using the apt repository" method from the [Docker documentation](https://docs.docker.com/engine/install/ubuntu/) to install docker

`sudo apt-get update`
`sudo apt-get install ca-certificates curl`
`sudo install -m 0755 -d /etc/apt/keyrings`

`sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc`

`sudo chmod a+r /etc/apt/keyrings/docker.asc`

In this next command, make sure there are no line-breaks when copying it into the terminal

`echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`

`sudo apt-get update`

`sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`

`docker --version`
`docker-compose --version`

**Golang Installation**

We cant follow the normal [installation method](https://go.dev/doc/install) of downloading the tar ball onto our machine bc we are in a virtual environment. This command downloads the appropriate tar ball and installs it:

`wget -c https://go.dev/dl/go1.22.1.linux-amd64.tar.gz -O - | tar -xz`

You can install go into /usr/local (recommended) or into /home/yourusername/

We need to set the GOPATH to the Go-Folder. Put the following lines into both your .bashrc and your .profile file, which configure the terminal.

`sudo nano ~/.profile`

and then add the below lines into the ~/.profile file.

`export GOPATH=usr/local/go`

`export PATH=$PATH:/usr/local/go/bin`

Since later on we will need this as well, also add this line to .bashrc:

`export PATH="/usr/local/go/src/github.com/fabric/fabric-samples/bin:$PATH"`

And then add the above lines into the ~/.bashrc file:

`sudo nano ~/.bashrc`

As you can see, we will be installing the fabric samples and the fabric binaries into the go folder and we will also download the git repo into the go folder. This is because the Smart Contract written in GO initializes correctly (initializes its relative dependencies) only if it is inside the GOPATH.

**Fabric-Samples repo, Binaries and Docker Images**

I follow the installation process in the [Fabric Documentation](https://hyperledger-fabric.readthedocs.io/en/latest/install.html).

cd into the go/src folder: `cd /usr/local/go/src` and make a directory github.com `mkdir github.com` and then make a directory fabric `mkdir fabric`. Then: `cd fabric`

From within this folder, get the install script by running:

`curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh`

Run without any flag to install all docker images, binaries and the samples repository:

`./install-fabric.sh`

**The [Fabric Documentation](https://hyperledger-fabric.readthedocs.io/en/latest/index.html) provides excellent tutorials on how to use the fabric-samples.**

# Download google-chrome for Linux Ubuntu VM

If you are running a Linux VM on a Windows machine, you will need to download the google chrome browser to access the applications (i.e. CouchDB and the client application) under this [LINK](https://linuxize.com/post/how-to-install-google-chrome-web-browser-on-ubuntu-20-04/). Open the google browser from the command line with `google-chrome-stable`.

When running applications, do not click on the little pop-up in the bottom-left "Your application is running on port X" to open the application. Instead open a new terminal window, open google chrome with `google-chrome-stable` and then type in http://localhost:PORTNUMBER

# Clone the GO conversion issuance repo

Lets clone the repo into /home/yourusername/go/src. Either, make a fork of the repo and then download or download the repo directly. You need to have git installed. Go to the repo and copy the http address. From /usr/local/go/src/github.com run:

`git clone https://github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA.git`
