#!/bin/bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# helper script to easily mod viya4-deployment when using openldap in a darksite


## check that viya4-deployment/ exists in this folder
if [ ! -d "viya4-deployment/" ] 
then
  echo -e "\nError: Directory viya4-deployment/ does not exists!\n" 
  read -p "Would you like to locally clone the viya4-deployment github repo to fix (y/n)? " -n 1 -r REPLY
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
  ## Get desired DAC version
  read -p "What release version of DAC do you want to use? " -r IAC_VERSION
  git clone --branch $IAC_VERSION https://github.com/sassoftware/viya4-deployment.git
fi

echo
read -p "What is your aws account id? " -r AWS_ACCT_ID
read -p "What is your aws region? " -r AWS_REGION

echo -e "\n+++Modding viya4-deployment/roles/vdm/templates/resources/openldap.yaml ..."

tee viya4-deployment/roles/vdm/templates/resources/openldap.yaml > /dev/null << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openldap
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openldap
  template:
    metadata:
      labels:
        app: openldap
    spec:
      hostname: ldap-svc
      imagePullSecrets: []
      containers:
        - image: "${AWS_ACCT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/osixia/openldap:1.3.0"
          imagePullPolicy: IfNotPresent
          name: openldap
          ports:
            - containerPort: 389
          args:
            - --copy-service
          env:
          - name: LDAP_TLS
            valueFrom:
              configMapKeyRef:
                name: openldap-bootstrap-config
                key: LDAP_TLS
          - name: LDAP_ADMIN_PASSWORD
            valueFrom:
              configMapKeyRef:
                name: openldap-bootstrap-config
                key: LDAP_ADMIN_PASSWORD
          - name: LDAP_DOMAIN
            valueFrom:
              configMapKeyRef:
                name: openldap-bootstrap-config
                key: LDAP_DOMAIN
          - name: LDAP_REMOVE_CONFIG_AFTER_SETUP
            valueFrom:
              configMapKeyRef:
                name: openldap-bootstrap-config
                key: LDAP_REMOVE_CONFIG_AFTER_SETUP
          - name: DISABLE_CHOWN
            valueFrom:
              configMapKeyRef:
                name: openldap-bootstrap-config
                key: DISABLE_CHOWN
          volumeMounts:
          - name: bootstrap-custom
            mountPath: "/container/service/slapd/assets/config/bootstrap/ldif/custom"
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - preference:
              matchExpressions:
              - key: workload.sas.com/class
                operator: In
                values:
                - stateless
              matchFields: []
            weight: 100
          - preference:
              matchExpressions:
              - key: workload.sas.com/class
                operator: NotIn
                values:
                - compute
                - cas
                - stateful
                - connect
              matchFields: []
            weight: 50
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.azure.com/mode
                operator: NotIn
                values:
                - system
              matchFields: []
      tolerations:
      - effect: NoSchedule
        key: workload.sas.com/class
        operator: Equal
        value: stateful
      - effect: NoSchedule
        key: workload.sas.com/class
        operator: Equal
        value: stateless
      volumes:
      - name: bootstrap-custom
        emptyDir: {}
      - name: ldap-bootstrap-config
        configMap:
          name: openldap-bootstrap-config
          items:
          - key: LDAP_USERS_CONF
            path: 07-testUsers.ldif
            mode: 0664
          - key: LDAP_GROUPS_CONF
            path: 06-testGroups.ldif
            mode: 0664
      initContainers:
      - name: ldap-init
        image: "${AWS_ACCT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/osixia/openldap:1.3.0"
        command:
          - bash
          - -c
          - "cp -avRL /tmp/ldif/custom/* /container/service/slapd/assets/config/bootstrap/ldif/custom/"
        volumeMounts:
          - name: bootstrap-custom
            mountPath: "/container/service/slapd/assets/config/bootstrap/ldif/custom"
          - name: ldap-bootstrap-config
            mountPath: "/tmp/ldif/custom"
---
apiVersion: v1
kind: Service
metadata:
  name: ldap-svc
spec:
  ports:
    - port: 389
      protocol: TCP
      targetPort: 389
      name: ldap
  selector:
    app: openldap
EOF

echo -e "\n+++Mod complete!"

# build modded viya4-deployment docker container?
echo
read -p "Would you like to build the modded viya4-deployment docker container (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "   What tag would you like to use for the modded container? " -r TAG
    docker build -t viya4-deployment:$TAG viya4-deployment/
    echo -e "\n+++Modded docker container is: viya4-deployment:${TAG}"
fi

# push modded docker container to ECR
echo
read -p "Would you like to push the viya4-deployment:${TAG} docker container to ECR (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

aws ecr create-repository --no-cli-pager --repository-name viya4-deployment

docker tag viya4-deployment:$TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/viya4-deployment:$TAG

aws ecr get-login-password --no-cli-pager --region $AWS_REGION | $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/viya4-deployment:$TAG
