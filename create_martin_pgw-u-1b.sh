cd /home/ericsson/5gc_files_pkg/config/martin-pgw-pcg-1b/

kubectl create ns martin-pgw-pcg-1b
kubectl create -n martin-pgw-pcg-1b -f network.yaml
kubectl create -n martin-pgw-pcg-1b configmap martin-pgw-pcg-1b-eric-pcgup-data-plane-router-config --from-file=bird.conf
helm install -n martin-pgw-pcg-1b --namespace martin-pgw-pcg-1b -f values.yaml ~/PCG_1_Drop_13/eric-pc-gateway-1.6.1-1.tgz --version 1.6.0-4

