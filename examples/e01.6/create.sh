# data in this example are persistent
# to stop the network call docker-compose down
# to start the network call docker-compose start

# clear chaincode container
docker rm -f $(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')

# clear for restart network if not persistent
# you can clear da network data, but not the artifacts
rm -r ./ca-orderer.morgen.net/orderer/genesis.block
rm -r ./ca-mars.morgen.net/peers/peer0/assets/channel.tx

sudo rm ./ca-mars.morgen.net/peers/peer0/assets/channel1.block
sudo rm ./ca-mars.morgen.net/peers/peer1/assets/channel1.block

sudo rm -R ./ca-mars.morgen.net/peers/peer0/production
sudo rm -R ./ca-mars.morgen.net/peers/peer1/production
sudo rm -R ./ca-orderer.morgen.net/orderer/production

## if you want to start from the ground clear all artifacts
## -----------------------
## ---- BE CAREFULLY -----
## -----------------------

# clear tls-ca.morgen.net
sudo rm -R ca-tls.morgen.net/ca

# clear ca-orderer.morgen.net
sudo rm -R ca-orderer.morgen.net/admin
sudo rm -R ca-orderer.morgen.net/ca
sudo rm -R ca-orderer.morgen.net/orderer

# clear ca-mars.morgen.net
sudo rm -R ca-mars.morgen.net/admin
sudo rm -R ca-mars.morgen.net/ca
sudo rm -R ca-mars.morgen.net/msp 
sudo rm -R ca-mars.morgen.net/peers

# ------------------------------
# how to setup the network
# ------------------------------
## (1) ca-tls.morgen.net 
### start with the create.sh script

## (2) ca-orderer.morgen.net 
### start with the create.sh script

## (3) ca-mars.morgen.net 
### start with the create.sh script

# (4) create genesis block
configtxgen -profile OneOrgOrdererGenesis -channelID orderersyschannel -outputBlock ./ca-orderer.morgen.net/orderer/genesis.block

# (5) create channelTx
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./ca-mars.morgen.net/peers/peer0/assets/channel.tx -channelID channel1

# (6) we start the network
# start the morgen.net network in the background
docker-compose up -d

# jump in to see the logs
docker-compose logs -f

# (7) we enter the mars-cli on peer0
docker exec -it cli-mars.morgen.net bash 

# (7.1) these are the needed environment vars (for peer0 these are alredy set in the docker-compose.file)
export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.morgen.net/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"

# (7.2) we create the channel
peer channel create -c channel1 -f /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel.tx -o orderer.morgen.net:7050 --outputBlock /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel1.block --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# (7.3) we join the channel
peer channel join -b /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel1.block

# (7.4) we switch to peer1 via environment vars 
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer1.mars.morgen.net:7051"

# if you have to copy the file per hand, but this is't needed because usally you can fetch the channel configuration from the latest block
#cp ./ca-mars.morgen.net/peers/peer0/assets/channel1.block ./ca-mars.morgen.net/peers/peer1/assets/channel1.block

# (7.5) on peer1 we can fetch the channel config information
peer channel fetch newest /tmp/hyperledger/mars.morgen.net/peers/peer1/assets/channel1.block -c channel1 --orderer orderer.morgen.net:7050 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem 

# (7.6) we join the channel for peer1
peer channel join -b /tmp/hyperledger/mars.morgen.net/peers/peer1/assets/channel1.block

# (7.7) we switch back to peer 0 to install chaincode 
# we set the proper environment vars
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"

# (7.8) we install the chaincode on peer0 
peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/

# you can check if the chaincode is installed
peer chaincode list --installed

# (7.9) we instantiate the chaincode (only on peer0)
peer chaincode instantiate -n sacc -v 1.0 -o orderer.morgen.net:7050 -C channel1  -c '{"Args":["msg","hello blockchain"]}' --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# (7.10) we can query the chaincode via cli
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# (7.11) we can set a new value to a given key
peer chaincode invoke -n sacc -c '{"Args":["set", "msg","hello fabric"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# (7.12) we change to peer1 to install the chaincode
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer1.mars.morgen.net:7051"

# (7.13) install chaincode on peer1
peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/

# check if it's installed
peer chaincode list --installed

# (7.14) query the chaincode from peer1 to check if you can query data from peer0
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# (7.15) updat the key from peer0 on peer1 to set a new value
peer chaincode invoke -n sacc -c '{"Args":["set", "msg","hello morgen.net"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

# check certs
openssl x509 -noout -text -in mars.morgen.net-admin-cert.pem
