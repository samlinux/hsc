# data in this example are persistent
# to stop the network call docker-compose down
# to start the network call docker-compose start


# clear for restart network if not persistent
# you can clear da network data, but not the artifacts
rm -r ./ca-orderer.morgen.net/orderer/genesis.block
rm -r ./ca-mars.morgen.net/peers/peer0/assets/channel.tx

sudo rm ./ca-mars.morgen.net/peers/peer0/assets/channel1.block
sudo rm ./ca-mars.morgen.net/peers/peer1/assets/channel1.block

sudo rm -R ./ca-mars.morgen.net/peers/peer0/production/
sudo rm -R ./ca-mars.morgen.net/peers/peer1/production/

## if you want to start from the ground clear all artifacts
## ---- BE CAREFULLY -----
# clear tls-ca.morgen.net
sudo rm -R ca-tls.morgen.net/ca/

# clear ca-orderer.morgen.net
sudo rm -R ca-orderer.morgen.net/admin/
sudo rm -R ca-orderer.morgen.net/ca
sudo rm -R ca-orderer.morgen.net/orderer

# ------------------------------
# how to setup the network
# ------------------------------
## (1) ca-tls.morgen.net 
### start with the create.sh script

## (2) ca-orderer.morgen.net 
### start with the create.sh script

## (3) ca-mars.morgen.net 
### start with the create.sh script

# ------------------------------
# create genesis block
# ------------------------------
configtxgen -profile OneOrgOrdererGenesis -channelID orderersyschannel -outputBlock ./ca-orderer.morgen.net/orderer/genesis.block

# ------------------------------
# create channelTx
# ------------------------------
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./ca-mars.morgen.net/peers/peer0/assets/channel.tx -channelID channel1

# ------------------------------
# we start the network
# ------------------------------
docker-compose up -d
docker-compose logs --follow

# ------------------------------
# we create the channel cia cli
# we install the chaincode
# we query the blockchain
# ------------------------------

docker exec -it cli-mars.morgen.net bash 

export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.morgen.net/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"

peer channel create -c channel1 -f /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel.tx -o orderer.morgen.net:7050 --outputBlock /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel1.block --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer channel join -b /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel1.block
exit

cp ./ca-mars.morgen.net/peers/peer0/assets/channel1.block ./ca-mars.morgen.net/peers/peer1/assets/channel1.block

### peer1
docker exec -it cli-mars.morgen.net bash 
export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.morgen.net/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer1.mars.morgen.net:7051"


# not working at the moment ?? why ??
## peer channel fetch newest channel1.block -c channel1 --orderer orderer.morgen.net:7050

peer channel join -b /tmp/hyperledger/mars.morgen.net/peers/peer1/assets/channel1.block


## Install chaincode on peer0
export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.morgen.net/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"

peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/
peer chaincode list --installed


# instantiate the chaincode (only on peer0)
peer chaincode instantiate -n sacc -v 1.0 -o orderer.morgen.net:7050 -C channel1  -c '{"Args":["msg","hello blockchain"]}' --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem


peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer chaincode invoke -n sacc -c '{"Args":["set", "msg","hello fabric"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem


## change to peer1
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer1.mars.morgen.net:7051"

peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/
peer chaincode list --installed

# query peer 1
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer chaincode invoke -n sacc -c '{"Args":["set", "msg","hello morgen.net"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# check certs
openssl x509 -noout -text -in mars.morgen.net-admin-cert.pem
