#!/bin/sh
#
#  scripts/bitrise/my-wallet-build.sh
#
#  What It Does
#  ------------
#  Build My-Wallet-V3 if necessary
#
#  NODE_VERSION:"7.9.0"
#
#  NOTE: This script is meant to be run in a Bitrise workflow.
#

set -u

WALLETJS="./Submodules/My-Wallet-V3/dist/my-wallet.js"

if [ -e "$WALLETJS" ]; then
    echo "Skiping My-Wallet-V3 build"
    exit 0
else
    echo "$WALLETJS does not exists"
fi

# Install Node
echo "Install Node"
git clone https://github.com/creationix/nvm.git .nvm
cd .nvm
git checkout v0.33.11
. nvm.sh
nvm install $NODE_VERSION
nvm use $NODE_VERSION
if [[ $(npm -v | grep -v "5.6.0") ]]; then
    npm install -g npm@5.6.0
fi
cd ..

# Build JS Dependencies
echo "run scripts/install-js.sh"
sh scripts/install-js.sh
echo "run scripts/build-js.sh"
sh scripts/build-js.sh
