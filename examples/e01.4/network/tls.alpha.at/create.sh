#!/usr/bin/env bash
# creates home directory for TLS-CA Server and TLS-CA client

mkdir -p ca/server/crypto
mkdir -p ca/client/crypto

# starts the tls-ca server
docker-compose up

#copys the tls-CA server root ceritficate to tls-ca client for tls authentication
cp ./ca/server/crypto/ca-cert.pem  ./ca/client/crypto/ca-tls.alpha.at.cert.pem

export FABRIC_CA_CLIENT_HOME=./ca/client
export FABRIC_CA_CLIENT_TLS_CERTFILES=crypto/ca-tls.alpha.at.cert.pem

# Enroll ca-tls.alpha.at-admin and register tls-identities

fabric-ca-client enroll -d -u https://ca-tls.alpha.at-admin:ca-tls.alpha.at-adminpw@0.0.0.0:7052

fabric-ca-client register -d --id.name peer0.mars.alpha.at --id.secret peer0PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer1.mars.alpha.at --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name orderer.alpha.at --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052
