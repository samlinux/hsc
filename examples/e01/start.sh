#!/bin/bash
export COMPOSE_PROJECT_NAME=e01

# exit on first error, print all commands.
set -e

# we first stop the network
docker-compose down

# start the network
docker-compose up -d

## Peer0
# first - create channel1
# second - join the channel on peer0
docker exec -e "CORE_PEER_ADDRESS=peer0.mars.universe.at:7051" -e "CORE_PEER_LOCALMSPID=MarsMSP" -e "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mars.universe.at/users/Admin\@mars.universe.at" cli peer channel create -o solo.orderer.universe.at:7050 -c channel1 -f ./config/channel.tx

docker exec -e "CORE_PEER_ADDRESS=peer0.mars.universe.at:7051" -e "CORE_PEER_LOCALMSPID=MarsMSP" -e "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mars.universe.at/users/Admin\@mars.universe.at" cli peer channel join -b channel1.block

## Peer1
# first - get the channel via fetch
# second - join the channel on peer1
docker exec -e "CORE_PEER_ADDRESS=peer1.mars.universe.at:7051" -e "CORE_PEER_LOCALMSPID=MarsMSP" -e "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mars.universe.at/users/Admin\@mars.universe.at" cli peer channel fetch 0 -o solo.orderer.universe.at:7050 -c channel1

docker exec -e "CORE_PEER_ADDRESS=peer1.mars.universe.at:7051" -e "CORE_PEER_LOCALMSPID=MarsMSP" -e "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mars.universe.at/users/Admin\@mars.universe.at" cli peer channel join -b channel1.block

# install the chaincode on peer0
docker exec -e "CORE_PEER_ADDRESS=peer0.mars.universe.at:7051" cli peer chaincode install -n sacc -v 1.0 -p sacc
docker exec -e "CORE_PEER_ADDRESS=peer0.mars.universe.at:7051" cli peer chaincode list --installed

# instantiate the chaincode (only on peer0)
docker exec -e "CORE_PEER_ADDRESS=peer0.mars.universe.at:7051" cli peer chaincode instantiate -n sacc -v 1.0 -o solo.orderer.universe.at:7050 -C channel1  -c '{"Args":["msg","hello blockchain"]}'

## install the chaincode on peer1
docker exec -e "CORE_PEER_ADDRESS=peer1.mars.universe.at:7051" cli peer chaincode install -n sacc -v 1.0 -p sacc
docker exec -e "CORE_PEER_ADDRESS=peer1.mars.universe.at:7051" cli peer chaincode list --installed

echo "--------------------------------------"
echo "we are ready to test the chaincode ..."
echo "--------------------------------------"
