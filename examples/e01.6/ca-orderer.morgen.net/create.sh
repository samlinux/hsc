# -----------------------------------------------------------
# (1) Setup orderer CA for morgen.net
# creates home directory for TLS-CA Server and TLS-CA client
# -----------------------------------------------------------

# we create the base folders
mkdir -p ca/server
mkdir -p ca/client/admin

# we start the CA
docker-compose up -d

# we copy the tls-ca-cert file
cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem

# we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem

# we enroll ca-tls.morgen-net-admin and register tls-identities
fabric-ca-client enroll -d -u https://ca-orderer.morgen.net-admin:ca-orderer-adminpw@0.0.0.0:7053

# register the members of the network
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
fabric-ca-client register -d --id.name admin-orderer.morgen.net --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://0.0.0.0:7053


# -----------------------------------------------------------
# (2) Setup orderer admin setup
# -----------------------------------------------------------

# we create the admin ca base folder
mkdir  -p admin/ca

# we copy ca-cert file
cp ./ca/server/crypto/ca-cert.pem ./admin/ca/orderer.morgen.net-ca-cert.pem

# we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/orderer.morgen.net-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

# we enroll the admin
fabric-ca-client enroll -d -u https://admin-orderer.morgen.net:org0adminpw@0.0.0.0:7053

# -----------------------------------------------------------
# copy the certificate from this admin MSP
# and move it to the orderer MSP in 
# the admincerts folder
# -----------------------------------------------------------

mkdir -p orderer/msp/admincerts
mkdir -p admin/msp/admincerts

cp ./admin/msp/signcerts/cert.pem ./orderer/msp/admincerts/orderer.morgen.net-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./admin/msp/admincerts/orderer.morgen.net-admin-cert.pem

# -----------------------------------------------------------
# (3) Setup orderer
# -----------------------------------------------------------

mkdir -p orderer/assets/ca
mkdir  orderer/assets/ca-tls.morgen.net

cp ./ca/server/crypto/ca-cert.pem ./orderer/assets/ca/orderer.morgen.net-ca-cert.pem
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./orderer/assets/ca-tls.morgen.net/tls-ca-cert.pem

#################################################################
################ configuring the environment ####################
#################################################################

export FABRIC_CA_CLIENT_HOME=./orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/orderer.morgen.net-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererpw@0.0.0.0:7053

export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca-tls.morgen.net/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts orderer.morgen.net

mv ./orderer/tls-msp/keystore/*_sk ./orderer/tls-msp/keystore/key.pem

# -----------------------------------------------------------
# (4) Setup MSP
# -----------------------------------------------------------
mkdir -p msp/admincerts
mkdir  msp/cacerts
mkdir  msp/tlscacerts
mkdir  msp/users

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