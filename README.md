# aws-irsa-example
Example of building OIDC provider config for use with IAM Roles for Service Accounts

## Usage
1. setup an HTTPS site (see https://github.com/sbwise01/wise-k8s/tree/main/iac/kustomize/aws-iam-oidc-provider)
1. edit constants in `setup.sh` to match local environment
1. run the command `bash setup.sh`
1. Follow the instructions printed out to provision the identity provider


## Credit
https://github.com/liskl/kind-aws-irsa-example
