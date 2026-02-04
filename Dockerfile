# syntax=docker/dockerfile:1.5
FROM dorowu/ubuntu-desktop-lxde-vnc:focal
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
USER root

# (Opcional) Evita mirrors instáveis: usa archive.ubuntu.com
# A base image coloca "mirror://mirrors.ubuntu.com/mirrors.txt" no sources.list.
# Se quiser manter mirrors, remova a linha abaixo.
RUN sed -i 's#mirror://mirrors.ubuntu.com/mirrors.txt#http://archive.ubuntu.com/ubuntu/#' /etc/apt/sources.list

# 1) Habilita universe/multiverse e instala dependências (inclui ping/nc)
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