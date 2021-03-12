with import <nixpkgs> {};
let
  charmplusplus-singlenode = stdenv.mkDerivation {
    name = "charmplusplus-singlenode";
    
    src = fetchurl {
      url = http://charm.cs.illinois.edu/distrib/charm-6.10.2.tar.gz;
      sha256 = "7abb4cace8aebdfbb8006eac03eb766897c009cfb919da0d0a33f74c3b4e6deb";
    };
#    phases = "unpackPhase buildPhase"; # I suspect this was actually stopping the Unpack phase from happening... hence the schlepping around inside InstallPhase
    
    buildPhase = ''
#we are building for single-node namd...
      ./build charm++ multicore-linux-x86_64 --with-production
    '';

    installPhase = ''
      mkdir -p $out
      cp -r ./bin ./lib ./include $out
    '';

#It seems like a good idea to run some sort of cleanup now, but I don't know what can be safely removed yet!
  };

  namd2-14 = stdenv.mkDerivation {
    name = "namd2-14";

    buildInputs = [ charmplusplus-singlenode tcl fftw ];
    
    src = fetchurl {
      url = https://www.ks.uiuc.edu/Research/namd/2.14/download/946183/NAMD_2.14_Source.tar.gz;
      sha256 = "34044d85d9b4ae61650ccdba5cda4794088c3a9075932392dd0752ef8c049235";
    };
#    phases = "installPhase";

#This piece of the install will be trouble, but there are config flags for these
# as well, if I can grab them from Nix.
#Optionally edit various configuration files:
#  (not needed if charm-6.10.2, fftw, and tcl are in NAMD_2.14_Source)
#  vi Make.charm  (set CHARMBASE to full path to charm)
#  vi arch/Linux-x86_64.fftw     (fix library name and path to files)
#  vi arch/Linux-x86_64.tcl      (fix library version and path to TCL files)
#  --tcl-prefix <directory containing Tcl lib and include>
#  --python-prefix <directory containing bin/python[23]-config>
#       in prefix/bin if specified, otherwise in regular path)
#  --with-fftw3 (use fftw3 API, your fftw-prefix should match) 
#  --fftw-prefix <directory containing FFTW lib and include>
#  --mkl-prefix <directory containing Intel MKL lib and include>
#  --cuda-prefix <directory containing CUDA bin, lib, and include>

    configureFlags = "Linux-x86_64-g++ --charm-arch multicore-linux-x86_64 --with-cuda --cuda-prefix ${cudaPackages.cudatoolkit_10.out} --tcl-prefix ${tcl.out} --charm-base ${charmplusplus-singlenode.out} --fftw-prefix ${fftw.out}";
    configureScript = "./config";

    dontAddPrefix = true; #This gets PRE-pended ton configureFLags, which breaks the namd build script!

    buildPhase = ''
       cd Linux-x86_64-g++
       make
    '';

    installPhase = ''
       mkdir $out
       cp -r Linux-x86_64-g++/* ./$out 
    '';
  };
in
stdenv.mkDerivation {
  name = "namd2-14Env";
  buildInputs = [
    nix
    bash
    vim
    
    # NAMD deps
    tcl
    fftw
    charmplusplus-singlenode

    #The thing itself!
    namd2-14
  ];
  src = null;
  shellHook = ''
    export LANG=en_US.UTF-8
    ln -sfn ${namd2-14.out}/namd2-14 /usr/bin/namd2-14
    ln -sfn ${namd2-14.out}/charmrun  /usr/bin/charmrun
    ln -sfn ${namd2-14.out}/flipbinpdb  /usr/bin/flipbinpdb
    ln -sfn ${namd2-14.out}/flipdcd /usr/bin/flipdcd
    ln -sfn ${namd2-14.out}/psfgen  /usr/bin/psfgen
    ln -sfn ${namd2-14.out}/sortreplicas /usr/bin/sortreplicas
    ln -sfn ${namd2-14.out}/lib /usr/lib
  '';
}

# Unneeded from charm++ installphase
#      mv ./multicore-linux-x86_64/* ./ #move bin, lib, etc. from our previous build into the top level nix store dir.
