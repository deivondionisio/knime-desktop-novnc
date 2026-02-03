# syntax=docker/dockerfile:1.5
FROM dorowu/ubuntu-desktop-lxde-vnc:focal

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Remover repo do Google Chrome que quebra o apt e instalar dependências
RUN rm -f /etc/apt/sources.list.d/google-chrome*.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      wget ca-certificates xz-utils unzip curl \
      openjdk-17-jdk \
      libgtk-3-0 libwebkit2gtk-4.0-37 \
 && rm -rf /var/lib/apt/lists/*

# Instala KNIME
ENV KNIME_HOME=/opt/knime
RUN wget -O /tmp/knime.tar.gz https://download.knime.org/analytics-platform/linux/knime-latest-linux.gtk.x86_64.tar.gz \
 && tar -xzf /tmp/knime.tar.gz -C /opt \
 && rm /tmp/knime.tar.gz \
 && KNIME_DIR="$(ls -d /opt/knime* | head -n1)" \
 && ln -s "${KNIME_DIR}" "${KNIME_HOME}" \
 && sed -i 's/^-Xmx.*/-Xmx4g/' "${KNIME_HOME}/knime.ini" || true \
 # Copia o ícone para caminho fixo
 && ICON_SRC="$(find "${KNIME_HOME}/plugins" -type f -path '*org.knime.product_*/icons/knime.png' | head -n1)" \
 && [[ -n "${ICON_SRC}" ]] && cp "${ICON_SRC}" "${KNIME_HOME}/knime.png" || true

ENV PATH="${KNIME_HOME}:${PATH}"

# Cria o atalho .desktop em um único RUN com heredoc de bloco
RUN <<'EOF' bash
set -e
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

# Workspace
RUN install -d -m 0755 /home/ubuntu/KNIME-workspace \
 && chown -R root:root /home/ubuntu/KNIME-workspace

# Resolução padrão do noVNC
ENV RESOLUTION=1920x1080

# Porta HTTP (noVNC) do base image
EXPOSE 80