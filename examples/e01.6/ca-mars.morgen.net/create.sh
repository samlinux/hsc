# -----------------------------------------------------------
# (1) Setup CA for org mars.morgen.net
# creates home directory for TLS-CA Server and TLS-CA client
# -----------------------------------------------------------

# (1.1) we create base folders
mkdir -p ca/server
mkdir -p ca/client/admin

# (1.2) first we start the mars-ca server with the init parameter
# for this, we replace in the docker-compose file the start command with init (from start => init => start)
# if you do not change the server config you can start the server directly with this command
## command: sh -c 'fabric-ca-server start -d -b ca-mars.morgen.net-admin:ca-mars-adminpw --port 7054'

# then start the docker-composition
docker-compose up

# (1.3) give the $USER the proper rights to change the config
sudo chown $USER ca/server/crypto/fabric-ca-server-config.yaml

# (1.4) we can modify some config values
# for now we change the following
#  - ca.name: ca-mars.morgen.net

# If you modified any of the values in the csr block of the configuration .yaml file, 
# you need to delete the fabric-ca-server-tls/ca-cert.pem file and the entire fabric-ca-server-tls/msp folder. 
# These certificates will be re-generated when you start the CA server in the next step.

# (1.5) we modify the docker start command from init to start
# we starts the mars-ca server
docker-compose up -d

# (1.6) we copy the mars-ca server root ceritficate to tls-ca client for tls authentication
# is also known as the TLS CA’s signing certificate is going to be used to validate the TLS certificate of the CA
cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem

# (1.7) we set needed environment vars
# the client run commands against the TLS-CA
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem

# (1.8) we enroll ca-mars.morgen-net-admin and register tls-identities
fabric-ca-client enroll -d -u https://ca-mars.morgen.net-admin:ca-mars-adminpw@0.0.0.0:7054

# (1.9) register the mars members of the network
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name admin-mars.morgen.net --id.secret marsAdminPW --id.type admin -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name user-mars.morgen.net --id.secret marsUserPW --id.type user -u https://0.0.0.0:7054

# -----------------------------------------------------------
# (2) Setup mars.morgen.net-admin setup  
# -----------------------------------------------------------

# (2.1) we create the admin ca base folder
mkdir  -p admin/ca

# (2.2) we copy ca-cert file
cp ./ca/server/crypto/ca-cert.pem ./admin/ca/mars.morgen.net-ca-cert.pem

# (2.3) we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/mars.morgen.net-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

# (2.3) we enroll the admin
fabric-ca-client enroll -d -u https://admin-mars.morgen.net:marsAdminPW@0.0.0.0:7054

# (2.4) we are creating admincerts dierctory in every peer msp so that all the peers 
# including the organization have there org's admin cert there
mkdir -p peers/peer0/msp/admincerts
mkdir -p peers/peer1/msp/admincerts
mkdir -p admin/msp/admincerts

cp ./admin/msp/signcerts/cert.pem ./peers/peer0/msp/admincerts/mars.morgen.net-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./peers/peer1/msp/admincerts/mars.morgen.net-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./admin/msp/admincertsmars.morgen.net-admin-cert.pem

# -----------------------------------------------------------
# (3) Setup peers
# -----------------------------------------------------------

## ------------------
## (3.1) enroll peer0 
## ------------------

# (3.1.1) we create base peers folder
mkdir -p peers/peer0/assets/{ca,tls-ca}

# (3.1.2) copy orgs root certificate to the peer
cp ./ca/server/crypto/ca-cert.pem ./peers/peer0/assets/ca/mars.morgen.net-ca-cert.pem

# (3.1.3) copying TLS-CA root certificate to the peer for tls authentication
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./peers/peer0/assets/tls-ca/tls-ca-cert.pem

# (3.1.4) enroll the peer0 against ca from mars.morgen.net
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer0/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/mars.morgen.net-ca-cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@0.0.0.0:7054

# (3.1.5) peer0-mars.morgen.net enrolling with TLS-CA to get the tls certificate
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer0.mars.morgen.net

# (3.1.6) rename the private key from tls-ca
mv peers/peer0/tls-msp/keystore/*_sk peers/peer0/tls-msp/keystore/key.pem

## ------------------
## (3.2) enroll peer1 
## ------------------

# (3.2.1) we create base peers folder
mkdir -p peers/peer1/assets/{ca,tls-ca}

# (3.2.2) copy orgs root certificate to the peer
cp ./ca/server/crypto/ca-cert.pem ./peers/peer1/assets/ca/mars.morgen.net-ca-cert.pem

# (3.2.3) copying TLS-CA root certificate to the peer for tls authentication
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./peers/peer1/assets/tls-ca/tls-ca-cert.pem

# (3.2.4) enroll the peer1 against ca from mars.morgen.net
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer1/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/mars.morgen.net-ca-cert.pem

fabric-ca-client enroll -d -u https://peer1.mars.morgen.net:peer1PW@0.0.0.0:7054

# (3.2.5) peer1-mars.morgen.net enrolling with TLS-CA to get the tls certificate
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://peer1.mars.morgen.net:peer1PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer1.mars.morgen.net

# (3.2.6) rename the private key from tls-ca
mv peers/peer1/tls-msp/keystore/*_sk peers/peer1/tls-msp/keystore/key.pem

# -----------------------------------------------------------
# (4) Setup MSP
# -----------------------------------------------------------

# (4.1) create the MSP folder for org mars.morgen.net
mkdir -p msp/{admincerts,cacerts,tlscacerts,users}

# (4.2) copying org mars root ca certificat to msp/cacerts directory
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/mars.morgen.net-ca-cert.pem

# (4.3) copying TLS CA root certificat to msp/tlscacerts directory
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/tls-ca-cert.pem

# (4.5) copying org mars admin singning certificat to msp/admincerts directory
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/mars.morgen.net-admin-cert.pem

# -----------------------------------------------------------
# (5) config.yaml
# -----------------------------------------------------------
vi msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: orderer
    

vi admin/msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: orderer
    