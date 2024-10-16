These scripts assume your aws cli and your kubeconfig is already configured!

Notes: 
- requires helm, yq, and aws cli
- these scripts will install the helm charts and corresponding container images to ECR for each baseline item.
- it will automatically set the chart version based on the version of DAC you specify.

## Step 1:  Set your variables
- Set your variables in 00_vars.sh

## Step 2: Run script(s)
- Option 1: run 01_run_all.sh (runs all scripts)
- Option 2: run scripts individually