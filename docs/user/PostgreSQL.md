# PostgreSQL

* [PostgreSQL](#postgresql)
  * [Use IAC To Create an External PostgreSQL Database Cluster](#use-iac-to-create-an-external-postgresql-database-cluster)
  * [Post Data Transfer Steps for viya4-deployment](#post-data-transfer-steps-for-viya4-deployment)
    * [Crunchy Data 5](#crunchy-data-5)
    * [Crunchy Data 4](#crunchy-data-4)
  * [2024.06 SharedServices Database Updated Behavior](#202406-sharedservices-database-updated-behavior)

## Use IAC To Create an External PostgreSQL Database Cluster

To use the IAC project to create an external PostgreSQL database cluster, refer to the IAC project link below that corresponds to your cloud environment. Each link goes to provider-specific PostgreSQL database cluster configuration examples.

**Note**: Before using IAC to create a new external PostgreSQL database cluster, SAS recommends that you follow the steps to [Stop a SAS Viya Platform Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=v_044&docsetId=calchkadm&docsetTarget=p17xfmmjjkma1dn1b5dcx3e5ejxq.htm#p0butgo7gtfyi0n14umtfv0voydt). After the external PostgreSQL database cluster has been created by IAC, follow the steps to [Start a SAS Viya Platform Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=v_044&docsetId=calchkadm&docsetTarget=p17xfmmjjkma1dn1b5dcx3e5ejxq.htm#p0butgo7gtfyi0n14umtfv0voydt).

[Azure PostgreSQL Cluster](https://github.com/sassoftware/viya4-iac-azure/blob/main/docs/CONFIG-VARS.md#postgres-servers)

[AWS PostgreSQL Cluster](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/CONFIG-VARS.md#postgresql-server)

[Google Cloud PostgreSQL Cluster](https://github.com/sassoftware/viya4-iac-gcp/blob/main/docs/CONFIG-VARS.md#postgres-servers)

## Post Data Transfer Steps for viya4-deployment

After you complete the steps outlined in the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) to move your data from an internal PostgreSQL server to an external PostgreSQL cluster, you can use the viya4-deployment project to manage your installation again. 

### Crunchy Data 5

The final step in the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) under "Post-transfer Steps for Crunchy Data 5" tells you to remove entries related to Crunchy Data and rebuild your manifests. Instead, you can remove the manual modifications you made to the `kustomization.yaml` and revise your `ansible-vars.yaml` file so that the viya4-deployment project can manage your installation again.

1. Remove any files you manually copied to site-config to configure the external PostgreSQL clusters, such as `sas-bases/examples/postgres/postgres-user.env` and `site-config/postgres/dataserver-transformer.yaml`. The viya4-deployment project will be generating the files for you.
   * If you provisioned your PostgreSQL clusters using any [Viya 4 IAC projects](https://github.com/search?q=org%3Asassoftware+viya4-iac-&type=repositories), then your PostgreSQL configuration and connection information should already be present in the .tfstate file. Therefore, you do not need to add those entries in your `ansible-vars.yaml` file. However, you should modify the `V4_CFG_POSTGRES_SERVERS` variable if it's still configured to use an internal Crunchy instance. Here is an example:
   ```yaml
   # modify as below to use external instance
   V4_CFG_POSTGRES_SERVERS:
     default:
       internal: false
   ```
   * If you provisioned your PostgreSQL clusters without the use of a Viya 4 IAC project, then you must manually add definitions for each of your PostgreSQL clusters. You can see an example definition at [CONFIG-VARS.md documentation](https://github.com/sassoftware/viya4-deployment/blob/main/docs/CONFIG-VARS.md#postgresql).
2. If your PostgreSQL cluster requires a certificate for connection, ensure that `V4_CFG_TLS_TRUSTED_CA_CERTS` is set in your `ansible-vars.yaml` file and that it points to either the certificate or a directory containing the certificate.
3. In your `ansible-vars.yaml` file, set `DEPLOY` to false.
4. Run the ansible-playbook again with the `viya,install` tags. Because `DEPLOY` is set to false, the SAS Viya platform deployment will not be modified. However, in your deployment directory you should see an updated `kustomization.yaml` file with generated entries for your PostgreSQL clusters. Those files should automatically be present in your site-config directory.

### Crunchy Data 4

1. In the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) under "Post-transfer Steps for Crunchy Data 4", in Step 5 you are asked to remove all entries in your `kustomization.yaml` file that contain a set of strings that are used for Crunchy Data 4 PostgreSQL configuration. Because the viya4-deployment project automatically manages the configuration and creation of the PostgreSQL related entries in your `kustomization.yaml` file, you can skip Step 5 from the "Post-transfer Steps for Crunchy Data 4".
2. Configure your `ansible-vars.yaml` file to make the switch over from Crunchy Data PostgreSQL to an external PostgreSQL cluster.
   * If you provisioned your PostgreSQL clusters using any [Viya 4 IAC projects](https://github.com/search?q=org%3Asassoftware+viya4-iac-&type=repositories), then your PostgreSQL configuration and connection information should already be present in the .tfstate file. Therefore, you do not need to add those entries in your `ansible-vars.yaml` file. However, you should modify the `V4_CFG_POSTGRES_SERVERS` variable if it's still configured to use an internal Crunchy instance. Here is an example:
   ```yaml
   # modify as below to use external instance
   V4_CFG_POSTGRES_SERVERS:
     default:
       internal: false
   ```
   * If you provisioned your PostgreSQL clusters without the use of a Viya 4 IAC project, then you must manually add definitions for each of your PostgreSQL clusters. You can see an example definition at [CONFIG-VARS.md documentation](https://github.com/sassoftware/viya4-deployment/blob/main/docs/CONFIG-VARS.md#postgresql).
3. If your PostgreSQL cluster requires a certificate for connection, ensure that `V4_CFG_TLS_TRUSTED_CA_CERTS` is set in your `ansible-vars.yaml` file and that it points to either the certificate or a directory containing the certificate. This replaces Step 6 from the "Post-transfer Steps for Crunchy Data 4" documentation. Skip over Step 7 from the "Post-transfer Steps for Crunchy Data 4" documentation, viya4-deployment performs this automatically. 
4. Going back to the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) under "Post-transfer Steps for Crunchy Data 4" perform Step 8 and start the operator if your deployment is managed by the SAS Deployment Operator (if `V4_DEPLOYMENT_OPERATOR_ENABLED` was set to true in your `ansible-vars.yaml` file). Otherwise, skip this step.
5. Run the ansible-playbook again with the `viya,install` tags. This updates the `kustomization.yaml` by removing entries related to Crunchy Data 4 and adding entries for your external PostgreSQL cluster. The manifest will be rebuilt and reapplied to the cluster. This replaces step 9 from the "Post-transfer Steps for Crunchy Data 4" documentation.
6. Return to the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) under "Post-transfer Steps for Crunchy Data 4". Perform Steps 10 and the remainder of the steps to complete the data transfer.


## 2024.06 SharedServices Database Updated Behavior
Due to changes in the sas-data-server-operator, the SharedServices database is not created automatically during the initial deployment of the SAS Viya platform. Instead, you must manually create it before you start the SAS Viya platform deployment

Deployments performed on cadence versions before 2024.06 will not be impacted.

For more information, please refer to the [External Postgres Requirements](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=p05lfgkwib3zxbn1t6nyihexp12n.htm#p1wq8ouke3c6ixn1la636df9oa1u) documentation.