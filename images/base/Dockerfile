FROM alpine:3.20 AS base

RUN apk update && apk upgrade && \
    apk add --no-cache \
      bash \
      curl \
      git \
      icu-libs \
      jq \
      ca-certificates

ENV TARGETARCH="linux-musl-x64"

COPY agent_installation.sh /azp/agent_installation.sh
RUN chmod +x /azp/agent_installation.sh

WORKDIR /azp/

ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT ["./agent_installation.sh"]
