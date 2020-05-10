/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';
console.log('enroll admin')
const FabricCAServices = require('fabric-ca-client');
const { FileSystemWallet, X509WalletMixin } = require('fabric-network');
const fs = require('fs');
const path = require('path');

let adminUser = 'ca-mars.morgen.net-admin';
let adminUserPw = 'ca-mars-adminpw';

async function main() {

    try {
        // load the network configuration
       
        const ccpPath = path.resolve(__dirname, 'connection-mars.morgen.net.json');
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));
       
        // Create a new CA client for interacting with the CA.
        const caInfo = ccp.certificateAuthorities['ca-mars.morgen.net'];
        
        const caTLSCACerts = caInfo.tlsCACerts.pem;
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);
      
        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = new FileSystemWallet(walletPath);
      
        // Check to see if we've already enrolled the admin user.
        const adminExists = await wallet.exists('admin');
        if (adminExists) {
            console.log('An identity for the admin user "admin-mars.morgen.net" already exists in the wallet');
            return;
        }
        
        // Enroll the admin user, and import the new identity into the wallet.
        const enrollment = await ca.enroll({ enrollmentID: adminUser, enrollmentSecret: adminUserPw });
       
        const identity = X509WalletMixin.createIdentity('marsMSP', enrollment.certificate, enrollment.key.toBytes());
        await wallet.import('admin', identity);
        console.log('Successfully enrolled admin user "'+adminUser+'" and imported it into the wallet');

    } catch (error) {
        console.error(`Failed to enroll admin user ${adminUser}": ${error}`);
        process.exit(1);
    }
}

main()