#!/bin/bash

export CERT_MANAGER_RBAC_ENABLED="true"
export CERT_MANAGER_ISSUER_NAME="letsencrypt-prod"
export CERT_MANAGER_ISSUER_KIND="ClusterIssuer"
export CERT_MANAGER_ISSUER_MAIL="me@nalbam.com"
export CERT_MANAGER_IAM_ROLE=

export ARGO_INGRESS_HOST="argo-devops.spot.mzdev.be"
export ARGO_BUCKET="seoul-dev-spot-eks-argo"
