#!/bin/bash

# ============================================================
# create-eks-cluster.sh
# Purpose: Create an EKS cluster with 2 worker nodes using eksctl
# ============================================================

set -e   # agar koi command fail ho jaye to script turant ruk jayega

# -------- CONFIG (yaha apni values check/change kar sakta hai) --------
CLUSTER_NAME="mukesh-eks-cluster"
REGION="ap-south-1"          # tera ECR bhi isi region me hai (Mumbai)
NODE_TYPE="c7i-flex.large"        # cost-effective instance for lab/testing
NODE_COUNT=1                 # fixed 2 worker nodes (min=max=desired=2)
K8S_VERSION="1.35"           # stable current version, change if needed

# -------- Pre-check: eksctl aur aws cli installed hai ya nahi --------
if ! command -v eksctl &> /dev/null
then
    echo "eksctl not found. Installing eksctl..."
    curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

if ! command -v aws &> /dev/null
then
    echo "AWS CLI not found. Please install AWS CLI first: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# -------- Confirm AWS credentials are configured --------
echo "Checking AWS identity..."
aws sts get-caller-identity

# ============================================================
# MAIN COMMAND: create the EKS cluster
# ============================================================
# --name             : cluster ka naam
# --region            : AWS region jaha cluster banega
# --version           : Kubernetes version
# --nodegroup-name    : worker node group ka naam
# --node-type         : EC2 instance type for worker nodes
# --nodes             : desired number of worker nodes (2)
# --nodes-min/max     : autoscaling range (yaha fixed 2 rakha hai)
# --managed           : AWS-managed nodegroup (recommended, AWS handles patching)
# ============================================================

echo "Creating EKS cluster: $CLUSTER_NAME in $REGION with $NODE_COUNT worker nodes..."

eksctl create cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --version "$K8S_VERSION" \
  --nodegroup-name "$CLUSTER_NAME-nodegroup" \
  --node-type "$NODE_TYPE" \
  --nodes "$NODE_COUNT" \
  --nodes-min "$NODE_COUNT" \
  --nodes-max "$NODE_COUNT" \
  --managed

# ============================================================
# Post-create: verify cluster and nodes
# ============================================================
echo ""
echo "Cluster created! Verifying nodes..."
kubectl get nodes -o wide

echo ""
echo "Verifying cluster info..."
kubectl cluster-info

echo ""
echo "DONE. Your EKS cluster '$CLUSTER_NAME' is ready with $NODE_COUNT worker nodes."
echo "kubeconfig has been auto-updated by eksctl (~/.kube/config)."
