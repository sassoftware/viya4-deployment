## PostgreSQL Data Transfer Tool for the SAS Viya Platform - viya4-deployment Post-Transfer Steps (Experimental)

### Using IAC to create an external PostgreSQL database server
If you would prefer to use the IAC project used to create your cluster to create an external PostgreSQL database server, refer to IAC project link below corresponding to your cloud environment for PostgreSQL datbase server configuration examples.

[Azure PostgreSQL Server](https://github.com/sassoftware/viya4-iac-azure/blob/main/docs/CONFIG-VARS.md#postgres-servers)

[AWS PostgreSQL Server](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/CONFIG-VARS.md#postgresql-server)

[GCP PostgreSQL Server](https://github.com/sassoftware/viya4-iac-gcp/blob/main/docs/CONFIG-VARS.md#postgres-servers)

### Situation:

You had an existing SAS Viya platform deployment that was created using the viya4-deployment project and configured to use Crunchy as the database, and you have now completed the manual steps outlined in the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) to move your data over to an external PostgreSQL cluster. You now want to use the viya4-deployment project to manage your installation again.

### Recommended Steps:

1. After following the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) under "Steps for Crunchy Data 5" you manually added entries for the external PostgreSQL clusters into the kustomization.yaml and produced a file that includes details for **both** the internal Crunchy and external Postgres instance. You then built and applied the manifest so that the Viya deployment is reconfigured to point to the external Postgres instance.
2. The final step in the [PostgreSQL Data Transfer Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=pgdatamig&docsetTarget=titlepage.htm) under "Steps for Crunchy Data 5"  asks you to manually remove entries to related to Crunchy and rebuild your manifests again. At this point in time you could instead remove the manual modifications you made to the kustomization.yaml and make changes to your `ansible-vars.yaml` so that the viya4-deployment project can manage your installation again.
   1. First remove any files you manually copied over to site-config to configure the external PostgreSQL clusters. Like `sas-bases/examples/postgres/postgres-user.env` and `site-config/postgres/dataserver-transformer.yaml`, viya4-deployment will be generating this for you.
      * If as part of your data transfer, you provisioned your PostgreSQL clusters using any [Viya 4 IAC projects](https://github.com/search?q=org%3Asassoftware+viya4-iac-&type=repositories), then your PostgreSQL configuration and connection information should already be present in the .tfstate file, so you don't need to add those entries in your `ansible-vars.yaml`. You should modify the `V4_CFG_POSTGRES_SERVERS` variable if it's still configured to use an internal Crunchy instance like so:
      ```yaml
      # modify as below to use external instance
      V4_CFG_POSTGRES_SERVERS:
        default:
          internal: false
      ```
      * If as part of your data transfer, you provisioned your PostgreSQL clusters without the use of a Viya 4 IAC projects, then you will need to manually add definitions for each of your PostgreSQL clusters. You can see an example definition here in our [CONFIG-VARS.md documentation](https://github.com/sassoftware/viya4-deployment/blob/main/docs/CONFIG-VARS.md#postgresql)
   2. If your PostgreSQL Cluster requires a certificate for connection, in your `ansible-vars.yaml` ensure that `V4_CFG_TLS_TRUSTED_CA_CERTS` is set and points to either the certificate or a directory containing that certificate.
   3. In your `ansible-vars.yaml` set `DEPLOY` to false
   4. Run the ansible-playbook again with the `viya,install` tags. Since `DEPLOY` is set to false, the SAS Viya platform deployment will not be modified, however in your deployment directory you should see an updated kustomization.yaml with generated entries for your PostgreSQL clusters and those files should automatically be present in your site-config directory.