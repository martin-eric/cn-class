yes | sudo kubeadm reset
sudo systemctl stop kubelet
sudo rm -rf /var/lib/cni/
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /etc/cni/
sudo ifconfig cni0 down
sudo ifconfig flannel.1 down
sudo ifconfig docker0 down
sudo ip link delete cni0
sudo ip link delete flannel.1
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F 
sudo iptables -X
