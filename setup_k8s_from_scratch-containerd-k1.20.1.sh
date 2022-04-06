FILE=~/.rebooted

if [ -f "$FILE" ]; then
    echo "$FILE exists. Continue"
else
    echo "$FILE does not exist."
        #0 - Disable swap, swapoff then edit your fstab removing any entry for swap partitions
        #You can recover the space with fdisk. You may want to reboot to ensure your config is ok. 
        sudo swapoff -a
        sudo sed -i 's/^\/swap/#&/g' /etc/fstab
        touch ~/.rebooted
        sudo shutdown -r +0 "Rebooting.... Reconnect to this terminal in 1 min and redo the previous command..."
        exit

fi

###IMPORTANT####
#I expect this code to change a bit to make the installation process more streamlined.
#Overall, the end result will stay the same...you'll have continerd installed
#I will keep the code in the course downloads up to date with the latest method.
################


#0 - Install Packages 
#containerd prerequisites, first load two modules and configure them to load on boot
#https://kubernetes.io/docs/setup/production-environment/container-runtimes/
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF


#Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF


#Apply sysctl params without reboot
sudo sysctl --system


#Install containerd
sudo apt-get update 
sudo apt-get install -y containerd


#Create a containerd configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml


#Set the cgroup driver for containerd to systemd which is required for the kubelet.
#For more information on this config file see:
# https://github.com/containerd/cri/blob/master/docs/config.md and also
# https://github.com/containerd/containerd/blob/master/docs/ops.md

#At the end of this section
        #[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
        #...
#Add these two lines, indentation matters.
          #[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            #SystemdCgroup = true

#sudo vi /etc/containerd/config.toml


#Restart containerd with the new configuration
sudo systemctl restart containerd


#Install Kubernetes packages - kubeadm, kubelet and kubectl
#Add Google's apt repository gpg key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -


#Add the Kubernetes apt repository
sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'


#Update the package list and use apt-cache policy to inspect versions available in the repository
sudo apt-get update
apt-cache policy kubelet | head -n 20 


#Install the required packages, if needed we can request a specific version. 
#Use this version because in a later course we will upgrade the cluster to a newer version.
VERSION=1.20.1-00
sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubeadm kubectl containerd


#To install the latest, omit the version parameters
#sudo apt-get install kubelet kubeadm kubectl
#sudo apt-mark hold kubelet kubeadm kubectl containerd


#1 - systemd Units
#Check the status of our kubelet and our container runtime, containerd.
#The kubelet will enter a crashloop until a cluster is created or the node is joined to an existing cluster.
sudo systemctl status kubelet.service 
sudo systemctl status containerd.service 


#Ensure both are set to start when the system starts up.
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service

if [ $HOSTNAME == "my-ubuntu-1" ]

then

    echo "KUBE1 is detected, continue with control plane"

#0 - Creating a Cluster
#Create our kubernetes cluster, specify a pod network range matching that in calico.yaml! 
#Only on the Control Plane Node, download the yaml files for the pod network.
wget https://docs.projectcalico.org/manifests/calico.yaml


#Look inside calico.yaml and find the setting for Pod Network IP address range CALICO_IPV4POOL_CIDR, 
#adjust if needed for your infrastructure to ensure that the Pod network IP
#range doesn't overlap with other networks in our infrastructure.
#vi calico.yaml

##IMPORTANT UPDATE - 27 Dec 2022##
#kubeadm 1.22 removed the need to use the parameters --config=ClusterConfiguration.yaml and --cri-set /run/containerd/containerd.sock
#You can now just use kubeadm init to bootstrap the cluster

sudo kubeadm init | tee ~/.kinit

#Before moving on review the output of the cluster creation process including the kubeadm init phases, 
#the admin.conf setup and the node join command


#Configure our account on the Control Plane Node to have admin access to the API server from a non-privileged account.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo -n "sudo " > ~/.kjoin && cat ~/.kinit | egrep 'kubeadm join|discovery-token-ca-cert-hash' >> ~/.kjoin

#1 - Creating a Pod Network
#Deploy yaml file for your pod network.
kubectl apply -f calico.yaml


#Look for the all the system pods and calico pods to change to Running. 
#The DNS pod won't start (pending) until the Pod network is deployed and Running.
kubectl get pods --all-namespaces


#Get a list of our current nodes, just the Control Plane Node/Master Node...should be Ready.
kubectl get nodes 

echo "**** FINISHED ****"

echo "the join command on all worker nodes is " && cat ~/.kjoin

echo "**** FINISHED ****"

else

    echo "*** worker node detected, use the join command from the control plane output ***"

fi
