#!/bin/bash

# what is the tag
read -p "What is the tag for your viya4-iac-aws container? " -r TAG
# what is the job
read -p "What type of IaC job: plan, apply, or destroy? " -r REPLY

# preview job
if [ $REPLY == "plan" ]; then
  echo -e "\n+++Starting plan job ...\n"
  docker run --rm \
    --group-add root \
    --user "$(id -u):$(id -g)" \
    --volume=$(pwd)/infrastructure:/workspace \
    viya4-iac-aws:$TAG \
    plan -var-file=/workspace/terraform.tfvars \
      -state=/workspace/terraform.tfstate  
fi

# apply job
if [ $REPLY == "apply" ]; then
  echo -e "\n+++Starting apply job ...\n"
  docker run --rm \
    --group-add root \
    --user "$(id -u):$(id -g)" \
    --volume=$(pwd)/infrastructure:/workspace \
    viya4-iac-aws:$TAG \
    apply -auto-approve -var-file=/workspace/terraform.tfvars \
      -state=/workspace/terraform.tfstate  
  
  # Update the kubeconfig using aws cli and place here on deploy machine: ~/.kube/config
  aws eks update-kubeconfig --name darksite-lab-eks 
  rm /home/$USER/viya/infrastructure/darksite-lab-eks-kubeconfig.conf
fi

# destroy job
if [ $REPLY == "destroy" ]; then
  read -p "Are you sure you want to continue (y/n)? " -n 1 -r REPLY
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
  echo -e "\n+++Starting destroy job ...\n"
  docker run --rm \
    --group-add root \
    --user "$(id -u):$(id -g)" \
    --volume=$(pwd)/infrastructure:/workspace \
    viya4-iac-aws:$TAG \
    destroy -auto-approve -var-file=/workspace/terraform.tfvars \
      -state=/workspace/terraform.tfstate 
fi