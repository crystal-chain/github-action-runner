FROM ghcr.io/actions/actions-runner:latest
ARG NODE_VERSION=20
# Install required debian packages
RUN sudo apt-get update \
    && sudo apt-get install -y awscli buildah zip qemu-user-static  binfmt-support git file jq curl nodejs npm \
    && sudo apt-get upgrade -y && sudo npm install -g npm@latest && sudo npm install --global yarn@latest && echo "yarn --version" && echo "npm --version"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# set env
ENV NVM_DIR=/root/.nvm

# install node
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION"