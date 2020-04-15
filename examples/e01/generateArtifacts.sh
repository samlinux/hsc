#!/bin/sh
#
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=channel1

# remove previous crypto material and config transactions
sudo rm -fr config/*
sudo rm -fr crypto-config/*

# generate crypto material
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# generate genesis block for orderer
configtxgen -profile OneOrgOrdererGenesis -outputBlock ./config/genesis.block -channelID orderersyschannel
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# generate channel configuration transaction
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./config/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction
configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./config/MarsMSPanchors.tx -channelID $CHANNEL_NAME -asOrg MarsMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for AthenMSP..."
  exit 1
fi
