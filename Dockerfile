FROM ghcr.io/actions/actions-runner:latest

# Install required debian packages
RUN sudo apt-get update \
    && sudo apt-get install -y awscli buildah zip qemu-user-static  binfmt-support git file jq curl nodejs npm \
    && sudo apt-get upgrade -y && sudo npm install -g npm@latest && sudo npm install --global yarn@latest
