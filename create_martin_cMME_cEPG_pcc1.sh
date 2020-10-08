cd /home/ericsson/5gc_files_pkg/config/martin-cmme-cepg-pcc-1/

kubectl create namespace martin-cmme-cepg-pcc-1

helm install --name martin-cmme-cepg-pcc-1 --namespace martin-cmme-cepg-pcc-1 -f values.yaml --set mme.redis.imageCredentials.registry.url="docker.io" --set-file mme.nc.configMap=config-mme.cfg --set-file eric-epg.eric-pccsm-controller.controller.configMap=config-epg.xml ~/PCC_1_Drop_13/eric-pc-controller-1.6.0-10.tgz
