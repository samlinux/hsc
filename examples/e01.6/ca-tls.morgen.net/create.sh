# -----------------------------------------------------------
# (1) Setup TLS-CA for morgen.net 
# creates home directory for TLS-CA Server and TLS-CA client
# -----------------------------------------------------------

# (1.1) we create base folders
mkdir -p ca/server/crypto
mkdir -p ca/client/crypto

# (1.2) first we start the tls-ca server with the init parameter
# for this, we replace in the docker-compose file the start command with init (from start => init => start)
# if you do not change the server config you can start the server directly with this command
## command: sh -c 'fabric-ca-server start -d -b ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw --port 7052'

# then start the docker-composition
docker-compose up

# (1.3) give the $USER the right to change the config
sudo chown $USER ca/server/crypto/fabric-ca-server-config.yaml

# (1.4) we can modify some config values
# for now we change the following
#  - ca.name: ca-tls.morgen.net

# If you modified any of the values in the csr block of the configuration .yaml file, 
# you need to delete the fabric-ca-server-tls/ca-cert.pem file and the entire fabric-ca-server-tls/msp folder. 
# These certificates will be re-generated when you start the CA server in the next step.

# (1.5) we modify the docker start command from init to start
# we starts the tls-ca server
docker-compose up -d

# (1.6) we copy the tls-CA server root ceritficate to tls-ca client for tls authentication
# is also known as the TLS CA’s signing certificate is going to be used to validate the TLS certificate of the CA
cp ./ca/server/crypto/ca-cert.pem  ./ca/client/crypto/ca-tls.morgen.net.cert.pem

# (1.7) we set needed environment vars
# the client run commands against the TLS-CA
export FABRIC_CA_CLIENT_HOME=./ca/client
export FABRIC_CA_CLIENT_TLS_CERTFILES=crypto/ca-tls.morgen.net.cert.pem

# (1.8) we enroll ca-tls.morgen-net-admin and register tls-identities
fabric-ca-client enroll -d -u https://ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw@0.0.0.0:7052

# (1.9) register the tls members of the network (peers and orderer)
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052