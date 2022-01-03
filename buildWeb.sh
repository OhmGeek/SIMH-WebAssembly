#!/usr/bin/bash

# This script is similar to build.sh but instead builds code as a set of JavaScript files that can be run in a web browser.
# No tests run as part of this process (web tests not yet implemented). 
# To run the associated code, start the server using "python3 server.py" from the main directory, and go to a web browser.

# Optionally allow the user to specify a custom value for the emscripten SDK.
emsdk_location=${emsdk_location:="/opt/emsdk/latest"}
simh_location=$(pwd)/build
emsdk_location=/home/ryan/Documents/emsdk-3.1.0

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

    make vax780 \
        GCC='emcc -s MAIN_MODULE -s USE_SDL=2 -s USE_SDL_IMAGE=2 -s USE_SDL_TTF=2 -s USE_ZLIB=1 -s USE_LIBPNG=1 -s EXIT_RUNTIME=1 -s PROXY_TO_PTHREAD=1' \
        TESTS=0 \
        CFLAGS_G='-s TOTAL_MEMORY=128MB' \
        LDFLAGS='-pthread'  \
        DONT_USE_ROMS=1 \
        EXE='.out.js'
        
    
    cd $original_location
}

build_roms() {
    original_location=$(pwd)
    cd $simh_location

    # We use GCC as it's everywhere. We should probably switch to use clang though as it's supported by emscripten.
    gcc BuildRoms.c -o BIN/buildtools/buildroms

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

run_simh_tests() {
    # VAX
    original_directory=$(pwd)
    # For now we copy binaries into noext without the *.out.js component.
    for emulator in $simh_location/BIN/*.out.js
    do

        [[ ! -e $emulator ]] && continue

        if [[ "$emulator" =~ .*"vax".* ]]; then
            # Create the file without the *.out.js extension, as the tests aren't quite suited for this.
            # Copy this over for now, but we should really just do symlinks or something if possible.
            emulator_noext=$( echo $emulator | awk '{gsub(/.out.js/,"")}1' )
            cp -rf $emulator $emulator_noext

            cd $simh_location/VAX/tests/
            echo "Running VAX test for $emulator_noext"
            # We *MUST* run these tests with verbose mode (to avoid using telnet).
            $original_directory/run-sim.sh $emulator_noext $simh_location/VAX/tests/vax-diag_test.ini -v > $original_directory/log/tests.log
            # Store the exit code status.
            status=$?
        
            # If we don't get a zero exit code, fail the build. 
            [[ 0 != $status ]] && (echo "ERROR: simple test failure for emulator $emulator, status code=$status" || exit 1)

            # If we get here, things went through fine.
            echo "INFO: test passed for emulator $emulator. Status=$status"
        fi
    done
    cd $original_directory
}

download_simh_code
ensure_emscripten_on_path

verify_emcc_compiler_is_present_and_working
verify_make_exists

build_simh_for_wasm

# Note: tests are currently disabled as we can't use node to test this. We need to (eventually) mock Chrome to test the web UI.
# that's a job for later on.

# run_simple_scp_tests
# run_simh_tests