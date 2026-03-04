FROM alpine:3.20 AS builder

# Install build dependencies for Azure CLI
RUN apk update && apk add --no-cache \
    python3 py3-pip \
    gcc musl-dev python3-dev libffi-dev openssl-dev cargo make

RUN pip3 install --no-cache-dir --prefer-binary --break-system-packages azure-cli

# ---
FROM alpine:3.20

# Install runtime dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache \
      bash \
      curl \
      git \
      icu-libs \
      jq \
      ca-certificates \
      nodejs \
      npm \
      python3 \
      py3-pip \
      kubectl

# Copy Azure CLI from builder
COPY --from=builder /usr/bin/az /usr/bin/az
COPY --from=builder /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /usr/bin/python3 /usr/bin/python3

ENV NODE_ENV="production"
ENV TARGETARCH="linux-musl-x64"

COPY agent_installation.sh /azp/agent_installation.sh
RUN chmod +x /azp/agent_installation.sh

WORKDIR /azp/

ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT ["./agent_installation.sh"]
