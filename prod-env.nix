with import <nixpkgs> { };
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
    
    ];
  };
}

