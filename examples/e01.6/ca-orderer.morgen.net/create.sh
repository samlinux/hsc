# -----------------------------------------------------------
# (1) Setup orderer CA for morgen.net
# creates home directory for TLS-CA Server and TLS-CA client
# -----------------------------------------------------------

# (1.1) we create the base folders
mkdir -p ca/server
mkdir -p ca/client/admin

# (1.2) first we start the orderer-ca server with the init parameter
# for this, we replace in the docker-compose file the start command with init (from start => init => start)
# if you do not change the server config you can start the server directly with this command
## command: sh -c 'fabric-ca-server start -d -b ca-orderer.morgen.net-admin:ca-orderer-adminpw --port 7053'

# then start the docker-composition
docker-compose up

# (1.3) give the $USER the right to change the config
sudo chown $USER ca/server/crypto/fabric-ca-server-config.yaml

# (1.4) we can modify some config values
# for now we change the following
#  - ca.name: ca-orderer.morgen.net

# If you modified any of the values in the csr block of the configuration .yaml file, 
# you need to delete the fabric-ca-server-tls/ca-cert.pem file and the entire fabric-ca-server-tls/msp folder. 
# These certificates will be re-generated when you start the CA server in the next step.

# (1.5) we modify the docker start command from init to start
# we starts the orderer-ca server
docker-compose up -d

# (1.6) we copy the tls-ca-cert file
cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem

# 1.7) we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem

# 1.8) we enroll ca-tls.morgen-net-admin and register tls-identities
fabric-ca-client enroll -d -u https://ca-orderer.morgen.net-admin:ca-orderer-adminpw@0.0.0.0:7053

# 1.9) register the members of the network
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
fabric-ca-client register -d --id.name admin-orderer.morgen.net --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://0.0.0.0:7053

# -----------------------------------------------------------
# (2) Setup orderer admin setup
# -----------------------------------------------------------

# (2.1) we create the admin ca base folder
mkdir  -p admin/ca

# (2.2) we copy ca-cert file
cp ./ca/server/crypto/ca-cert.pem ./admin/ca/orderer.morgen.net-ca-cert.pem

# (2.3) we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/orderer.morgen.net-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

# (2.3) we enroll the admin
fabric-ca-client enroll -d -u https://admin-orderer.morgen.net:org0adminpw@0.0.0.0:7053

# (2.4) copy the certificate from this admin MSP
# and move it to the orderer MSP in 
# the admincerts folder

mkdir -p orderer/msp/admincerts
mkdir -p admin/msp/admincerts

cp ./admin/msp/signcerts/cert.pem ./orderer/msp/admincerts/orderer.morgen.net-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./admin/msp/admincerts/orderer.morgen.net-admin-cert.pem

# -----------------------------------------------------------
# (3) Setup orderer
# -----------------------------------------------------------

# (3.1) we create the some assets folder for the orderer, these folders are used later at runtime
mkdir -p orderer/assets/ca
mkdir orderer/assets/ca-tls.morgen.net

# (3.2) we copy the certs, ca cert and tls-ca cert
cp ./ca/server/crypto/ca-cert.pem ./orderer/assets/ca/orderer.morgen.net-ca-cert.pem
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./orderer/assets/ca-tls.morgen.net/tls-ca-cert.pem

# (3.3) we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/orderer.morgen.net-ca-cert.pem

# (3.4) we enroll the orderer
fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererpw@0.0.0.0:7053

# (3.5) we enroll the TLS for the orderer
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca-tls.morgen.net/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts orderer.morgen.net

# (3.6) we rename the private key of the orderer for later
mv ./orderer/tls-msp/keystore/*_sk ./orderer/tls-msp/keystore/key.pem

# -----------------------------------------------------------
# (4) Setup then MSP for the orderer
# -----------------------------------------------------------

# (4.1) create MSP base folder structore
mkdir -p msp/{admincerts,cacerts,tlscacerts,users}

# (4.2) copy necessary certs
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/orderer.morgen.net-ca-cert.pem
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/tls-ca-cert.pem
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/orderer.morgen.net-admin-cert.pem

# -----------------------------------------------------------
# (5) config.yaml
# -----------------------------------------------------------
vi msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: orderer