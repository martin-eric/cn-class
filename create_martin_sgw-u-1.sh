cd /home/ericsson/5gc_files_pkg/config/martin-sgw-pcg-1/

kubectl create ns martin-sgw-pcg-1
kubectl create -n martin-sgw-pcg-1 -f network.yaml
kubectl create -n martin-sgw-pcg-1 configmap martin-sgw-pcg-1-eric-pcgup-data-plane-router-config --from-file=bird.conf
helm install -n martin-sgw-pcg-1 --namespace martin-sgw-pcg-1 -f values.yaml ~/PCG_1_Drop_13/eric-pc-gateway-1.6.1-1.tgz --version 1.6.0-4

