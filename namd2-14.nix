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
      ./build charm++ multicore-linux-x86_64 gcc --with-production
    '';

    installPhase = ''
      mkdir -p $out
      cp -r ./* $out
    '';

#It seems like a good idea to run some sort of cleanup now, but I don't know what can be safely removed yet!
  };
  namd2-14 = stdenv.mkDerivation {
    name = "namd2-14";

    buildInputs = [ charmplusplus-singlenode tcl-8_5 fftw ];
    
    src = fetchurl {
      url = https://www.ks.uiuc.edu/Research/namd/2.14/download/946183/NAMD_2.14_Source.tar.gz;
      sha256 = "34044d85d9b4ae61650ccdba5cda4794088c3a9075932392dd0752ef8c049235";
    };

#We need to modify some of the namd .arch files to make sure CUDA libs get the right path, YAY
# basically, NAMD assumes /lib64 rather than /lib, and we need to point to the location of 
#  ${cudaPackages.cudatoolkit_10.lib}/lib/libcudart.so

    preConfigure = ''
      sed -i 's/lib64/lib/' ./arch/Linux-x86_64.cuda
      sed -i "s@^CUDASODIR=.*@CUDASODIR=${cudaPackages.cudatoolkit_10.lib}/lib@" ./arch/Linux-x86_64.cuda
      sed -i "s@^LIBCUDARTSO=.*@LIBCUDARTSO=libcudart.so.10.2@" ./arch/Linux-x86_64.cuda
      cat ./arch/Linux-x86_64.cuda
      echo "Configure running in:"
      pwd
    '';
#      sed -i "s@lcudart_static@lcudart@" ./arch/Linux-x86_64.cuda

    configureFlags = "Linux-x86_64-g++ --with-cuda --cuda-prefix ${cudaPackages.cudatoolkit_10.out} --tcl-prefix ${tcl-8_5.out} --charm-base ${charmplusplus-singlenode.out} --charm-arch multicore-linux-x86_64-gcc --fftw-prefix ${fftwFloat.out} --with-fftw3 --cxx-opts '-Wno-error=format-security' ";
    configureScript = "./config";

    dontAddPrefix = true; #This gets PRE-pended to configureFLags, which breaks the namd build script!

#SYMLINK libcudart.so ftw?
#    mv -v $out/lib64/libcudart* $lib/lib/
#    # Remove OpenCL libraries as they are provided by ocl-icd and driver.
#    rm -f $out/lib64/libOpenCL*
#    ${lib.optionalString (lib.versionAtLeast version "10.1") ''
#      mv $out/lib64 $out/lib
#    ''}
    buildPhase = ''
       sed -i "s@^CUDASODIR=.*@CUDASODIR=${cudaPackages.cudatoolkit_10.lib}/lib@" Linux-x86_64-g++/Make.config
       sed -i "s@^LIBCUDARTSO=.*@LIBCUDARTSO=libcudart.so@" Linux-x86_64-g++/Make.config
       ln -s ${cudaPackages.cudatoolkit_10.out}/lib ${cudaPackages.cudatoolkit_10.out}/lib64
       cp -r ${cudaPackages.cudatoolkit_10.lib}/lib/* ${cudaPackages.cudatoolkit_10.out}/lib64/
       cd Linux-x86_64-g++
       cat Make.config
       echo "BUILD PHASE TAKING PLACE IN:"
       pwd
       make
    '';

    installPhase = ''
       mkdir -p $out/
       find ./ 
       ldd namd2
       cp -r ./charmrun ./flip* ./inc ./obj namd2 psfgen sortreplicas $out/
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
    tcl-8_5
    fftwFloat

    #The thing itself!
    namd2-14
  ];
  src = null;
  shellHook = ''
    export LANG=en_US.UTF-8
    ln -sfn ${namd2-14.out}/namd2 /usr/bin/namd2
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

#    configureFlags = "Linux-x86_64-g++ --charm-arch multicore-linux-x86_64 --with-cuda --cuda-prefix ${cudaPackages.cudatoolkit_10.out} --tcl-prefix ${tcl-8_5.out} --charm-base ${charmplusplus-singlenode.out} --charm-arch multicore-linux-x86_64-gcc --fftw-prefix ${fftw.out}";
