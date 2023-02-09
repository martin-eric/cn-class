SCRIPTV="0.3"
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

VERSION=1.6.4-1
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

VERSION=1.26.1-00
sudo apt-mark unhold kubelet kubeadm kubectl 
sudo apt-get install -y --allow-downgrades kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubeadm kubectl 

echo "Kubernetes binaries workaround applied installed.... You are ready to manually initialize the cluster."

touch .containerdworkarounddone


    if [[ $(hostname) == "my-ubuntu-1" ]]; then
    
        echo "On Kube-1, continuing..."
        
            echo "Look like the cluster binaries are installed, and executing on KUBE-1.... starting the cluster for you..."
    
    yes | sudo kubeadm reset && sudo kubeadm init && sudo mkdir -p $HOME/.kube && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown ericsson:ericsson $HOME/.kube/config
    
    # kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
    
    kubectl apply -f ./pod.yaml
    
    echo && echo && echo "Cluster initialize completed. Your join command for your worker nodes is :" && echo && echo
    
    echo -n "yes | sudo kubeadm reset ; sudo " && kubeadm token create --print-join-command
    
    else
    
        echo "NOT ON KUBE-1, exitting..." 
           
    fi
    
kubeadm version
ctr version
crictl -v
    
    exit
