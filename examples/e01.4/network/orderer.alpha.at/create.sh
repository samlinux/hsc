#!/bin/bash
# -------------------------------------------------------
# (1) setup orderer-ca
# -------------------------------------------------------

mkdir -p ca/server
mkdir -p ca/client/admin

docker-compose up

cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem

fabric-ca-client enroll -d -u https://ca-orderer.alpha.at-admin:ca-orderer-adminpw@0.0.0.0:7053

fabric-ca-client register -d --id.name orderer.alpha.at --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
fabric-ca-client register -d --id.name admin-orderer.alpha.at --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://0.0.0.0:7053

# -------------------------------------------------------
# (2) setup orderer-admin
# -------------------------------------------------------

mkdir  -p admin/ca

# cp ./ca/server/crypto/ca-cert.pem ./admin/ca/org0-ca-cert.pem
cp ./ca/server/crypto/ca-cert.pem ./admin/ca/orderer.alpha.at-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/orderer.alpha.at-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-orderer.alpha.at:org0adminpw@0.0.0.0:7053

# -------------------------------------------------------
######  copy the certificate from this admin MSP
######  and move it to the orderer MSP in  the admincerts folder 

mkdir -p orderer/msp/admincerts
mkdir -p admin/msp/admincerts

cp ./admin/msp/signcerts/cert.pem ./orderer/msp/admincerts/orderer.alpha.at-admin-cert.pem
cp ./admin/msp/signcerts/cert.pem ./admin/msp/admincerts/orderer.alpha.at-admin-cert.pem

# -------------------------------------------------------
# (3) setup orderer
# ------------------------------------------------------

mkdir -p orderer/assets/ca
mkdir orderer/assets/tls.alpha.at

cp ./ca/server/crypto/ca-cert.pem ./orderer/assets/ca/orderer.alpha.at-ca-cert.pem
cp ../tls.alpha.at/ca/server/crypto/ca-cert.pem ./orderer/assets/tls.alpha.at/tls-ca-cert.pem

#################################################################
################ configuring the environment ####################
#################################################################


export FABRIC_CA_CLIENT_HOME=./orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/orderer.alpha.at-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer.alpha.at:ordererpw@0.0.0.0:7053

export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls.alpha.at/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://orderer.alpha.at:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts orderer.alpha.at

mv ./orderer/tls-msp/keystore/*_sk ./orderer/tls-msp/keystore/key.pem

# -------------------------------------------------------
# (4) setup orderer-msp
# ------------------------------------------------------

mkdir -p msp/admincerts
mkdir  msp/cacerts
mkdir  msp/tlscacerts
mkdir  msp/users

# cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/org0-ca-cert.pem
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/orderer.alpha.at-ca-cert.pem
cp ../tls.alpha.at/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/tls-ca-cert.pem
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/orderer.alpha.at-admin-cert.pem


# -------------------------------------------------------
# (5) add config.yaml into msp
# ------------------------------------------------------
vi msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/orderer.alpha.at-ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/orderer.alpha.at-ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/orderer.alpha.at-ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/orderer.alpha.at-ca-cert.pem
    OrganizationalUnitIdentifier: orderer
