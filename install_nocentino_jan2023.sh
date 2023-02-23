SCRIPTV="0.92"
FILE=.swapoff
FILE2=.binariesdone

echo "Starting script version $SCRIPTV"

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Use SUDO " 2>&1
  exit 1
fi

if [ -f "$FILE" ]; then

    echo "$FILE exists. Continue"

else

    echo "$FILE does not exist. Updating SWAP. RELAUNCH this script after reboot."
    sudo swapoff -a
    sudo sed -i  's/\/swap/#\/swap/' /etc/fstab
    touch .swapoff
    
    echo "Cleaning up the hosts file"
    sudo sed -i '/my-ubuntu/d' /etc/hosts
    echo "10.81.10.81 my-ubuntu-1 c1-cp1"  | sudo tee -a /etc/hosts
    echo "10.81.10.82 my-ubuntu-2 c1-node1"  | sudo tee -a /etc/hosts
    echo "10.81.10.83 my-ubuntu-3 c1-node2"  | sudo tee -a /etc/hosts
    echo "10.81.10.84 my-ubuntu-4 c1-node3 c1-storage"  | sudo tee -a /etc/hosts
    
    echo "Rebooting ..... "
    sleep 5
    sudo reboot

fi

if [ -f "$FILE2" ] ; then

    echo "Binaries already installed"

    if [[ $(hostname) == "my-ubuntu-1" ]]; then
           
      echo "$FILE2 exists. Look like the cluster binaries are installed, and executing on KUBE-1.... starting a new cluster for you..."

      yes | sudo kubeadm reset && sudo kubeadm init --kubernetes-version v1.24.3 && sudo mkdir -p $HOME/.kube && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown ericsson:ericsson $HOME/.kube/config

      wget https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml && kubectl apply -f ./calico.yaml

      echo && echo && echo "Cluster initialize completed. Your join command for your worker nodes is :" && echo && echo

      echo -n "sudo kubeadm reset ; sudo " && kubeadm token create --print-join-command
        
      exit
    
    else
    
        echo "Binaries already installed, NOT ON KUBE-1, not attempting to start a new cluster"
        
        echo "Please join this node to the cluster with the join command provided by the control plane node"
        
        exit
    
    fi
    

else

    echo "$FILE2 does not exist. Installing and configuring all the binaries needed for this node for a Kubernetes cluster"
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
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  #Use the following command to set up the repository:

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  #Remove containerd if already installed

  sudo apt-mark unhold containerd
  sudo apt remove -y containerd
  sudo rm -rf /etc/containerd/config.toml

  #Install containerd from docker registery

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
  VERSION=1.24.3-00
  sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
  sudo apt-mark hold kubelet kubeadm kubectl containerd.io

  #Ensure both are set to start when the system starts up.
  sudo systemctl enable kubelet.service
  sudo systemctl enable containerd.service

  echo "kubernetes binaries all installed.... You are ready to manually initialize the cluster."

  touch .binariesdone

  if [[ $(hostname) == "my-ubuntu-1" ]]; then

        echo "Installing completion bash for Kubernetes..."

        sudo apt-get install -y bash-completion
        echo "source <(kubectl completion bash)" >> ~/.bashrc

  fi

  echo "If you want this script initialize the cluster, launch it again and it will do the following for you: initialize it, set-up your kubectl, and process the calico file for you"

fi


exit
