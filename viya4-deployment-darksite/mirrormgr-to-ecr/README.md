## Helper Script to help with mirrormgr

SAS documentation specific to using mirrormgr for AWS ECR located [here](https://go.documentation.sas.com/doc/en/itopscdc/v_029/dplyml0phy0dkr/p0lexw9inr33ofn1tbo69twarhlx.htm).

## Step 1: Download Order Assets
- Download order assets [here](https://my.sas.com/en/my-orders.html). Check all under "order assets".

## Step 2: Unzip to assets/ folder
- Unzip multipleAssets zip to assets/ folder ... if following the darksite-lab: place in /home/ec2-user/viya/software/viya_order_assets

## Step 3: Install mirrormgr
- Download [here](https://support.sas.com/en/documentation/install-center/viya/deployment-tools/4/mirror-manager.html).

## Step 4: Update variables in 00_vars.sh

## Step 5: Run mirrormgr-ecr.sh
- The script assumes your AWS CLI is already configured.
- This script will use `mirrormgr` to create AWS ECR repos for each viya4 image (AWS requirement).
- This script will download the viya4 images locally, then using `mirrormgr`, automatically push them to the appropriate ECR repo.
    - This will take some time based on your local bandwidth.  Note: the images are around ~120GiB total.

## Helper script to help clean up ECR: cleanup-ecr.sh
- This script uses AWS CLI to delete all the SAS Viya and 3rd party repositories and images.  This makes life easier when you need to clean up the AWS ECR.
