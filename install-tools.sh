#!/bin/bash

set -e  # Exit on error

# Prevent interactive prompts (matches Dockerfile ENV)
export DEBIAN_FRONTEND=noninteractive

# Function to install base OS packages
install_base_packages() {
    echo "--------------------------------------------"
    echo "Installing base OS packages..."
    echo "--------------------------------------------"
    apt-get update && apt-get install -y \
        curl sudo jq git build-essential unzip zip \
        software-properties-common apt-transport-https ca-certificates gnupg lsb-release \
    && rm -rf /var/lib/apt/lists/*
}

# Function to install Docker
install_docker() {
    echo "--------------------------------------------"
    echo "Installing Docker..."
    echo "--------------------------------------------"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
}

# Function to install AWS CLI
install_awscli() {
    echo "--------------------------------------------"
    echo "Installing AWS CLI..."
    echo "--------------------------------------------"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
    unzip awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws


}

# Function to add the 'runner' user
add_runner_user() {
    echo "--------------------------------------------"
    echo "Adding 'runner' user..."
    echo "--------------------------------------------"
    useradd -m -s /bin/bash runner
}

# Function to install GitHub Actions runner
install_actions_runner() {
    echo "--------------------------------------------"
    echo "Installing GitHub Actions runner..."
    echo "--------------------------------------------"
    local version="$1"
    mkdir -p /home/runner  # Ensure dir exists
    cd /home/runner
    curl -L -o runner.tar.gz \
        https://github.com/actions/runner/releases/download/v${version}/actions-runner-linux-x64-${version}.tar.gz
    tar xzf runner.tar.gz
    ./bin/installdependencies.sh
    rm runner.tar.gz
}

# Function to install container hooks
install_container_hooks() {
    echo "--------------------------------------------"
    echo "Installing GitHub Actions runner container hooks..."
    echo "--------------------------------------------"
    local version="$1"
    cd /home/runner  # Hooks are installed in /home/runner/k8s
    curl -f -L -o runner-container-hooks.zip \
        https://github.com/actions/runner-container-hooks/releases/download/v${version}/actions-runner-hooks-k8s-${version}.zip
    unzip runner-container-hooks.zip -d ./k8s
    rm runner-container-hooks.zip
}

# Function to install Node.js 20.x
install_nodejs_20() {
    echo "--------------------------------------------"
    echo "Installing Node.js 20.x..."
    echo "--------------------------------------------"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
}

# Function to install .NET 8
install_dotnet8() {
    echo "--------------------------------------------"
    echo "Installing .NET 8 SDK..."
    echo "--------------------------------------------"
    curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
    apt-get update
    apt-get install -y dotnet-sdk-8.0
    rm packages-microsoft-prod.deb
}

# Function to install Go 1.22
install_go() {
    echo "--------------------------------------------"
    echo "Installing Go 1.22..."
    echo "--------------------------------------------"
    curl -L https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | tar -C /usr/local -xzf -
    ln -s /usr/local/go/bin/go /usr/local/bin/go
}

# Function to install Rust
install_rust() {
    echo "--------------------------------------------"
    echo "Installing Rust..."
    echo "--------------------------------------------"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="/home/runner/.cargo/bin:$PATH"
}

# Function to install Node.js 22.x
install_nodejs_22() {
    echo "--------------------------------------------"
    echo "Installing Node.js 22.x..."
    echo "--------------------------------------------"
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
}

# Function to enable corepack and install Yarn
install_yarn() {
    echo "--------------------------------------------"
    echo "Installing Yarn..."
    echo "--------------------------------------------"
    corepack enable && corepack prepare yarn@stable --activate
}

# Function to install Buildah
install_buildah() {
    echo "--------------------------------------------"
    echo "Installing Buildah..."
    echo "--------------------------------------------"
    . /etc/os-release
    sudo sh -c "echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_22.04/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
    curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/libcontainers.gpg > /dev/null
    sudo apt-get update
    sudo apt-get install -y buildah
}

# Function to install Kustomize
install_kustomize() {
    echo "--------------------------------------------"
    echo "Installing Kustomize..."
    echo "--------------------------------------------"
    curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.7.1/kustomize_v5.7.1_linux_amd64.tar.gz -o kustomize.tar.gz
    tar -xzf kustomize.tar.gz -C /tmp
    mv /tmp/kustomize /usr/local/bin/kustomize
    chmod +x /usr/local/bin/kustomize
    rm kustomize.tar.gz
}

# Function to install Terraform
install_terraform() {
    echo "--------------------------------------------"
    echo "Installing Terraform..."
    echo "--------------------------------------------"
    curl -fsSL https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip -o terraform.zip
    unzip terraform.zip
    mv terraform /usr/local/bin/terraform
    chmod +x /usr/local/bin/terraform
    rm terraform.zip
}

# Function to install Ansible (includes python3-pip and pipx)
install_ansible() {
    echo "--------------------------------------------"
    echo "Installing Ansible..."
    echo "--------------------------------------------"
    apt-get update
    apt-get install -y python3-pip pipx
    pipx install --global ansible
    ln -s /opt/pipx_bin/ansible-playbook /usr/local/bin/ansible-playbook
    ln -s /opt/pipx_bin/ansible /usr/local/bin/ansible
}

# Function to set up GitHub tool cache
install_tool_cache() {
    echo "--------------------------------------------"
    echo "Setting up GitHub tool cache..."
    echo "--------------------------------------------"
    export RUNNER_TOOL_CACHE=/opt/hostedtoolcache
    mkdir -p "$RUNNER_TOOL_CACHE"
    chown -R runner:runner "$RUNNER_TOOL_CACHE"
}
show_installation_summary() {
    echo "--------------------------------------------"
    echo "Installation Summary:"
    echo "--------------------------------------------"
    echo "Base packages, Docker, AWS CLI, GitHub Actions runner, container hooks, Node.js 20.x, Node.js 22.x, Yarn, Buildah, Kustomize, Terraform, Ansible, Go installed successfully."
    echo "Tool cache set at: $RUNNER_TOOL_CACHE"
    echo "installed tools versions:"
    versions

}
versions() {
    echo "Installed versions:"
    echo "Node.js 20.x: $(node -v)"
    echo "Node.js 22.x: $(node -v)"
    echo "Yarn: $(yarn -v)"
    echo "Buildah: $(buildah --version)"
    echo "Kustomize: $(kustomize version)"
    echo "Terraform: $(terraform -version | head -n 1)"
    echo "Ansible: $(ansible --version | head -n 1)"
    echo "Go: $(go version)"
}
# Main function to run all installations
main() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <RUNNER_VERSION> <RUNNER_CONTAINER_HOOKS_VERSION>"
        exit 1
    fi

    install_base_packages
    install_docker
    install_awscli
    add_runner_user
    install_actions_runner "$1"
    install_container_hooks "$2"
    install_nodejs_20
    #install_dotnet8
    install_go
    #install_rust
    install_nodejs_22
    install_yarn
    install_buildah
    install_kustomize
    install_terraform
    install_ansible
    install_tool_cache

    # Capture environment (matches original Dockerfile's final RUN for /etc/environment)
    export ImageOS=ubuntu24
    echo "PATH=$PATH" > /etc/environment
    echo "ImageOS=${ImageOS}" >> /etc/environment
}

# Run main with arguments
main "$@"
