
# copy and paste

## delete and start again
rm -r ./network/orderer.alpha.at/orderer/genesis.block
rm -r ./network/mars.alpha.at/peers/peer0/assets/channel.tx

sudo rm ./network/mars.alpha.at/peers/peer0/assets/channel1.block
sudo rm ./network/mars.alpha.at/peers/peer1/assets/channel1.block

sudo rm -R network/tls.alpha.at/ca 

sudo rm -R network/mars.alpha.at/admin
sudo rm -R network/mars.alpha.at/ca
sudo rm -R network/mars.alpha.at/msp
sudo rm -R network/mars.alpha.at/peers

sudo rm -R network/orderer.alpha.at/ca
sudo rm -R network/orderer.alpha.at/msp
sudo rm -R network/orderer.alpha.at/orderer
sudo rm -R network/orderer.alpha.at/admin
sudo rm -R network/orderer.alpha.at/ca
## -----------------------------


## copy and paste
# 1.) network/tls.alpha.at/create.sh
# 2.) network/orderer.alpha.at/create.sh
# 3.) network/mars.alpha.at/create.sh

# create genesis block
configtxgen -profile OneOrgOrdererGenesis -channelID orderersyschannel -outputBlock ./network/orderer.alpha.at/orderer/genesis.block

# create channel
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./network/mars.alpha.at/peers/peer0/assets/channel.tx -channelID channel1

docker-compose up

## create channel and join peer2 
### peer0

docker exec -it cli-mars.alpha.at bash 

export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.alpha.at/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.alpha.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.alpha.at:7051"

peer channel create -c channel1 -f /tmp/hyperledger/mars.alpha.at/peers/peer0/assets/channel.tx -o orderer.alpha.at:7050 --outputBlock /tmp/hyperledger/mars.alpha.at/peers/peer0/assets/channel1.block --tls --cafile /tmp/hyperledger/mars.alpha.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer channel join -b /tmp/hyperledger/mars.alpha.at/peers/peer0/assets/channel1.block

cp ./network/mars.alpha.at/peers/peer0/assets/channel1.block ./network/mars.alpha.at/peers/peer1/assets/channel1.block

### peer1
docker exec -it cli-mars.alpha.at bash 
export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.alpha.at/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.alpha.at/peers/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer1.mars.alpha.at:7051"

# peer channel fetch 0 -o orderer.alpha.at:7050 -c channel1
peer channel join -b /tmp/hyperledger/mars.alpha.at/peers/peer1/assets/channel1.block


## Install chaincode on peer0
export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.universe.at/admin/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.universe.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.universe.at:7051"

peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/
peer chaincode list --installed

# instantiate the chaincode (only on peer0)
peer chaincode instantiate -n sacc -v 1.0 -o orderer.alpha.at:7050 -C channel1  -c '{"Args":["msg","hello blockchain"]}' --tls --cafile /tmp/hyperledger/mars.alpha.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.universe.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

## install chaincode on peer 1
peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/

## query peer 1
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.universe.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem


## set new value 
peer chaincode invoke -n sacc -c '{"Args":["set", "msg","hello roland"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.universe.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer chaincode invoke -n sacc -c '{"Args":["set", "msg2","msg2"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.universe.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls

# check certs
openssl x509 -noout -text -in  network/mars.alpha.at/peers/peer0/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem


