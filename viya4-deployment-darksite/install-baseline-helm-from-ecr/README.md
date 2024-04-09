# Gather some facts before running these scripts:

## Global Variables (00_vars.sh)
1. AWS Account ID
2. AWS Region 
3. K8s minor version

## metrics-server
1. helm chart version

## auto-scaler
1. helm chart version
2. Cluster name
3. Autoscaler ARN

## ingress-nginx
1. helm chart version
2. controller image digest (sha256) - get this from your ECR
3. webhook image digest (sha256) - get this from your ECR
4. load balancer source ranges (must be list example: ["0.0.0.0/0"])

## nfs-subdir-external-provisioner
1. nfs-subdir-external-provisioner helm chart version
2. RWX filestore endpoint (IP or DNS for endpoint..)
3. RWX filestore path (don't include ../pvs as it is already appended in the script)

## pg-nfs-provisioner
1. helm chart version
2. RWX filestore endpoint (IP or DNS for endpoint..)
3. RWX filestore path (don't include ../pvs as it is already appended in the script)

## cert-manager
1. helm chart version (don't include the proceeding v, it is already appended in the script)

## ebs-csi-driver
1.  helm chart version
2. eks.amazonaws.com/role-arn for EBS_CSI_DRIVER