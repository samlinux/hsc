/**
 * query some data 
 */
'use strict';

const { FileSystemWallet, Gateway } = require('fabric-network');
const path = require('path');

const ccpPath = path.resolve(__dirname, 'connection-mars.morgen.net.json');
const channel = 'channel1';
const chaincode = 'sacc';

let myArgs = process.argv.slice(2);
let queryKey = '';

if(myArgs[0] !== undefined){
  queryKey = myArgs[0];
} else {
  console.error('Error: not all input parameters set, use: node query.js key');
  process.exit(1);
}

async function main() {
  try {

    // Create a new file system based wallet for managing identities.
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = new FileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);

    // Check to see if we've already enrolled the user.
    const userExists = await wallet.exists('user1');
    if (!userExists) {
        console.log('An identity for the user "user1" does not exist in the wallet');
        console.log('Run the registerUser.js application before retrying');
        return;
    }

    // Create a new gateway for connecting to our peer node.
    const gateway = new Gateway();
    await gateway.connect(ccpPath, { wallet, identity: 'user1', discovery: { enabled: true, asLocalhost: true } });

    // Get the network (channel) our contract is deployed to.
    const network = await gateway.getNetwork(channel);

    // Get the contract from the network.
    const contract = network.getContract(chaincode);

    // Evaluate the specified transaction.
    // queryCar transaction - requires 1 argument, ex: ('queryCar', 'CAR4')
    // queryAllCars transaction - requires no arguments, ex: ('queryAllCars')
    const result = await contract.evaluateTransaction('query',queryKey);
    console.log(`Transaction has been evaluated, result is: ${result.toString()}`);

  } catch (error) {
      console.error(`Failed to evaluate transaction: ${error}`);
      process.exit(1);
  }
}

main();