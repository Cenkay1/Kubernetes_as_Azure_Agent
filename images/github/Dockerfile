# GitHub Actions self-hosted runner image.
#
# NOTE: Unlike the Azure DevOps agents (Alpine/musl), GitHub's actions/runner
# is only published for glibc (linux-x64). We therefore use a Debian base
# instead of Alpine so the runner and installdependencies.sh work reliably.
FROM debian:bookworm-slim

# procps -> pgrep (liveness probe); the rest are runner + common CI needs.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      jq \
      bash \
      procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /actions-runner

# Pin a specific runner version by passing --build-arg RUNNER_VERSION=x.y.z,
# otherwise the latest release is resolved at build time.
ARG RUNNER_VERSION=""
RUN set -eux; \
    ver="${RUNNER_VERSION:-$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')}"; \
    curl -fsSL -o runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${ver}/actions-runner-linux-x64-${ver}.tar.gz"; \
    tar xzf runner.tar.gz; \
    rm runner.tar.gz

# Install the runner's OS-level dependencies (libicu, libssl, etc.)
RUN ./bin/installdependencies.sh && rm -rf /var/lib/apt/lists/*

COPY runner_installation.sh /actions-runner/runner_installation.sh
RUN chmod +x /actions-runner/runner_installation.sh

# The runner refuses to run as root unless this is set.
ENV RUNNER_ALLOW_RUNASROOT="1"

ENTRYPOINT ["./runner_installation.sh"]
