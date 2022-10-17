#!/usr/bin/env bash

echo "Please input variables or push Enther for default values"
read -p "Please input: AWS_PROFILE: Default: default: " AWS_PROFILE
read -p "Please input: AWS_REGION: Default: us-east-1: " AWS_REGION
read -p "Please input: CLUSTER_NAME: Default: zerosystems-cluster: " CLUSTER_NAME
read -p "Please input CIDR for VPC: Default: 10.8.0.0/16: " CIDR
read -p "Do You use AWS GovCloud? type no or yes: Default: No: " GovCloud 

read -p "Please find in https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html this number: " NUMBER_OF_IMAGE
read -p "Please enter certificate ARN: " CERT_ARN
read -p "Please enter secret name: " SECRET_NAME

export AWS_PROFILE=${AWS_PROFILE:-"default"}
export AWS_REGION=${AWS_REGION:-"us-east-1"}
export CLUSTER_NAME=${CLUSTER_NAME:-"zerosystems-cluster"}
export CIDR=${CIDR:-"10.8.0.0/16"}
GovCloud=${GovCloud:-"no"}

echo "-----------------"
echo "Profile name is $AWS_PROFILE"
echo "Region is $AWS_REGION"
echo "Cluster name is $CLUSTER_NAME"
echo "CIDR is $CIDR"
echo "-----------------"

cp --remove-destination zero-eksctl-template.yaml eksctl.yaml
CIDR=$(sed 's/[&//]/\\&/g' <<<"$CIDR") 

sed -i "s/AWS_REGION/${AWS_REGION}/g" eksctl.yaml
sed -i "s/CLUSTER_NAME/${CLUSTER_NAME}/g" eksctl.yaml
sed -i "s/CIDR/${CIDR}/g" eksctl.yaml

eksctl create cluster -f ./eksctl.yaml
export VPC_ID=$(aws ec2 describe-vpcs --region ${AWS_REGION} --filter Name=tag:Name,Values=eksctl-${CLUSTER_NAME}-cluster/VPC --query 'Vpcs[].VpcId' --output text)
export AWS_ACCOUNT=$(aws sts get-caller-identity --profile ${AWS_PROFILE} --query 'Account' --output text)

echo "-----------------"
echo "VPC_ID name is $VPC_ID"
echo "AWS_ACCOUNT is $AWS_ACCOUNT"
echo "-----------------"

if [ "$GovCloud" = "yes" ]
then
  curl -o iam_policy_us-gov.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.3/docs/install/iam_policy_us-gov.json
  POLICY_ALB_ARN=$(aws --query Policy.Arn --output text iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy_us-gov.json)
else
  curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.3/docs/install/iam_policy.json
  POLICY_ALB_ARN=$(aws --query Policy.Arn --output text iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json)
fi

eksctl create iamserviceaccount \
--cluster=${CLUSTER_NAME} \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--role-name "AmazonEKSLoadBalancerControllerRoleZero" \
--attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT}:policy/AWSLoadBalancerControllerIAMPolicy \
--approve

kubectl annotate serviceaccount -n kube-system aws-load-balancer-controller eks.amazonaws.com/sts-regional-endpoints=true 

helm repo add eks https://aws.github.io/eks-charts
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo add zerosystemsapi https://charts.zerosystems.sbs
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=${AWS_REGION} \
  --set vpcId=${VPC_ID} \
  --set image.repository=${NUMBER_OF_IMAGE}.dkr.ecr.${AWS_REGION}.amazonaws.com/amazon/aws-load-balancer-controller
  
helm install -n kube-system --set syncSecret.enabled=true csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

POLICY_ARN=$(aws --query Policy.Arn --output text iam create-policy --policy-name secretsmanager-policy --policy-document '{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": [
"secretsmanager:GetSecretValue",
"secretsmanager:DescribeSecret"
],
"Resource": "*"
},
{
"Effect": "Allow",
"Action": "ecr:*",
"Resource": "*"
}
]
}')

eksctl create iamserviceaccount --name secretsmanager-policy-sa --cluster ${CLUSTER_NAME} --attach-policy-arn "$POLICY_ARN" --approve --override-existing-serviceaccounts

helm install ${CLUSTER_NAME} zerosystemsapi/zeroconnectapi --version 1.9.0 --atomic --set secretsName=${SECRET_NAME} --set ingress.certificateARN=${CERT_ARN} --set image.tag=1.9.0.41


echo "#!/usr/bin/env bash" > ./delete.sh
echo "export AWS_PROFILE=${AWS_PROFILE}" >> ./delete.sh
echo "export AWS_REGION=${AWS_REGION}" >> ./delete.sh
echo "helm uninstall ${CLUSTER_NAME}" >> ./delete.sh
echo "eksctl delete iamserviceaccount --name secretsmanager-policy-sa --cluster ${CLUSTER_NAME}" >> ./delete.sh
echo "aws iam delete-policy --policy-arn ${POLICY_ARN}" >> ./delete.sh
echo "kubectl delete -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml" >> ./delete.sh
echo "helm uninstall -n kube-system csi-secrets-store" >> ./delete.sh
echo "helm install -n kube-system aws-load-balancer-controller" >> ./delete.sh
echo "eksctl delete iamserviceaccount --name aws-load-balancer-controller --cluster=${CLUSTER_NAME}" >> ./delete.sh
echo "aws iam delete-policy --policy-arn ${POLICY_ALB_ARN}" >> ./delete.sh
echo "eksctl delete cluster -f ./eksctl.yaml" >> ./delete.sh

chmod +x ./delete.sh