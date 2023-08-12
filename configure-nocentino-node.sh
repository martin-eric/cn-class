#!/bin/bash

SCRIPTV="0.1"
FILE=.swapoff
FILE2=.binariesdone

echo "**********************************"
echo "Starting script version $SCRIPTV"
echo "**********************************"
echo
sudo echo

if [[ $EUID -eq 0 ]]; then
        echo "You cannot be a root user. " 2>&1
        exit 1
fi

if [ -f "$FILE" ]; then

    echo "Phase 1 COMPLETED. Continuing with Phase 2"

else

        # .swapoff file does not exist, start phase 1

    echo 
    echo 
    echo "Starting Phase 1"


read -p "Which Kube do you want to configure / create ? 1 or 2 or 3 or 4   --->   " choice

case $choice in
  1) echo "Perfect $choice" ;;
  2) echo "Perfect, OK $choice" ;;
  3) echo "Perfect, Nice $choice" ;;
  4) echo "Perfect, Nice $choice" ;;
  *) echo "Unrecognized selection: $choice" ; exit 1 ;;
esac

    
    
    sudo swapoff -a
    sudo sed -i  's/\/swap/#\/swap/' /etc/fstab
    
    echo "Cleaning up the hosts file"
    sudo sed -i '/my-ubuntu/d' /etc/hosts
    sudo echo "my-ubuntu-$choice" | sudo tee /etc/hostname
    echo "10.81.10.81 my-ubuntu-1 c1-cp1"  | sudo tee -a /etc/hosts
    echo "10.81.10.82 my-ubuntu-2 c1-node1"  | sudo tee -a /etc/hosts
    echo "10.81.10.83 my-ubuntu-3 c1-node2"  | sudo tee -a /etc/hosts
    echo "10.81.10.84 my-ubuntu-4 c1-node3 c1-storage"  | sudo tee -a /etc/hosts

    sudo sed -i "s/10.81.10.90/10.81.10.8$choice/g" /etc/netplan/50-cloud-init.yaml
 
    echo "editing sudoers"
    
    echo "ericsson ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ericsson
    
    echo
    
    echo "Turning off Auto Upgrade of Ubuntu"
    
    sudo sed -i 's/"1"/"0"/g;' /etc/apt/apt.conf.d/20auto-upgrades
    
    echo
    
    touch .swapoff

    echo "Rebooting ..... "
    sleep 5
    sudo reboot

fi

if [ -f "$FILE2" ] ; then

    echo "Binaries already installed (Phase 2)"

    echo "Starting Phase 3 ..."

    if [[ $(hostname) == "my-ubuntu-1" ]] || [[ $(hostname) == "c1-cp1" ]]; then
           
      echo "Look like the cluster binaries are installed, and executing on KUBE-1.... starting a new cluster for you... (Phase 3)"

      yes | sudo kubeadm reset && sudo kubeadm init --kubernetes-version v1.26.0 && sudo mkdir -p $HOME/.kube && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown ericsson:ericsson $HOME/.kube/config


      sleep 10
      
      echo
      
      echo "Installing Calico..."
      
      echo
      
      rm -rf calico* && wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml && kubectl apply -f ./calico.yaml

      echo && echo && echo "Cluster initialize completed. Your join command for your worker nodes is :" && echo && echo

      echo -n "sudo kubeadm reset -f ; sudo " && kubeadm token create --print-join-command
      
      touch .clusterstarted
        
      exit
    
    else
    
        echo "Binaries already installed (Phase 2), NOT ON KUBE-1, not attempting to start a new cluster"
        
        echo "Please add this node to the cluster with the join command provided by the control plane node"
        
        exit
    
    fi
    

else

    echo "Installing and configuring all the binaries needed for this node for a Kubernetes cluster"
    
    echo
    
    echo "Starting Phase 2"
    
    sleep 5

#Installing all binaries, including latest containerd from docker repo

#Install a container runtime - containerd
#containerd prerequisites, first load two modules and configure them to load on boot

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF


##Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

#Apply sysctl params without reboot
sudo sysctl --system

## How to fix kubernetes cluster start-up after containerd updated on ubuntu repository
## version 1.59 does not play well with any kubernetes 1.2x version
## need to remove and download latest containerd binary from a difference repository, I decided to use docker repo
## To be done on both CP and worker nodes

#Add Docker’s official GPG key:

sudo mkdir -p /etc/apt/keyrings
sudo rm -rf /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

#Use the following command to set up the repository:

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
#Remove containerd if already installed

sudo apt-mark unhold containerd
sudo apt remove -y containerd
sudo rm -rf /etc/containerd/config.toml

#Install containerd from docker registry
sudo apt-get update 
sudo apt-get install -y containerd.io
sudo apt-mark hold containerd.io

#Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

#You can use sed to swap in true
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml

#Restart containerd with the new configuration
sudo systemctl restart containerd

#Install Kubernetes packages - kubeadm, kubelet and kubectl
#Add Google's apt repository gpg key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

#Add the Kubernetes apt repository
sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

#Update the package list 
sudo apt-get update
#apt-cache policy kubelet | head -n 20 

#Install the required packages, if needed we can request a specific version. 
#Pick the same version you used on the Control Plane Node in 0-PackageInstallation-containerd.sh
VERSION=1.26.0-00
#VERSION=1.24.3-00

sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubeadm kubectl containerd.io

#Ensure both are set to start when the system starts up.
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service

echo
echo "kubernetes binaries all installed.... You are ready to manually initialize the cluster."
echo

touch .binariesdone

  if [[ $(hostname) == "my-ubuntu-1" ]]; then

        echo "Installing completion bash for Kubernetes..."

        sudo apt-get install -y bash-completion
        echo "source <(kubectl completion bash)" >> ~/.bashrc

  fi

echo

echo "If you want this script to initialize the cluster for you, launch it again and it will do the following for you: initialize it, set-up your kubectl, and process the calico file for you"

echo

fi


exit
