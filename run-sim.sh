#!/usr/bin/bash
# This simply runs the WASM output with nodejs, adding the appropriate CLI options to make node support WASM
node --experimental-wasm-threads --experimental-wasm-bulk-memory $1 $2