# syntax=docker/dockerfile:1.5
FROM dorowu/ubuntu-desktop-lxde-vnc:focal

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
USER root

# --------------------------------------------------------------------
# Repositórios e rede (estabilizar APT e evitar GPG error do Chrome)
# --------------------------------------------------------------------

# (Opcional) Fixar archive.ubuntu.com (a base image usa mirror://mirrors.txt)
RUN sed -i 's#mirror://mirrors.ubuntu.com/mirrors.txt#http://archive.ubuntu.com/ubuntu/#' /etc/apt/sources.list

# Remover repo do Google Chrome herdado da base para evitar erro de chave GPG
RUN rm -f /etc/apt/sources.list.d/google-chrome*.list

# Forçar IPv4 e tornar o APT mais resiliente em ambientes sem IPv6
RUN printf 'Acquire::ForceIPv4 "true";\nAcquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' \
    > /etc/apt/apt.conf.d/99force-ipv4

# --------------------------------------------------------------------
# Dependências do sistema e ferramentas de rede
# --------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      software-properties-common ca-certificates gnupg curl wget xz-utils unzip \
 && add-apt-repository -y universe \
 && add-apt-repository -y multiverse \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-17-jdk \
      libgtk-3-0 libwebkit2gtk-4.0-37 \
      iputils-ping netcat-traditional \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------
# Instalação do KNIME Analytics Platform (Linux x86_64)
# Fontes: página oficial de download e guia de instalação
# --------------------------------------------------------------------
# KNIME_HOME é o link estável /opt/knime -> /opt/knime_versao
ENV KNIME_HOME=/opt/knime

# Baixa o tarball "latest" e instala
RUN set -euxo pipefail \
 && wget -O /tmp/knime.tar.gz "https://download.knime.org/analytics-platform/linux/knime-latest-linux.gtk.x86_64.tar.gz" \
 && tar -xzf /tmp/knime.tar.gz -C /opt \
 && rm -f /tmp/knime.tar.gz \
 && KNIME_DIR="$(ls -d /opt/knime* | grep -E '/opt/knime[^/]*$' | head -n1)" \
 && ln -s "${KNIME_DIR}" "${KNIME_HOME}" \
 # Ajusta memória (4GB) no knime.ini – pode ajustar conforme necessidade
 && sed -i 's/^-Xmx.*/-Xmx4g/' "${KNIME_HOME}/knime.ini" || true \
 # Captura e fixa o ícone em caminho estável
 && ICON_SRC="$(find "${KNIME_HOME}/plugins" -type f -path '*org.knime.product_*/icons/knime.png' | head -n1)" \
 && if [[ -n "${ICON_SRC}" ]]; then cp "${ICON_SRC}" "${KNIME_HOME}/knime.png"; fi

# Exporta KNIME para o PATH (permite executar 'knime' direto)
ENV PATH="${KNIME_HOME}:${PATH}"

# --------------------------------------------------------------------
# Cria atalho .desktop no menu e na área de trabalho do root (noVNC)
# --------------------------------------------------------------------
RUN <<'EOF' bash
set -euo pipefail
install -d /usr/share/applications /root/Desktop
cat >/usr/share/applications/knime.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=KNIME Analytics Platform
Exec=/opt/knime/knime
Icon=/opt/knime/knime.png
Terminal=false
Categories=Development;Education;Science;
DESKTOP
cp /usr/share/applications/knime.desktop /root/Desktop/KNIME.desktop
chmod 0644 /usr/share/applications/knime.desktop
chmod +x /root/Desktop/KNIME.desktop || true
EOF

# --------------------------------------------------------------------
# Workspace padrão (permite persistir via volume)
# --------------------------------------------------------------------
RUN install -d -m 0755 /home/ubuntu/KNIME-workspace \
 && chown -R root:root /home/ubuntu/KNIME-workspace

# Resolução padrão do noVNC (imagem base suporta RESOLUTION)
ENV RESOLUTION=1920x1080

# A imagem base expõe 80/tcp (noVNC). Em network_mode=host, isso é ignorado.
EXPOSE 80