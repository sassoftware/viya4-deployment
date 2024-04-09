#!/bin/bash

# get viya4-deployment container tag
echo -e "\n"
read -p "What is your viya4-deployment container tag? " -r DOCKER_TAG

TASKS=("baseline" "viya" "cluster-logging" "cluster-monitoring" "viya-monitoring" "install" "uninstall")

##### FUNCTIONS #####
function docker_run() {
  echo "starting $tags job..."
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $(pwd)/infrastructure/ssh/id_rsa:/config/jump_svr_private_key \
    --volume $(pwd)/infrastructure/terraform.tfstate:/config/tfstate \
    --volume /home/ec2-user/.kube/config:/.kube/config \
    --volume $(pwd)/software/deployments:/data \
    --volume $(pwd)/software/viya_order_assets:/viya_order_assets \
    --volume $(pwd)/software/ansible-vars-iac.yaml:/config/config \
    --volume $(pwd)/software/ingress:/ingress \
    --volume $(pwd)/software/sitedefault.yaml:/sitedefault/sitedefault.yaml \
    viya4-deployment:$DOCKER_TAG --tags "$tags"
}

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

##### MAIN SCRIPT #####
if [ $# -eq 0 ]
then
  # what are the deploy tags
  echo
  echo "You didn't provide deployment tags!"
  echo 
  echo "Tasks: baseline viya cluster-logging cluster-monitoring viya-monitoring"
  echo "Actions: install uninstall"
  echo 
  echo '     -All tasks and actions must be separated by ","                      '
  echo "     -At least one task must be supplied. Multiple tasks are allowed.     "
  echo "     -An action is required and must be the last and ONLY action provided."
  echo
  echo "Examples: baseline,viya,install"
  echo "          viya,uninstall       "
  echo
  echo -n "What are your deployment tags? "
  read -r REPLY
else
  REPLY=$*
fi

# split REPLY into an array
IFS=',' read -r -a array <<< "$REPLY"
# remove spaces in array elements
clean=()
for i in "${array[@]}"; do
  i=${i// /}
  clean+=("$i")
done

# check if provided tasks are valid
for i in "${clean[@]}"; do
  inarray=$(echo ${TASKS[@]} | grep -ow "$i" | wc -w)
  if [ $inarray == 0 ]; then
    echo $i "is not a valid input."
    exit 0
  fi
done

# check that more than one tag is provided
len=${#clean[@]}
if [ $len -lt 2 ]; then
  echo "Not enough tags provided!"
  exit 0
fi

# check if install and uninstall is provided correctly
count=0
for i in "${clean[@]}"; do
  if [ $i == "install" ] || [ $i == "uninstall" ]; then
    (( count++ ))
  fi
done
if [ $count == 0 ]; then
  echo "You didn't provide an install or uninstall action!"
  exit 0
elif [ $count -gt 1 ]; then
  echo "You can only have one action: install or uninstall!"
  exit 0
fi
# check that install/uninstall is last value
last="${clean[-1]}"
if [ "$last" != "install" ] && [ "$last" != "uninstall" ]; then
  echo "install or uninstall must be last tag value!"
  exit 0
fi

# if uninstall job, double check before continuing!
if [ "$last" == "uninstall" ]; then
  read -p "Are you really sure you want to continue; this action is destructive!! (y/n)? " -n 1 -r REPLY
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# all checks passed so build the tags string
tags=$(join_by , ${clean[*]})

# run the function
docker_run

# remove downloaded assets
if [ -f software/deployments/darksite-lab-eks/viya/SASViyaV4*.tgz ]; then
    rm software/deployments/darksite-lab-eks/viya/SASViyaV4*.tgz
fi
