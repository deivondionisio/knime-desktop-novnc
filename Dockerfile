# Dockerfile
FROM dorowu/ubuntu-desktop-lxde-vnc:focal
USER root
RUN apt-get update && apt-get install -y --no-install-recommends     wget ca-certificates xz-utils unzip     openjdk-17-jdk     libgtk-3-0 libwebkit2gtk-4.0-37     && rm -rf /var/lib/apt/lists/*
ENV KNIME_HOME=/opt/knime
RUN mkdir -p ${KNIME_HOME}
RUN wget -O /tmp/knime.tar.gz       https://download.knime.org/analytics-platform/linux/knime-latest-linux.gtk.x86_64.tar.gz     && tar -xzf /tmp/knime.tar.gz -C /opt     && rm /tmp/knime.tar.gz     && ln -s $(ls -d /opt/knime* | head -n1) ${KNIME_HOME}
RUN sed -i 's/^-Xmx.*/-Xmx4g/' ${KNIME_HOME}/knime.ini || true
ENV PATH="${KNIME_HOME}:${PATH}"
RUN bash -lc 'cat >/usr/share/applications/knime.desktop <<EOF
[Desktop Entry]
Type=Application
Name=KNIME Analytics Platform
Exec=${KNIME_HOME}/knime
Icon=${KNIME_HOME}/plugins/org.knime.product_*/icons/knime.png
Terminal=false
Categories=Development;Education;Science;
EOF'  && mkdir -p /root/Desktop  && cp /usr/share/applications/knime.desktop /root/Desktop/KNIME.desktop  && chmod +x /usr/share/applications/knime.desktop /root/Desktop/KNIME.desktop
RUN mkdir -p /home/ubuntu/KNIME-workspace && chown -R root:root /home/ubuntu/KNIME-workspace
ENV RESOLUTION=1920x1080
EXPOSE 80
