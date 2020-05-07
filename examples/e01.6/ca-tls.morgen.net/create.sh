# -----------------------------------------------------------
# Setup TLS-CA for morgen.net
# creates home directory for TLS-CA Server and TLS-CA client
# -----------------------------------------------------------

# we create base folders
mkdir -p ca/server/crypto
mkdir -p ca/client/crypto

# we starts the tls-ca server
docker-compose up -d

# we copy the tls-CA server root ceritficate to tls-ca client for tls authentication
# is also known as the TLS CA’s signing certificate is going to be used to validate the TLS certificate of the CA
cp ./ca/server/crypto/ca-cert.pem  ./ca/client/crypto/ca-tls.morgen.net.cert.pem

# we set needed environment vars
# the client run commands against the TLS-CA
export FABRIC_CA_CLIENT_HOME=./ca/client
export FABRIC_CA_CLIENT_TLS_CERTFILES=crypto/ca-tls.morgen.net.cert.pem

# we enroll ca-tls.morgen-net-admin and register tls-identities
fabric-ca-client enroll -d -u https://ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw@0.0.0.0:7052

# register the tls members of the network (peers and orderer)
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052