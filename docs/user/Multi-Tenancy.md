# Multi-Tenancy

The SAS Viya _IT Operations Guide_ provides detailed information about requirements and onboarding procedures for a multi-tenant deployment of SAS Viya. Access it [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/titlepage.htm).

## Overview: Required Steps

1. Deploy SAS Viya and a provider tenant into a single Kubernetes namespace.

   The deployment includes shared mid-tier services, such as SAS Logon Manager, and shared applications, such as SAS Studio. 
  Applications other than SAS Environment Manager are not accessed from the provider tenant, and application users are not added to the provider tenant.

2. Onboard one or more tenants, and then onboard one or more instances of SAS Cloud Analytic Services (the CAS server) into each tenant. Each instance of CAS is customized to meet its expected tenant workload.  

   During tenant onboarding, the database schemas that will support authorization and authentication are also installed. Database servers can be internal or external to SAS.

## Preparation

### Variable Definitions File (ansible-vars.yaml) 

Prepare your `ansible-vars.yaml` file, and set the variables as described in [Multi-Tenancy](../CONFIG-VARS.md#multi-tenancy). The variables V4MT_ENABLE and V4MT_MODE must be set before you perform the deployment. Other variables can be set before the deployment or during the onboarding or offboarding procedures. See example [ansible-vars-multi-tenancy.yaml](../../examples/multi-tenancy/ansible-vars-multi-tenancy.yaml)

### OpenLDAP Customizations

If the embedded OpenLDAP server is enabled, it is possible to change the users and groups that will be created. The required steps are similar to other customizations:

1. Create the folder structure detailed in the [Customize Deployment Overlays](../../README.md#customize-deployment-overlays). 
2. Copy the `./examples/multi-tenancy/openldap` folder into the `/site-config` folder. 
3. Locate the openldap-modify-mt-users-groups.yaml file in the `/openldap` folder. 
4. Modify it to match the desired setup. The file contains example user and groups defined for tenant1 and tenant2, make sure to update them to match your tenant IDs.

**Note:** You must configure all the tenant-specific users and groups during the intial deployment as this method can only be used when you are first deploying the OpenLDAP server. Subsequently, you can either delete and redeploy the OpenLDAP server with a new configuration, or add users using `ldapadd`.
For more information about setting up tenant users and groups, see [LDAP Requirements for Multi-Tenancy](https://go.documentation.sas.com/doc/en/itopscdc/v_025/itopssr/p0440nbofn1b5qn1l6j1l6ygm7qg.htm#p1dr09lqs9w0w7n1iaklneorpy4r).

For example:

- `/deployments` is the BASE_DIR
- The cluster is named demo-cluster
- The namespace will be named demo-ns
- Add overlay with custom LDAP setup

```bash
  /deployments                                     <- parent directory
    /demo-cluster                                  <- folder per cluster
      /demo-ns                                     <- folder per namespace
        /site-config                               <- location for all customizations
          /openldap                                <- folder containing user defined customizations
            /openldap-modify-mt-users-groups.yaml  <- openldap overlay
 ```

## Example Steps to Configure a Multi-Tenant Deployment

Step 1. Have a new cluster with sufficient CAS node resources to support the number of tenants being onboarded. Deploy using the ansible-vars.yaml file that you prepared previously. Run the following command to deploy SAS Viya:

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
  ```

Step 2. Make sure that the SAS Viya deployment is stable. Verify that you can log in to the provider tenant successfully.

Step 3. Onboard tenants. Run the following command:

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "onboard"
  ```
**Note:** The tenant CAS servers might take several mins to stabilize after the onboard tenant command above has completed successfully.

### Example Command to Offboard Tenants

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "offboard"
  ```

### Example Command to Uninstall SAS Viya with Multi-Tenancy

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,uninstall"
  ```

## Troubleshooting

1. Verify that all the pods are in Running/Completed state before offboarding the tenants. Otherwise, locks might have been added by SAS Viya services, and the offboarding job will exit without offboarding the tenants. (SAS is working on a fix to remediate this situation.)
2. Do not attempt to offboard tenants immediately after performing the onboarding steps. Most of the SAS Viya services are restarted during tenant onboarding. The tenant environment might be accessible during the time immediately following tenant onboarding, but there might some services that have not yet stabilized. As a result, they can cause the issue that is described in the previous troubleshooting step.
