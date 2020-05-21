#!/bin/bash

## -------------------
## (1) setup CA
## -------------------

mkdir -p ca/server
mkdir -p ca/client/admin

docker-compose up -d

#copys the org1-CA server root ceritficate to org1-ca client for tls authentication
cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem

fabric-ca-client enroll -d -u https://ca-mars.alpha.at-admin:ca-alpha-adminpw@0.0.0.0:7054

fabric-ca-client register -d --id.name peer0.mars.alpha.at --id.secret peer0PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name peer1.mars.alpha.at --id.secret peer1PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name admin-mars.alpha.at --id.secret marsAdminPW --id.type admin -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name user-mars.alpha.at --id.secret marsUserPW --id.type user -u https://0.0.0.0:7054


## -------------------
## (2) setup admin
## -------------------

mkdir  -p admin/ca
cp ./ca/server/crypto/ca-cert.pem ./admin/ca/mars.alpha.at-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/mars.alpha.at-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://admin-mars.alpha.at:marsAdminPW@0.0.0.0:7054


# here we are creating admincerts directory in every peer msp so that all the peers including the orderer have there  org's admin cert there
mkdir -p peers/peer0/msp/admincerts
mkdir -p peers/peer1/msp/admincerts
mkdir -p admin/msp/admincerts

cp ./admin/msp/signcerts/cert.pem ./peers/peer0/msp/admincerts/mars.alpha.at-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./peers/peer1/msp/admincerts/mars.alpha.at-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./admin/msp/admincerts/mars.alpha.at-admin-cert.pem

## -------------------
## (3) setup peers
## -------------------

mkdir -p peers/peer0/assets/ca
mkdir peers/peer0/assets/tls-ca

#copying  org1 root certificate to peer0-org1
cp ./ca/server/crypto/ca-cert.pem ./peers/peer0/assets/ca/mars.alpha.at-ca-cert.pem
#copying TLS-CA root certificate to  peer0-org1 for tls authentication
cp ../tls.alpha.at/ca/server/crypto/ca-cert.pem ./peers/peer0/assets/tls-ca/tls-ca-cert.pem

#################################################################
################ configuring the environment ####################
#################################################################

# peer0-org1 enrolling with org1-ca
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer0/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/mars.alpha.at-ca-cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.alpha.at:peer0PW@0.0.0.0:7054

# peer0-mars.universe.at enrolling with TLS-CA to get tls certificate
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://peer0.mars.alpha.at:peer0PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer0.mars.alpha.at

mv peers/peer0/tls-msp/keystore/*_sk peers/peer0/tls-msp/keystore/key.pem

# peer1-org1 enrolling with org1-ca

mkdir -p peers/peer1/assets/ca
mkdir  peers/peer1/assets/tls-ca

cp ./ca/server/crypto/ca-cert.pem ./peers/peer1/assets/ca/mars.alpha.at-ca-cert.pem
cp ../tls.alpha.at/ca/server/crypto/ca-cert.pem ./peers/peer1/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer1/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/mars.alpha.at-ca-cert.pem

fabric-ca-client enroll -d -u https://peer1.mars.alpha.at:peer1PW@0.0.0.0:7054

# peer1-mars.universe.at enrolling with TLS-CA to get tls certificate
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://peer1.mars.alpha.at:peer1PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer1.mars.alpha.at
mv peers/peer1/tls-msp/keystore/*_sk peers/peer1/tls-msp/keystore/key.pem

# ---------------------
# setup MSP
# ---------------------

#################################################################
###############       msp-org1 setup               ##############
#################################################################

mkdir -p msp/admincerts
mkdir  msp/cacerts
mkdir  msp/tlscacerts
mkdir  msp/users

# copying org1 root ca certificat to msp/cacerts directory.
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/mars.alpha.at-ca-cert.pem
# copying TLS CA root certificat to msp/tlscacerts directory.
cp ../tls.alpha.at/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/tls-ca-cert.pem
# copying org1 admin singning certificat to msp/admincerts directory.
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/mars.alpha.at-admin-cert.pem

# -------------------------------------------------------
# (5) add config.yaml into msp
# ------------------------------------------------------
vi msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/mars.alpha.at-ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/mars.alpha.at-ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/mars.alpha.at-ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/mars.alpha.at-ca-cert.pem
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
