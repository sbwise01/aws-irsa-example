# Constants
export STACK_DIR="$HOME/.kind-irsa"
export ISSUER_HOSTNAME="oidc.home.bradandmarsha.com"

# variables
export ISSUER_HOSTPATH="$ISSUER_HOSTNAME/oidc"
export PRIV_KEY="$STACK_DIR/keys/oidc-issuer.key"
export PUB_KEY="$STACK_DIR/keys/oidc-issuer.key.pub"
export PKCS_KEY="$STACK_DIR/keys/oidc-issuer.pub"

# Create stack directory structure
mkdir -p "$STACK_DIR"

# Generate keys for k8s configuration
rm -rf "$STACK_DIR/keys"
mkdir -p "$STACK_DIR/keys"
mkdir -p "$STACK_DIR/aws"

# Generate a key pair
ssh-keygen -t rsa -b 2048 -f $PRIV_KEY -m pem -N ""

# convert the SSH pubkey to PKCS8
ssh-keygen -e -m PKCS8 -f $PUB_KEY >$PKCS_KEY

# Use the PKCS_KEY to generate the JWKS key set for the JWKS endpoint of the Discovery Bucket
go run -C keys-generator main.go -key "$PKCS_KEY" | jq >"$STACK_DIR/aws/keys.json"

# Create discovery.json
cat templates/aws/discovery.template.json | sed "s;ISSUER_HOSTNAME;${ISSUER_HOSTNAME};g" | sed "s;ISSUER_HOSTPATH;${ISSUER_HOSTPATH};g" >"$STACK_DIR/aws/discovery.json"

# Generate CA thumbprint for OIDC identity provider
export CA_THUMBPRINT=$(openssl s_client -connect $ISSUER_HOSTNAME:443 -servername $ISSUER_HOSTNAME -showcerts </dev/null 2>/dev/null | openssl x509 -in /dev/stdin -sha1 -noout -fingerprint | cut -d '=' -f 2 | tr -d ':')

# print OIDC provisioning instructions
echo ""
echo ""
echo "#################################"
echo "# OIDC provisioning instructions"
echo "#################################"
echo "Copy the file $STACK_DIR/aws/discovery.json to https://$ISSUER_HOSTNAME/.well-known/openid-configuration"
echo "Copy the file $STACK_DIR/aws/keys.json to https://$ISSUER_HOSTNAME/keys.json"
echo ""
echo "Execute the following AWS command to provision the OIDC provider:

aws iam create-open-id-connect-provider --url https://$ISSUER_HOSTPATH --thumbprint-list $CA_THUMBPRINT --client-id-list sts.amazonaws.com
"
