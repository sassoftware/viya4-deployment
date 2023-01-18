# Using Trusted CA Certs

## How to obtain an AWS certificate bundle

To obtain a certificate bundle that contains both the intermediate and root certificates for all AWS Regions, you can download the PEM file from https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html  

## How to Obtain an Open Source Kubernetes Certificate Bundle

If you are performing a SAS Viya platform deployment into a cluster in open source Kubernetes that was created with the [viya4-iac-k8s](https://github.com/sassoftware/viya4-iac-k8s) project, and if you want to obtain the certificates for the external PostgreSQL database, follow the steps in the "Notes" section in the [documentation here](https://github.com/sassoftware/viya4-iac-k8s/blob/main/docs/CONFIG-VARS.md#postgresql-server). You will have the option to either use the system default certificates, in which case they will be copied to your workspace for use, or you can provide your own generated certificates.