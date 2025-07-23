# ---------------------------------------------------------
FROM ubuntu:24.04

ARG RUNNER_VERSION="2.327.0"          # bump as needed
ARG RUNNER_CONTAINER_HOOKS_VERSION="0.7.0"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Base OS packages (build-essential, git, docker-cli, etc.)
RUN apt-get update && apt-get install -y \
      curl sudo jq git build-essential unzip zip aws-cli \
      software-properties-common apt-transport-https ca-certificates gnupg lsb-release \
    && rm -rf /var/lib/apt/lists/*
# --- Add Docker's official repo and install Engine + CLI + plugins ----------
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
# 2. Add the actions/runner user & install the runner itself
RUN useradd -m -s /bin/bash runner
WORKDIR /home/runner
RUN curl -L -o runner.tar.gz \
      https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
 && tar xzf runner.tar.gz \
 && ./bin/installdependencies.sh \
 && rm runner.tar.gz

# 3. Install container hooks (optional, for k8s jobs)
RUN curl -f -L -o runner-container-hooks.zip \
      https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
 && unzip runner-container-hooks.zip -d ./k8s \
 && rm runner-container-hooks.zip

# 4. Pre-load language SDKs (adjust versions or add more as you wish)
## Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs

## Python 3.11 + pipx
#RUN add-apt-repository ppa:deadsnakes/ppa \
# && apt-get update \
# && apt-get install -y python3.13 python3.13-venv python3-pip \
# && pip3 install --upgrade pip pipx

## .NET 8
RUN curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb \
 && dpkg -i packages-microsoft-prod.deb \
 && apt-get update && apt-get install -y dotnet-sdk-8.0

## Go 1.22
RUN curl -L https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | tar -C /usr/local -xzf - \
 && ln -s /usr/local/go/bin/go /usr/local/bin/go

## Rust stable
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/runner/.cargo/bin:${PATH}"

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - \
 && sudo apt-get install -y nodejs

RUN corepack enable && corepack prepare yarn@stable --activate

RUN . /etc/os-release \
 && sudo sh -c "echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_22.04/ /' \
      > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list" \
 && curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_22.04/Release.key \
      | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/libcontainers.gpg > /dev/null \
 && sudo apt-get update \
 && sudo apt-get install -y buildah

# 5. Pre-populate GitHub tool cache (optional but speeds up setup-* actions)
#    See https://www.kenmuse.com/blog/building-github-actions-runner-images-with-a-tool-cache/ [^6^]
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
RUN mkdir -p "$RUNNER_TOOL_CACHE" && chown -R runner:runner "$RUNNER_TOOL_CACHE"

# 6. Labels (good practice)
LABEL org.opencontainers.image.source="https://github.com/crystal-chain/github-action-runner"
LABEL org.opencontainers.image.description="Ubuntu 24.04 based GitHub Actions runner with build tools & multiple SDKs"

COPY entrypoint.sh startup.sh logger.sh graceful-stop.sh update-status /usr/bin/
COPY docker-shim.sh /usr/local/bin/docker
COPY hooks /etc/arc/hooks/

# Same env as official image
ENV ImageOS=ubuntu24
ENV PATH="${PATH}:${HOME}/.local/bin"
RUN echo "PATH=${PATH}" > /etc/environment \
 && echo "ImageOS=${ImageOS}" >> /etc/environment

USER runner

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]