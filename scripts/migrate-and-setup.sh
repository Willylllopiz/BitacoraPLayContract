#!/usr/bin/env bash

source .env && tronbox migrate --reset --network nile
node ./scripts/setup.js

