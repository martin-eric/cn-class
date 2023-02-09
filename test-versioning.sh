SCRIPTV="0.1"
FILE=.swapoff
FILE2=.binariesdone
FILE3=.containerdworkarounddone

echo "Starting script version $SCRIPTV"

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Use SUDO " 2>&1
  exit 1
fi


## How to fix kubernetes cluster start-up after containerd updated on ubuntu repository
## version 1.59 does not play well with any kubernetes 1.2x version
## need to remove and download latest containerd binary from a difference repository, I decided to use docker repo
## To be done on both CP and worker nodes

#Add Docker’s official GPG key:

#sudo mkdir -p /etc/apt/keyrings
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

#Use the following command to set up the repository:

#echo \
#  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  

yes | sudo kubeadm reset

#Remove containerd if already installed

sudo apt-mark unhold containerd
sudo apt remove -y containerd
sudo rm -rf /etc/containerd/config.toml

#Install containerd from docker registry

VERSION=latest
sudo apt-get update 
sudo apt-get install -y --allow-downgrades containerd.io=$VERSION 
sudo apt-mark hold containerd.io

#Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

#Use sed to set SystemdCgroup to true
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml

#Restart containerd with the new configuration
sudo systemctl restart containerd

echo "containerd workaround applied installed.... You are ready to manually initialize the cluster."

VERSION=1.24.3-00
sudo apt-mark unhold kubelet kubeadm kubectl 
sudo apt-get install -y --allow-downgrades kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubeadm kubectl 

echo "Kubernetes binaries workaround applied installed.... You are ready to manually initialize the cluster."

touch .containerdworkarounddone
