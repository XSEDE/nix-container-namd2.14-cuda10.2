with import <nixpkgs> { };
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
in
{ cudaProdEnv = buildEnv {
  name = "cuda-prod-env";
  paths = [
    # Always include nix, or environment will break
    # Include bash for base OSes without bash
    nix
    bash
    
    # MPI-related packages
    binutils
    cudaPackages.cudatoolkit_10

    #NAMD Dependency: charmplusplus
    charmplusplus-singlenode
    
    ];
  };
}

