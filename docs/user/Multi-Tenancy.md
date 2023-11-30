# SAS Viya Multi-tenancy

SAS Viya Multi-tenancy enables the onboarding and offboarding of tenants. The tenants share access to licensed SAS Viya applications, but tenants cannot access the data, workflows, users, and resources in other tenants.

The onboarding and offboarding processes described here enable you to deploy tenants with specified users and groups as part of the deployment process. Standardized CAS Servers can be installed with each tenant, or customized CAS Servers can be installed after tenant onboarding.

The tenant onboarding and offboarding processes can be run as needed after a successful provider deployment. Offboarding removes specified tenants and their CAS Servers.

## Requirements for a Multi-tenant Environment

1. CAS Server Resources Requirement.
   
   Each tenant requires a dedicated CAS server. See [CAS Server Resources](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n0ampbltwqgkjkn1j3qogztsbbu0.htm#p1phbohacgeubcn0zgt2pdlqu0fu) for more details and [plan workload placement](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p0om33z572ycnan1c1ecfwqntf24.htm#p1ujrdxsdddpdpn1r3xavgwaa0tu) accordingly.

2. PostgreSQL Requirement.

   SAS Viya Multi-tenancy requires either an internal PostgreSQL instance, which is the default option that is deployed automatically, or an external PostgreSQL instance that you configure and maintain. For external PostgreSQL, see [Requirements for External PostgreSQL](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=p05lfgkwib3zxbn1t6nyihexp12n.htm#p1wq8ouke3c6ixn1la636df9oa1u). Also for details see [PostgreSQL Requirements for a Multi-tenant Deployment](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=p05lfgkwib3zxbn1t6nyihexp12n.htm#p1r5u2f0yyiql5n11qb61lldcq1j).

   **Note:** Before deployment, when using internal PostgreSQL, be sure to size the total number of tenants that will be onboarded. The variable `V4MT_TENANT_IDS` must list all tenants planned to be onboarded. The list of tenants is used to calculate max_connections in PostgreSQL. After deployment, max_connections cannot be changed without redeploying the SAS Viya platform.

3. TLS certificates. See [TLS Requirements](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n18dxcft030ccfn1ws2mujww1fav.htm#p0bskqphz9np1ln14ejql9ush824).

4. DNS configuration. See [DNS Requirements for Multi-tenancy](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n18dxcft030ccfn1ws2mujww1fav.htm#n0mfva3uqvw78nn14s2deu1um3m1).

5. LDAP or SCIM requirements. 

   To configure LDAP see the steps in [OpenLDAP Customizations](#openldap-customizations). For more information on LDAP or SCIM requirements see [Additional LDAP Requirements for Multi-tenancy](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n18dxcft030ccfn1ws2mujww1fav.htm#p1dr09lqs9w0w7n1iaklneorpy4r) or [Additional SCIM Requirements for Multi-tenancy](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n18dxcft030ccfn1ws2mujww1fav.htm#n0snw477kspeqln1fmoeq3hu6c4m).

## Limitations to Multi-tenancy Support
Multi-tenancy is not supported in every customer environment. For more information, see [Limitations to Multi-tenancy Support](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n0jq6u1duu7sqnn13cwzecyt475u.htm#p11lcjg42kzdgjn1obgqb9zlaltw).

## Actions

| Name | Description |
| :--- | :--- |
| onboard | Adds and configures one or more tenants alongside the existing provider tenant |
| cas-onboard | Onboards a CAS server for an onboarded tenant |
| offboard | Removes one or more onboarded tenants |

## Tasks

| Name | Description |
| :--- | :--- |
| multi-tenancy | Enables you to onboard tenants, onboard CAS server for tenants, and offboard tenants. |

## Preparation

### Variable Definitions File (ansible-vars.yaml) 

Prepare your `ansible-vars.yaml` file, and set the variables as described in [Multi-tenancy](../CONFIG-VARS.md#multi-tenancy). The variables `V4MT_ENABLE` and `V4MT_MODE` must be set before deployment. Other variables can be set before the deployment or during the onboarding or offboarding procedures. See example [ansible-vars-multi-tenancy.yaml](../../examples/multi-tenancy/ansible-vars-multi-tenancy.yaml)

**Note:** If your deployment has internal PostgreSQL then you must also set the variable `V4MT_TENANT_IDS` before deployment. You must include all the tenants that you plan to onboard in your deployment to calculate the `max_connections` correctly. Post deployment, when onboarding or offboarding, change the value of `V4MT_TENANT_IDS` to list the subset of involved tenants.

For external PostgreSQL, `V4MT_TENANT_IDS` is optional for the deployment step. You can set it along with other variable during the onboarding or offboarding procedures.

### OpenLDAP Customizations

If the embedded OpenLDAP server is enabled, it is possible to change the users and groups that will be created. The required steps are similar to other customizations:

1. Create the folder structure detailed in the [Customize Deployment Overlays](../../README.md#customize-deployment-overlays).
2. Copy the `./examples/multi-tenancy/openldap` folder into the `/site-config` folder.
3. Locate the openldap-modify-mt-users-groups.yaml file in the `/openldap` folder.
4. Modify the file to match the desired setup. The initial file contains example users and groups defined for tenant1 and tenant2. Make sure that you change the tenant IDs.

**Note:** You must configure all the tenant-specific users and groups during the initial deployment as this method can only be used when you are first deploying the OpenLDAP server. Subsequently, you can either delete and redeploy the OpenLDAP server with a new configuration or add users using `ldapadd`.

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

## Configure a Multi-tenant Deployment and Onboard Tenants

Step 1. Configure a cluster with sufficient CAS node resources to support the number of tenants being onboarded. Deploy using your updated ansible-vars.yaml file. Run the following command to deploy SAS Viya Multi-tenancy:

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
  ```

Step 2. Make sure that the SAS Viya platform deployment is stable. Verify that you can log in to the provider tenant successfully.

Step 3. Onboard tenants. Run the following command:

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "multi-tenancy,onboard"
  ```
**Note:** As part of setup in the above `Onboard tenants` step, for every onboarded tenant, 

- A CAS server directory containing the configuration artifacts is created under the `/site-config` folder. 
For example,if you have tenant with the ID `acme`, then a CAS server directory named `cas-acme-default` will be created.

- Starting with SAS Viya Platform cadence 2023.03, each tenant will require their own copy of certain Kubernetes resources. Hence a new directory for each tenant containing all the `sas-programming-environment` files will be created under `$deploy/site-config/multi-tenant/`. For example, if you have a tenant with the ID `acme`, then a directory named `$deploy/site-config/multi-tenant/acme` will be created.

Step 4. Add or update CAS customizations for tenants as needed and then run following command to onboard the CAS servers:

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "multi-tenancy,cas-onboard"
  ```

**Note:** 
- If there are no additional CAS customizations required for tenants then run 'onboard' and 'cas-onboard' tags together in Step 3 and skip Step 4.
- The tenant CAS servers might take several mins to stabilize after the cas-onboard command above has completed successfully.

## Log In and Validate an Onboarded Tenant
After the onboard and cas-onboard steps are complete see the steps [here](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=caltenants&docsetTarget=p0emzq13c0zbhxn1hktsdlmig934.htm#n05u0e3vmr5lcqn1l5xa2rhkdu6x) to login and validate an onboarded tenant.

## Offboard Tenants and CAS Servers
Best practice before running offboard command:

1. Perform a backup as a best-practice task. For more information, see [Backup and Restore: Perform an Ad Hoc Backup](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calbr&docsetTarget=p0cw7yuvwc83znn1igjc16zah2se.htm) in SAS Viya: Backup and Restore.

2. Check for scheduled jobs and suspend all scheduled jobs to prevent them from automatically starting during or after offboarding. The jobs need to remain suspended at least until the offboarding of tenant CAS servers. If your deployment includes SAS Workflow Manager, use the [Workload Orchestrator](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=evfun&docsetTarget=n15gjfza5o8i6hn1kr8f408c2et3.htm) page in SAS Environment Manager. Otherwise, use the [Jobs](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=caljobs&docsetTarget=n0x3w4aokfoi1wn1q33jg4yrifge.htm) page in SAS Environment Manager.

### Run the following command to Offboard Tenants and Offboard CAS Servers for tenants

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "multi-tenancy,offboard"
  ```

## Uninstall SAS Viya Multi-tenant Deployment
Before you run uninstall command make sure to run offboard command for any onboarded tenants.

### Run the following command to uninstall

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,uninstall"
  ```

## Troubleshooting

1. Verify that all the pods are in `Running` or `Completed` state before offboarding the tenants. Otherwise, locks might have been added by SAS Viya platform services, and the offboarding job will exit without offboarding the tenants.
2. Do not attempt to offboard tenants immediately after onboarding. Most of the SAS Viya platform services are restarted during tenant onboarding. The tenant environment might be accessible during the time immediately following tenant onboarding, but there might be some services that have not yet stabilized. As a result, they can cause the issue that is described in the previous troubleshooting step.
