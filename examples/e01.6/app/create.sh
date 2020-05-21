# clear the wallet
sudo rm -R wallet

# enroll the admin
node enrollAdmin.js

# register and enroll the application user
node register.js

# query some data
node query.js key

# invoke some data
node invoke.js key value

cd ca-mars.morgen.net
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem
fabric-ca-client identity list --id user1
