FROM xsede/centos-nix-base:latest

################## METADATA ######################

LABEL base_image="xsede/centos-nix-base"
LABEL version="1.0.0"
LABEL software="Nix"
LABEL software.version="2.14"
LABEL about.summary="A template container with NAMD 2.14 and CUDA 10.2 installed using the Nix package manager in a CentOS 7 environment"
LABEL about.home="https://github.com/XSEDE/nix-container-namd2.14-cuda-10.2"
LABEL about.documentation="https://github.com/XSEDE/nix-container-namd2.14-cuda-10.2"
LABEL about.license_file="https://github.com/XSEDE/nix-container-namd2.14-cuda-10.2"
LABEL about.license="MIT"
LABEL about.tags="example-container" 
LABEL authors="XCRI <help@xsede.org>"

################## ENVIRONMENT ######################

SHELL ["/bin/bash", "-c"]

USER root

ENV NIXENV "/root/.nix-profile/etc/profile.d/nix.sh"

RUN mkdir -p /root/.config/nixpkgs/

COPY config.nix /root/.config/nixpkgs/
COPY prod-env.nix /root/
COPY persist-env.sh /root/

RUN for i in $(ls /root/.nix-profile/bin) ; do ln -s /root/.nix-profile/bin/"$i" /usr/bin ; done

RUN chmod +x /root/.nix-profile/etc/profile.d/nix.sh

# initiate environment
# With CUDA toolkit, this takes *quite* a while
RUN $NIXENV && \
    cd /tmp && \
    bash /root/persist-env.sh /root/prod-env.nix && nix-collect-garbage

COPY namd2-14.nix /root/

# Build namd3 environment 
RUN nix-shell /root/namd2-14.nix
