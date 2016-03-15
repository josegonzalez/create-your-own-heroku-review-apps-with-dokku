#!/usr/bin/env bash
set -eo pipefail

# node-gyp requires $HOME variable to be set
export HOME=/tmp

# cd into script dir
SCRIPT_PATH=`dirname ${BASH_SOURCE[0]}`
DIR=`cd "$SCRIPT_PATH";pwd -P`
cd $DIR

# pnpm is fast but with some probability fails with an error on installation
# even 10 retries with pnpm is faster than one npm install
RETRIES=10

for i in $(seq 1 $RETRIES); do
  pnpm install && break || echo 'pnpm retry...' && rm -rf node_modules && sleep 3
done

if [[ ! -d "node_modules" ]]; then
  >&2 echo "pnpm returns error $RETRIES times, use npm instead"
  rm -rf node_modules
  npm install
fi

# run project
npm run start
