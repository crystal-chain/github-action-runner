FROM ghcr.io/actions/actions-runner:latest
ARG NODE_VERSION=20
# Install required debian packages
RUN sudo apt-get update \
    && sudo apt-get install -y awscli buildah=1.35.3 zip qemu-user-static  binfmt-support git file jq curl nodejs npm\
    && sudo apt-get upgrade -y 
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
RUN export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && nvm alias default $NODE_VERSION

RUN sudo npm install --global yarn@latest 