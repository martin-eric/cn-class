#!/bin/bash
SCRIPTV="0.1"

echo "Starting script version $SCRIPTV"

if [[ $EUID -eq 0 ]]; then
  echo "You CANNOT be a root user. " 2>&1

  exit 1

fi
nop=0
nod=0
dep=0
pod=0
detected=0

echo "This script will analyze all Deployments and all Pods not in kube-system namespace and identify if the image is pointing to the Hello World app version that do not have a shell"
echo "If found, it will provide the command to update the image to an earlier version that indeed has a shell/killall binary."
echo "Thereafter, the Pluralsight exercises can resume."
echo
echo "Gathering information...."

myarray=$(kubectl get deployment,pod -A -o jsonpath='{range .items[*]}{"\n"}{.kind}{","}{.metadata.namespace}{","}{.metadata.name}{","}{.status.podIP}{","}{range .spec.template.spec.containers[*]}{.name}{","}{.image}{","}{"|||||"}{end}{range .spec.containers[*]}{.name}{","}{.image}{","}{"///"}{end}{end}' | sort | grep -v kube-system | grep hello-app)


echo "Workaround needed : "

for i in $myarray
do
        ((detected+=1))

        #echo "Detected  $i"
        IFS=', ' read -r -a array <<< "$i"

        #echo "${array[0]}"

        if [[ "${array[0]}" == "Deployment" ]] ; then

                if [[ "${array[5]}" =~ .*hello-app:1.0.* ]] ; then

                        echo "  DEPLOYMENT: kubectl set image deployment/${array[2]} ${array[4]}=gcr.io/google-samples/hello-app@sha256:88b205d7995332e10e836514fbfd59ecaf8976fc15060cd66e85cdcebe7fb356 -n ${array[1]}"
                        ((dep+=1));

                elif [[ "${array[5]}" =~ .*hello-app:2.0.* ]] ; then

                        echo "  DEPLOYMENT: kubectl set image deployment/${array[2]} ${array[4]}=gcr.io/google-samples/hello-app@sha256:2b0febe1b9bd01739999853380b1a939e8102fd0dc5e2ff1fc6892c4557d52b9 -n ${array[1]}"
                        ((dep+=1));

                else 

                        #echo "         no Deployment workaround needed"
                        ((nod+=1));

                fi

        elif [[ "${array[0]}" == "Pod" ]] ; then

                if [[ "${array[5]}" =~ .*hello-app:1.0.* ]] ; then

                        echo "  POD:    kubectl set image pod/${array[2]} ${array[4]}=gcr.io/google-samples/hello-app@sha256:88b205d7995332e10e836514fbfd59ecaf8976fc15060cd66e85cdcebe7fb356 -n ${array[1]}"
                        ((pod+=1));

                elif [[ "${array[5]}" =~ .*hello-app:2.0.* ]] ; then

                        echo "  POD:    kubectl set image pod/${array[2]} ${array[4]}=gcr.io/google-samples/hello-app@sha256:2b0febe1b9bd01739999853380b1a939e8102fd0dc5e2ff1fc6892c4557d52b9 -n ${array[1]}"
                        ((pod+=1));

                else 

                        #echo "         no Pod workaround needed"
                        ((nop+=1));

                fi

        fi

        #echo "------------------"
done


echo "------------------"
echo "Instructions "
echo "  1) Start with the Deployments, then rerun this script. "
echo "  2) If there are Pod not controlled by a Replicaset/Statefulset, then you can apply the workaround on them"
echo
echo "stats :"
echo "  Elements detected: $detected"
echo "  Deployments not needing workaround : $nod"
echo "  Pod not needing workaround : $nop"
echo
echo "  Deployments needing workaround : $dep"
echo "  Pod needing workaround : $pod"
echo "------------------"
