## 6.13 

sudo kubeadm init --pod-network-cidr=10.244.0.0/16
#sudo kubeadm init --pod-network-cidr=172.16.0.0/16
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl apply -f https://raw.githubusercontent.com/intel/multus-cni/v3.2/images/multus-daemonset.yml
kubectl apply -f https://raw.githubusercontent.com/intel/multus-cni/v3.2/images/flannel-daemonset.yml
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

## 6.14

kubectl apply -f ~/5gc_files_pkg/config/rp-eccd-1/metallb.yaml

## 6.15
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'


## 6.16
kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/v0.35.0/deploy/addons/storageclass/storageclass.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/v0.35.0/deploy/addons/storage-provisioner/storage-provisioner.yaml

## 6.21
cd /home/ericsson/PCC_1_Drop_13/host-setup
sudo apparmor_parser -r -W apparmor-docker-pcc
sudo cp host-local-pcc /opt/cni/bin/host-local-pcc
sudo chmod a+x /opt/cni/bin/host-local-pcc
cd



