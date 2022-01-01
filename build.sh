#!/usr/bin/bash

# Optionally allow the user to specify a custom value for the emscripten SDK.
emsdk_location=${emsdk_location:="/opt/emsdk/latest"}
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
        GCC='emcc -s MAIN_MODULE -s NODERAWFS=1' \
        TESTS=0 \
        CFLAGS_G='-s TOTAL_MEMORY=128MB' \
        LDFLAGS='-pthread'  \
        DONT_USE_ROMS=1 \
        EXE='.out.js'
        
    
    cd $original_location
}

run_simple_scp_tests() {
    echo "INFO: Running simple emulator start test."
    for emulator in $simh_location/BIN/*.out.js
    do
        [[ ! -e $emulator ]] && continue

        if [[ "$emulator" =~ .*"uc15".* ]]; then
            echo "Skipping ignored emulator $emulator"
            continue
        fi

        echo "Running test for sim: $emulator"
        ./run-sim.sh $emulator tests/scp-boot-test.ini
        
        # Store the exit code status.
        status=$?
        
        # If we don't get a zero exit code, fail the build. 
        [[ 0 != $status ]] && (echo "ERROR: simple test failure for emulator $emulator, status code=$status" && exit 1)

        # If we get here, things went through fine.
        echo "INFO: test passed for emulator $emulator. Status=$status"

    done
    echo "Tests completed."
}


download_simh_code
ensure_emscripten_on_path

verify_emcc_compiler_is_present_and_working
verify_make_exists

build_simh_for_wasm
run_simple_scp_tests