# SIMH-WebAssembly
This is an attempt at making the wonderful [SIMH](https://github.com/simh/simh) project run within a web browser using web assembly.

## Getting Started:
You must have the [emsdk](https://github.com/emscripten-core/emsdk) installed. 

On first install, you will want to mark the latest emscripten version as the one to use.
```
./emsdk install latest
./emsdk activate latest
```

You must also have a bash compatible shell installed. There are several bash scripts here which automate the build process:

`build.sh` downloads SIMH from GitHub, and handles compilation into web assembly.

`run-sim.sh` runs a built simulation using the NodeJS engine.


## Bill of work (all work in progress):
- [ ] Run SIMH tests using the build script (using node).
- [ ] Test using a web browser (probably need to use nodejs here) and write Javascript layers to interact with SIMH.
- [ ] Integrate BrowserFS (load files from the browser)

