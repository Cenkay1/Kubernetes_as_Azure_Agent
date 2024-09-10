FROM alpine

RUN apk update
RUN apk upgrade
RUN apk add bash curl git icu-libs jq

RUN apk update

RUN apk add --update nodejs npm

RUN apk add --no-cache --update python3 py3-pip 
RUN apk add --no-cache --update --virtual=build gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && pip3 install --no-cache-dir --prefer-binary --break-system-packages azure-cli && apk del build

ENV TARGETARCH="linux-musl-x64"

WORKDIR /azp/

COPY ["./agent_intallation.sh", "./"]
COPY ["./extension_script.sh", "./"]

RUN dos2unix agent_intallation.sh
RUN dos2unix extension_script.sh

RUN chmod +x ./agent_intallation.sh
RUN chmod +x ./extension_script.sh

ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT ["./agent_intallation.sh"]
