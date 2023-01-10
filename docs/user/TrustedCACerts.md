# Using Trusted CA Certs

## How to obtain an AWS certificate bundle

To obtain a certificate bundle that contains both the intermediate and root certificates for all AWS Regions, you can download the PEM file from https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html  

## How to obtain an Opensource Kubernetes certificate bundle

If performing a SAS Viya 4 platform deployment against Opensource Kubernetes whose infrastructure was created with the [viya4-iac-k8s](https://github.com/sassoftware/viya4-iac-k8s) project, and you want to get the certificates for the external Postgres database, follow the steps in the "notes" section in the [documentation here](https://github.com/sassoftware/viya4-iac-k8s/blob/main/docs/CONFIG-VARS.md#postgresql-server). You will have the option to either use the system default certificates in which case they will be copied to your workspace for use, or you can provide your own generated certificates.
