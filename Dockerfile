FROM xsede/centos-nix-base:latest

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
