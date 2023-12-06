# Deployment Directory Structure 

This is the directory structure that the viya4-deployment project creates to store persistent files. It varies slightly from the SAS Viya Platform documentation in order to accommodate managing multiple SAS Viya Platform deployments within a single cluster. Below you will find an example of the directory structure and files that gets laid out, their use, equivalent from the SAS Viya Platform documentation if you were performing a manual deployment.

## Example Deployment Directory Structures

Note: All of these examples would be created in the location that is  defined by `BASE_DIR`. See [variable documentation](https://github.com/sassoftware/viya4-deployment/blob/main/docs/CONFIG-VARS.md#base).


**Example 1**: Single SAS Viya Platform Deployment using the SAS Viya Platform Deployment Operator with a "cluster-wide" scope

```shell
cluster
├── deployment-operator-clusterwide.yaml
└── namespace
    ├── license
    │   ├── certs.zip
    │   └── license.jwt
    ├── operator-deploy-clusterwide
    │   ├── operator-base
    │   └── site-config
    ├── sas-bases
    └── site-config
        └── vdm
```

Tree Breakdown

* `cluster`: Folder created per cluster that you are deploying to. It can house multiple `namespace` folders which would indicate multiple SAS Viya Platform deployments were performed within a single cluster.
  * `namespace`: Folder created per namespace within the cluster where you are performing the SAS Viya Platform deployment in. In our case we treat it similarly to the `$deploy` directory from the [SAS Viya Platform Administration documentation](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p1goxvcgpb7jxhn1n85ki73mdxc8.htm#p03uez7j2g8f0vn1m4xch4izmum0) and store our `sas-bases` and `site-config` files in there.
    * `license`: contains the .jwt file that licenses your software and the *-certs.zip file that contains the entitlement and CA certificates
    * `operator-deploy-$SCOPE`: Contains the operator kustomization.yaml file, used only for configuring and deploying the SAS Viya Platform Deployment Operator. The folder is appended with either "clusterwide" or "namespace" depending on the scope you chose for it using the `V4_DEPLOYMENT_OPERATOR_SCOPE` variable. This folder will not present if you set  `V4_DEPLOYMENT_OPERATOR_ENABLED` to "false" and opt to use the [sas-orchestration command](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=p0839p972nrx25n1dq264egtgrcq.htm)
    * `sas-bases`: contains the files that SAS provides to deploy your software. Extracted from the deployment assets.
    * `site-config`: Location for all customizations. This includes user provided customizations, [see documentation](https://github.com/sassoftware/viya4-deployment#sas-viya-customizations).
    * `vdm`: Contains the SAS Viya platform customizations files that are managed by viya4-deployment. These particular files are configured via exposed variables that are documented within [CONFIG-VARS.md](docs/CONFIG-VARS.md) and do not need to be manually placed under `/site-config`.
  * `deployment-operator-clusterwide.yaml`: File created when the SAS Viya Platform Deployment Operator is being used in the "clusterwide" mode. Contains information about the active "clusterwide" SAS Viya Platform Deployment Operator, useful when managing multiple SAS Viya platform deployments in a single cluster. This file will not present if you set  `V4_DEPLOYMENT_OPERATOR_SCOPE` is set to "namespace" or if opt to use the [sas-orchestration command](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=p0839p972nrx25n1dq264egtgrcq.htm)

  
**Example 2**: Single SAS Viya Platform Deployment using the "sas-orchestration" command

```shell
cluster
└── namespace
    ├── license
    │   ├── certs.zip
    │   └── license.jwt
    ├── sas-bases
    └── site-config
        └── vdm
```

Note: you will see that `operator-deploy-$SCOPE` directory nor the `deployment-operator-clusterwide.yaml` file is present since the SAS Viya Platform Deployment Operator is not in use. See above for tree breakdown for applicable directories.

**Example 3**: Multiple SAS Viya Platform Deployments in a single cluster using the SAS Viya Platform Deployment Operator with a "namespace" scope

```shell
cluster
├── namespace1
│   ├── license
│   │   ├── certs.zip
│   │   └── license.jwt
│   ├── operator-deploy-namespace
│   │   ├── operator-base
│   │   └── site-config
│   ├── sas-bases
│   └── site-config
│       └── vdm
└── namespace2
    ├── license
    │   ├── certs.zip
    │   └── license.jwt
    ├── operator-deploy-namespace
    │   ├── operator-base
    │   └── site-config
    ├── sas-bases
    └── site-config
        └── vdm
```

Note: you will see that `deployment-operator-clusterwide.yaml` is not present in this example since `V4_DEPLOYMENT_OPERATOR_SCOPE` is set to "namespace". See above for tree breakdown for applicable directories.