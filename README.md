# Skeleton Infrastructure

The Skeleton Infrastructure repo provides the terraform scripts for the following segments of the infrastructure for the main vonMerkatz application and others.

- CI/CD Pipeline (Jenkins Instance)
- NGINX Proxy
- Various management Lambda Scripts

Additionally the GitHub Workflows that handle terraform deployment

Current Dependencies:
- AMIs
- Service Account secrets stored in repo
- SSL Cert and Private key stored in AWS Secrets Manager
- Route 53 updates to point to proxy
