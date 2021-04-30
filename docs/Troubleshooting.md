# Troubleshooting

## Debug Mode
Debug mode can be enabled by adding "-vvv" to the end of the docker or ansible commands

Example:

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME:/data \
    --volume $HOME/ansible-vars.yaml:/config/config \
    --volume $HOME/viya4-iac-azure/terraform.tfstate:/config/tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install" -vvv
  ```

  ```bash
  ansible-playbook \
    -e CONFIG=$HOME/ansible-vars.yaml \
    -e TFSTATE=$HOME/viya4-iac-aws/terraform.tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install" -vvv
  ```
