cd /home/ericsson/5gc_files_pkg/config/martin-cmme-cepg-pcc-1/

kubectl create namespace martin-student-namespace

helm install --name martin-student-release --namespace martin-student-namespace -f values.yaml --set tags.epg=false --set tags.mme=false --set mme.redis.imageCredentials.registry.url="docker.io" --set-file mme.nc.configMap=config-mme.cfg --set-file eric-epg.eric-pccsm-controller.controller.configMap=config-epg.xml ~/PCC_1_Drop_13/eric-pc-controller-1.6.0-10.tgz
