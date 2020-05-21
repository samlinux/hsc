# (1) we enter the mars-cli on peer0
docker exec -it cli-mars.morgen.net bash 

# (1.1) these are the needed environment vars (for peer0 these are alredy set in the docker-compose.file)
export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.morgen.net/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"

# install the chaincode
peer chaincode install -n sacc-abac -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc-abac/go

# you can check if the chaincode is installed
peer chaincode list --installed

# (1.2) we instantiate the chaincode (only on peer0)
peer chaincode instantiate -n sacc-abac -v 1.0 -o orderer.morgen.net:7050 -C channel1  -c '{"Args":["msg","hello abac"]}' --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# (1.3) we can query the chaincode via cli
peer chaincode query -n sacc-abac -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# (1.4) set a new value
peer chaincode invoke -n sacc-abac -c '{"Args":["set", "msg","hello fabric"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem


# -----------------------------------------------------------
# (2) Setup ./users/user-mars.morgen.net setup  
# -----------------------------------------------------------

# (2.1) we create the admin ca base folder
mkdir  -p users/ca
mkdir users/user2-mars.morgen.net
mkdir users/user3-mars.morgen.net

# (2.2) we copy ca-cert file
cp ./ca/server/crypto/ca-cert.pem ./users/ca/mars.morgen.net-ca-cert.pem

# (1.5) we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./users/user3-mars.morgen.net
export FABRIC_CA_CLIENT_TLS_CERTFILES=../ca/mars.morgen.net-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

# (2.3) we enroll the user
fabric-ca-client enroll -d -u https://user3-mars.morgen.net:marsUserPW@0.0.0.0:7054

vi users/user3-mars.morgen.net/msp/config.yaml
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


docker exec -it cli-mars.morgen.net bash 

export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.morgen.net/users/user3-mars.morgen.net/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"

peer chaincode query -n sacc-abac -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer chaincode invoke -n sacc-abac -c '{"Args":["set", "msg","hello abac - user3-1"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem


peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem


# check certs
openssl x509 -noout -text -in mars.morgen.net-admin-cert.pem
