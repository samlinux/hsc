#!/bin/bash
# -----------------------------------------------------------
# (1) Setup CA for org mars.morgen.net
# creates home directory for TLS-CA Server and TLS-CA client
# -----------------------------------------------------------

mkdir -p ca/server
mkdir -p ca/client/admin

docker-compose up -d

#copys the org1-CA server root ceritficate to org1-ca client for tls authentication
cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem


fabric-ca-client enroll -d -u https://ca-mars.morgen.net-admin:ca-mars-adminpw@0.0.0.0:7054


fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name admin-mars.morgen.net --id.secret marsAdminPW --id.type admin -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name user-mars.morgen.net --id.secret marsUserPW --id.type user -u https://0.0.0.0:7054

# -----------------------------------------------------------
# (2) Setup mars.morgen.net-admin setup  
# -----------------------------------------------------------

mkdir  -p admin/ca

cp ./ca/server/crypto/ca-cert.pem ./admin/ca/mars.morgen.net-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/mars.morgen.net-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://admin-mars.morgen.net:marsAdminPW@0.0.0.0:7054


# here we are creating admincerts dierctory in every peer msp so that all the peers including the orderer have there  org's admin cert there
mkdir -p peers/peer0/msp/admincerts
mkdir -p peers/peer1/msp/admincerts
mkdir -p admin/msp/admincerts

cp ./admin/msp/signcerts/cert.pem ./peers/peer0/msp/admincerts/mars.morgen.net-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./peers/peer1/msp/admincerts/mars.morgen.net-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./admin/msp/admincertsmars.morgen.net-admin-cert.pem

# -----------------------------------------------------------
# (3) Setup peers
# -----------------------------------------------------------

mkdir -p peers/peer0/assets/ca
mkdir  peers/peer0/assets/tls-ca

#copying  org1 root certificate to peer1-org1
cp ./ca/server/crypto/ca-cert.pem ./peers/peer0/assets/ca/mars.morgen.net-ca-cert.pem
#copying TLS-CA root certificate to  peer1-org1 for tls authentication
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./peers/peer0/assets/tls-ca/tls-ca-cert.pem

# peer0-org1 enrolling with org1-ca
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer0/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/mars.morgen.net-ca-cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@0.0.0.0:7054


# peer0-mars.morgen.netenrolling with TLS-CA to get tls certificate
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer0.mars.morgen.net

mv peers/peer0/tls-msp/keystore/*_sk peers/peer0/tls-msp/keystore/key.pem

# peer1-org1 enrolling with org1-ca

mkdir -p peers/peer1/assets/ca
mkdir  peers/peer1/assets/tls-ca

cp ./ca/server/crypto/ca-cert.pem ./peers/peer1/assets/ca/mars.morgen.net-ca-cert.pem
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./peers/peer1/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer1/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/mars.morgen.net-ca-cert.pem

fabric-ca-client enroll -d -u https://peer1.mars.morgen.net:peer1PW@0.0.0.0:7054

# peer1-mars.morgen.net enrolling with TLS-CA to get tls certificate
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://peer1.mars.morgen.net:peer1PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer1.mars.morgen.net
mv peers/peer1/tls-msp/keystore/*_sk peers/peer1/tls-msp/keystore/key.pem

# -----------------------------------------------------------
# (4) Setup MSP
# -----------------------------------------------------------
mkdir -p msp/admincerts
mkdir  msp/cacerts
mkdir  msp/tlscacerts
mkdir  msp/users

# copying org1 root ca certificat to msp/cacerts directory.
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/mars.morgen.net-ca-cert.pem
# copying TLS CA root certificat to msp/tlscacerts directory.
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/tls-ca-cert.pem
# copying org1 admin singning certificat to msp/admincerts directory.
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/mars.morgen.net-admin-cert.pem

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