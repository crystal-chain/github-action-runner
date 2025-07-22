#!/bin/bash
# GitHub Actions Runner container entrypoint

set -e

# If you want to use Docker-in-Docker or Buildah, start the service here
sudo service docker start 2>/dev/null || true

# Launch the runner
exec ./run.sh "$@"