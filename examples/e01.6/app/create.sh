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