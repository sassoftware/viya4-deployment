# Multi-Tenancy

See details on how Multi-tenancy works [here](https://go.documentation.sas.com/doc/en/itopscdc/v_025/caltenants/titlepage.htm)

## Multi-tenancy is implemented in the following steps

1. Deploy SAS Viya and a provider tenant into a single Kubernetes namespace. The deployment includes shared mid-tier services such as SAS Logon, and shared applications such as SAS Studio. Applications other than SAS Environment Manager are not accessed from the provider tenant, and application users are not added to the provider tenant.
2. Onboard one or more tenants, and then onboard one or more instances of SAS Cloud Analytic Services into each tenant. Each instance of CAS is customized to meet its expected tenant workload. Also installed during tenant onboarding are the database schemas that will support authorization and authentication. Database servers can be internal or external to SAS.

**Note:** You need to configure all the tenant-specific users and groups during the intial deployment. Any changes to users or groups after the deployment are manual. For more details on setting up tenant users and groups see [LDAP Requirements for Multi-Tenancy](https://go.documentation.sas.com/doc/en/itopscdc/v_025/itopssr/p0440nbofn1b5qn1l6j1l6ygm7qg.htm#p1dr09lqs9w0w7n1iaklneorpy4r)

## Preparation

### Variable Definitions (ansible-vars.yaml) File

Prepare your `ansible-vars.yaml` file, and set the variables described in [Multi-Tenancy](../CONFIG-VARS.md#multi-tenancy). The variables V4_CFG_MULTITENANT_ENABLE and V4_CFG_MULTITENANT_DB_MODE are required to be set before deployment. The other variables can be set during onboard, offboard task as well.

### Examples steps to get Multi-tenant deployment

Step 1. Have a new cluster with sufficient CAS nodepool setup to support the number of tenants being onboarded. Deploy using the prepared ansible-vars.yaml

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
  ```

Step 2. Make sure deployment is stable, Verify login to the provider tenant succeeds.

Step 3. Onboard tenants

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "onboard"
  ```

#### Example command to Offboard tenants

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "offboard"
  ```

#### Example command to uninstall the deplyoment

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,uninstall"
  ```

## Troubleshooting
1. Make sure to check all the pods are in Running/Completed state before offboarding the tenants, else there might locks added by microservices and offboarding job will exit without offboarding the tenants (Work is in pogress to remediate this situation).
2. Cannot offboard immediately after onboarding, most of the microservices get restarted during onboarding process. Tenant environment might be accessible but there might some services which haven't stabilized yet causing the issue mentioned in #1.