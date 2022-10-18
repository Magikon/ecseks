#!/usr/bin/env bash
export AWS_PROFILE=zerosso
export AWS_REGION=us-west-2
export AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
helm uninstall zerosystemsapi
eksctl delete iamserviceaccount --name secretsmanager-policy-sa --cluster zerosystems-cluster
kubectl delete -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
helm uninstall -n kube-system csi-secrets-store
helm uninstall -n kube-system aws-load-balancer-controller
helm repo remove eks secrets-store-csi-driver zerosystemsapi
eksctl delete iamserviceaccount --name aws-load-balancer-controller --cluster=zerosystems-cluster
eksctl delete cluster -f ./eksctl.yaml
aws iam delete-policy --policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/AWSLoadBalancerControllerIAMPolicy
aws iam delete-policy --policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/secretsmanager-policy
