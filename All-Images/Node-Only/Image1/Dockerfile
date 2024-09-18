FROM alpine

# Temel sistem ve gerekli paketlerin kurulumu
RUN apk update && apk upgrade \
    && apk add bash curl git icu-libs jq \
    && apk add --no-cache --update nodejs npm \
    && apk add --no-cache --update python3 py3-pip \
    && apk add --no-cache --update --virtual=build gcc musl-dev python3-dev libffi-dev openssl-dev cargo make \
    && pip3 install --no-cache-dir --prefer-binary --break-system-packages azure-cli \
    && apk del build

# Set Node.js environment variables if needed (optional)
ENV NODE_ENV=production

# Gerekli diğer environment değişkenini ayarla
ENV TARGETARCH="linux-musl-x64"

# Dosyaları Docker build bağlamından (context) kopyalayın
COPY ["*.sh", "/azp/"]
RUN ls -l /azp
# Dosya formatını Unix formatına dönüştür ve çalıştırılabilir yap
RUN dos2unix azp/agent_installation.sh && dos2unix azp/extension_script.sh
RUN chmod +x azp/agent_installation.sh && chmod +x azp/extension_script.sh

# Çalışma dizinini ayarlayın
WORKDIR /azp/

# Gerekli environment değişkenini ayarla
ENV AGENT_ALLOW_RUNASROOT="true"

# Başlangıç komutu
ENTRYPOINT ["./agent_installation.sh"]
