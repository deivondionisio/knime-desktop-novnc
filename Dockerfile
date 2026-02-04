# syntax=docker/dockerfile:1.5
FROM dorowu/ubuntu-desktop-lxde-vnc:focal

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
USER root

# (Opcional) Fixar archive.ubuntu.com em vez de mirrors dinâmicos
RUN sed -i 's#mirror://mirrors.ubuntu.com/mirrors.txt#http://archive.ubuntu.com/ubuntu/#' /etc/apt/sources.list

# Remover repo do Google Chrome herdado da base (evita GPG error)
RUN rm -f /etc/apt/sources.list.d/google-chrome*.list

# Forçar IPv4 + aumentar resiliência do APT
RUN printf 'Acquire::ForceIPv4 "true";\nAcquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' \
    > /etc/apt/apt.conf.d/99force-ipv4

# Habilitar universe/multiverse e instalar pacotes (JDK 17, libs GTK/WebKit, ping/nc)
RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common ca-certificates gnupg curl wget xz-utils unzip \
 && add-apt-repository -y universe \
 && add-apt-repository -y multiverse \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-17-jdk \
      libgtk-3-0 libwebkit2gtk-4.0-37 \
      iputils-ping netcat-traditional \
 && rm -rf /var/lib/apt/lists/*