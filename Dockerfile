# ---------------------------------------------------------
FROM ubuntu:24.04

ARG RUNNER_VERSION="2.327.0"          # bump as needed
ARG RUNNER_CONTAINER_HOOKS_VERSION="0.7.0"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Copy and run the installation script
COPY install-tools.sh /install-tools.sh
RUN /bin/bash /install-tools.sh ${RUNNER_VERSION} ${RUNNER_CONTAINER_HOOKS_VERSION} \
    && rm /install-tools.sh  # Optional cleanup
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
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