# Deploy to AWS EKS in Dark Site or Air-Gapped Site scenario

### Contributors

We thank the following individuals for technical assistance and their contributions of documentation, scripts and yaml templates that provided the basis for this document.
- Josh Coburn
- Matthias Ender

### Background

This file describes procedures, helper scripts, and example files to assist with performing a Dark Site deployment using the `viya4-deploymemt` GitHub project.  

### Dark Site Deployment Scenarios

Choose the deployment scenario that describes your Dark Site configuration:

1. The deployment virtual machine has Internet access but the EKS cluster cannot reach the Internet (Dark Site) - Follow procedures 1, 2, 4, and 6.
2. The deployment virtual machine and cluster has no Internet access (air-gapped site) - Follow procedures 1, 2, 5, and 6.  Note: you'll still need to somehow push all the images and Helm charts to ECR from a machine with Internet access, and the deployment machine will use the private ECR endpoint in the VPC to pull these during install, so the deployment virtual machine won't need Internet access.

**Notes:**
- The following procedures assume that the `viya4-iac-aws` project was used to deploy the EKS infrastructure.  Refer to the `viya4-iac-aws-darksite` folder within the `viya4-iac-aws` [github repo](https://github.com/sassoftware/viya4-iac-aws) for the procedures to follow pertaining to IaC use with an AWS Dark Site configuration.
- Helper shell scripts under the `viya4-deployment-darksite` folder in this project assume that the deployment virtual machine is properly configured, confirm that:
    - kubeconfig file for the EKS cluster has been installed and tested (EKS cluster admin access is verified as working)
    - AWS CLI is configured

# Procedures

1. **Push Viya4 images to ECR (uses SAS mirrormgr tool):**
    - Download deployment assets from my.sas.com
    - refer to the `mirrormgr-to-ecr` folder in this repo for helper scripts

2. **Push 3rd party images to ECR:**
    - refer to the `baseline-to-ecr` folder in this repo for helper scripts
    - note: OpenLDAP is only required if you are planning to use OpenLDAP for your deployment.  Script to automate this is located [here](https://github.com/sassoftware/viya4-deployment/blob/feat/iac-1117/viya4-deployment-darksite/baseline-to-ecr/openldap.sh) [here](https://github.com/sassoftware/viya4-deployment/blob/main/viya4-deployment-darksite/baseline-to-ecr/openldap.sh).

3. **(Optional) If OpenLDAP is needed, modfy local viya4-deployment clone**
    - Refer to the [darksite-openldap-mod](https://github.com/sassoftware/viya4-deployment/blob/feat/iac-1117/viya4-aws-darksite/darksite-openldap-mod) [darksite-openldap-mod](https://github.com/sassoftware/viya4-deployment/blob/main/viya4-aws-darksite/darksite-openldap-mod) folder for procedures.  You can build the container using the script or do it manually.

4. **Deployment machine has Internet access - use viya4-deployment for baseline,install**

    1. Use built in variables for baseline configurations in your `ansible-vars.yaml` file:
        - Example `ansible-vars.yaml` provided [here](https://github.com/sassoftware/viya4-deployment/blob/feat/iac-1117/viya4-deployment-darksite/deployment-machine-assets/software/ansible-vars-iac.yaml) [here](https://github.com/sassoftware/viya4-deployment/blob/main/viya4-deployment-darksite/deployment-machine-assets/software/ansible-vars-iac.yaml)
        - The goal here is to change the image references to point to ECR versus an Internet facing repo and add cluster subnet ID annotations for the nginx load balancers:
            - Replace `{{ AWS_ACCT_ID }}` with your AWS account ID
            - Replace `{{ AWS_REGION }}` with your AWS region
            - Replace `{{ CONTROLLER_ECR_IMAGE_DIGEST }}` with image digest from ECR
            - Replace `{{ WEBHOOK_ECR_IMAGE_DIGEST }}` with image digest from ECR
            - If your VPC contains multiple subnets (unrelated to viya), you may need to add annotations to force the NLB to associate with the Viya subnets. More on that topic [here](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/subnet_discovery/).

    2. Deploy viya4-deployment baseline,install.  Note: the deployment virtual machine will pull the Helm charts from the Internet during this step.

5. **Deployment machine has no Internet access - install baseline using Helm charts pulled from ECR**
    - Two Options:
        1. If using OCI type repo (like ECR), we can use `viya4-deployment` but we'll need to make some changes to the baseline items in `ansible-vars.yaml`.  An example provided [here](https://github.com/sassoftware/viya4-deployment/blob/feat/iac-1117/viya4-deployment-darksite/deployment-machine-assets/software/ansible-vars-iac.yaml) [here](https://github.com/sassoftware/viya4-deployment/blob/main/viya4-deployment-darksite/deployment-machine-assets/software/ansible-vars-iac.yaml) includes the needed variables for OCI Helm support.  Pay close attention to `XXX_CHART_URL` and `XXX_CHART_NAME` variables.
        2. Use Helm directly to "manually" install baseline items.
            - Refer to baseline-helm-install-ecr README.md for instructions.

6. **viya4-deployment viya,install**
    - **Note:** As of `viya4-deployment` v6.0.0, the project uses the Deployment Operator as the default.  The deployment operator has additional considerations in a Dark Site deployment because the repository warehouse for the metadata will not be available without Internet access (as it is pulled from ses.sas.com).  
    
    - There are multiple options to mitigate the issue created by using the Deployment operator:

        1. (Easiest/Recommended) Set `V4_DEPLOYMENT_OPERATOR_ENABLED` to false.  This uses the sas-orchestration method for deployment instead of the Deployment Operator (no requirement for offline repository-warehouse hosting is required).

        2. Supply the repository information through an internally deployed http server.  SAS doesn't provide instructions on how to do this, because there are a lot of ways to accomplish this.  One way to accomplish this is shared in this [TS Track](https://sirius.na.sas.com/Sirius/GSTS/ShowTrack.aspx?trknum=7613552746).
        
        3. Store required metadata on a file system that can be mounted to the reconciler pod (using a transformer).  [TIES Blog for instructions](http://sww.sas.com/blogs/wp/technical-insights/8466/configuring-a-repository-warehouse-for-a-sas-viya-platform-deployment-at-a-dark-site/sukhda/2023/02/28)
        
        4. Use DAC with `DEPLOY: false` set.  This will build the manifests and references in kustomization.yaml and stop there.  Then you can proceed with manual installation steps: create site.yaml and apply it to the cluster (just ensure you are using the proper kustomization version!)
    
    - **Important:** ensure you specify `V4_CFG_CR_URL` in your ansible-vars.  This should be your ECR URL + your viya namespace!
        example: I used "viya4" as my Viya namespace.... `XXXXX.dkr.ecr.{{AWS_REGION}}.amazonaws.com/viya4`
