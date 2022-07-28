# SAS Viya Application Multi-Tenancy

SAS Viya supports a multi-tenant environment where multiple tenants can use the applications of a single deployment. Each tenant has access to the licensed software and can manage their own resources but has no visibility into the data and workflows of other tenants. The SAS Viya _IT Operations Guide_ provides detailed information about requirements and onboarding procedures for a multi-tenant deployment of SAS Viya. Access it [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/titlepage.htm).

## Requirements for a Multi-Tenant Environment

1. CAS Server Resources Requirement. Each tenant requires a dedicated CAS server.
   
   With multi-tenancy enabled in your deployment, the tenants will share most of the nodes with the provider tenant. However, because each tenant has its own CAS server, the total number of nodes required for CAS for the full deployment is greater than that for a non-multi-tenant deployment. The number of additional CAS nodes required per tenant depends on whether the tenant is deploying SMP or MPP CAS. See [CAS Server Resources](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/n0ampbltwqgkjkn1j3qogztsbbu0.htm#p1phbohacgeubcn0zgt2pdlqu0fu) for more details and [plan workload placement](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/p0om33z572ycnan1c1ecfwqntf24.htm#p1ujrdxsdddpdpn1r3xavgwaa0tu) accordingly.

2. SAS Infrastructure Data Server. 

   SAS Viya requires either an internal PostgreSQL instance, which is the default option that is deployed automatically, or an external instance that you configure and maintain. Both the internal and external PostgreSQL options are supported for multi-tenancy. If you deploy with the default option, SAS configures and maintains the deployment for you. If you instead deploy an external PostgreSQL instance, you are responsible for configuring and maintaining it. For external PostgreSQL, see [Requirements for External PostgreSQL](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/p05lfgkwib3zxbn1t6nyihexp12n.htm#p1wq8ouke3c6ixn1la636df9oa1u). Also for details see [PostgreSQL Requirements for a Multi-Tenant Deployment](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/p05lfgkwib3zxbn1t6nyihexp12n.htm#p1r5u2f0yyiql5n11qb61lldcq1j).

3. TLS certificates. See [TLS Requirements](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/n18dxcft030ccfn1ws2mujww1fav.htm#p0bskqphz9np1ln14ejql9ush824).

4. DNS configuration. See [DNS Requirements for Multi-Tenancy](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/n18dxcft030ccfn1ws2mujww1fav.htm#n0mfva3uqvw78nn14s2deu1um3m1).

5. User accounts in your LDAP or SCIM identity provider. To configure LDAP see the steps in [OpenLDAP Customizations](#openldap-customizations).

   For more information on requirements see [Additional LDAP Requirements for Multi-Tenancy](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/n18dxcft030ccfn1ws2mujww1fav.htm#p1dr09lqs9w0w7n1iaklneorpy4r) or [Additional SCIM Requirements for Multi-Tenancy](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/n18dxcft030ccfn1ws2mujww1fav.htm#n0snw477kspeqln1fmoeq3hu6c4m).

Multi-tenancy is not supported in every customer environment. For more information, see [Limitations to Multi-Tenancy Support](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/n0jq6u1duu7sqnn13cwzecyt475u.htm#p11lcjg42kzdgjn1obgqb9zlaltw).

## Actions

Actions to perform onboard, cas-onboard or offboard tenants. 

| Name | Description |
| :--- | :--- |
| onboard | Adds and configures one or more tenants alongside the existing provider tenant |
| cas-onboard | Onboards a CAS server for an onboarded tenant |
| offboard | Removes one or more onboarded tenants |

## Tasks

Task introduced to facilitate Multi-tenancy actions.

| Name | Description |
| :--- | :--- |
| multi-tenancy | Enables to onboard, cas-onboard and offboard on a multi-tenant deployment |

## Preparation

### Variable Definitions File (ansible-vars.yaml) 

Prepare your `ansible-vars.yaml` file, and set the variables as described in [Multi-Tenancy](../CONFIG-VARS.md#multi-tenancy). The variables V4MT_ENABLE, V4MT_MODE and V4MT_TENANT_IDS must be set before you perform the deployment. Other variables can be set before the deployment or during the onboarding or offboarding procedures. See example [ansible-vars-multi-tenancy.yaml](../../examples/multi-tenancy/ansible-vars-multi-tenancy.yaml)

### OpenLDAP Customizations

If the embedded OpenLDAP server is enabled, it is possible to change the users and groups that will be created. The required steps are similar to other customizations:

1. Create the folder structure detailed in the [Customize Deployment Overlays](../../README.md#customize-deployment-overlays).
2. Copy the `./examples/multi-tenancy/openldap` folder into the `/site-config` folder.
3. Locate the openldap-modify-mt-users-groups.yaml file in the `/openldap` folder.
4. Modify it to match the desired setup. The file contains example user and groups defined for tenant1 and tenant2, make sure to update them to match your tenant IDs.

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

## Steps to Configure a Multi-Tenant Deployment and Onboard Tenants

Step 1. Have a cluster with sufficient CAS node resources to support the number of tenants being onboarded. Deploy using the ansible-vars.yaml file that you prepared previously. Run the following command to deploy SAS Viya:

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
    playbooks/playbook.yaml --tags "multi-tenancy,onboard"
  ```

Step 4. Add any additional CAS customizations for tenants as needed and then run following command to onboard the CAS servers:

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    playbooks/playbook.yaml --tags "multi-tenancy,cas-onboard"
  ```

**Note:** 
- If there are no additional CAS customizations required for tenants then run 'onboard' and 'cas-onboard' tags together in Step 3 and skip Step 4.
- The tenant CAS servers might take several mins to stabilize after the cas-onboard command above has completed successfully.

## Log In and Validate an Onboarded Tenant
After the onboard and cas-onboard steps are complete see the steps [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/p0emzq13c0zbhxn1hktsdlmig934.htm#n05u0e3vmr5lcqn1l5xa2rhkdu6x) to login and validate an onboarded tenant.

## Offboard Tenants and CAS Servers
Best practice before running offboard command:

1. Perform a backup as a best-practice task. For more information, see [Backup and Restore: Perform an Ad Hoc Backup](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calbr/p0cw7yuvwc83znn1igjc16zah2se.htm) in SAS Viya: Backup and Restore.

2. Check for scheduled jobs and suspend all scheduled jobs to prevent them from automatically starting during or after offboarding. The jobs need to remain suspended at least until the offboarding of tenant CAS servers. If your deployment includes SAS Workflow Manager, use the [Workload Orchestrator](https://go.documentation.sas.com/doc/en/sasadmincdc/default/evfun/n15gjfza5o8i6hn1kr8f408c2et3.htm) page in SAS Environment Manager. Otherwise, use the [Jobs](https://go.documentation.sas.com/doc/en/sasadmincdc/default/caljobs/n0x3w4aokfoi1wn1q33jg4yrifge.htm) page in SAS Environment Manager.

### Run the following command to Offboard Tenants and Offboard CAS Servers for tenants

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    playbooks/playbook.yaml --tags "multi-tenancy,offboard"
  ```

## Uninstall SAS Viya with Multi-Tenancy Enabled Deployment
Before you run uninstall command make sure to run offboard command for any onboarded tenants.

### Run the following command to uninstall deployment

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
