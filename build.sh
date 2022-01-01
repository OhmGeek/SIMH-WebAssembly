#!/usr/bin/bash

emsdk_location="/home/ryan/Documents/emsdk-3.1.0"
simh_location=$(pwd)/build

# Initial setup: download the codebase, and ensure dependencies for building are installed.
download_simh_code() {
    if [ -d $simh_location ]
    then
        echo "SIMH already exists, skipping the download step"
    else
        echo "SIMH doesn't exist. Cloning."
        git clone https://github.com/simh/simh.git $simh_location
    fi
}

ensure_emscripten_on_path() {
    echo "Using emsdk located at $emsdk_location"
    source $emsdk_location/emsdk_env.sh 
}

# Build functions
verify_emcc_compiler_is_present_and_working() {
    if [ -x "$(command -v emcc)" ]
    then
        echo "EMCC compiler found on path (as expected)."
        echo "Path location: $(which emcc)"
        echo "Version details: $(emcc --version | head -n 1)"
    else
        echo "ERROR: EMCC not found on path. Are you sure emscripten is installed properly?"
        echo "Exiting."
        exit 1
    fi
}

verify_make_exists() {
    if ! [ -x "$(command -v make)" ]
    then
        echo "ERROR: Make doesn't exist on the path. Please ensure this is installed."
        exit 1
    fi
}

build_simh_for_wasm() {
    original_location=$(pwd)
    cd $simh_location
    make clean

    make all \
        GCC='emcc' \
        TESTS=0 \
        CFLAGS_G='-s MAIN_MODULE -s TOTAL_MEMORY=64MB -s NODERAWFS=1' \
        LDFLAGS=-pthread  \
        DONT_USE_ROMS=1
        
    
    cd $original_location
}

download_simh_code
ensure_emscripten_on_path

verify_emcc_compiler_is_present_and_working
verify_make_exists

build_simh_for_wasm