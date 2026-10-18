FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies for MT5, Wine, and noVNC
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    wine64 \
    wine32 \
    xserver-xorg \
    openbox \
    ffmpeg \
    curl \
    wget \
    sudo \
    net-tools \
    novnc \
    websockify \
    tigervnc-standalone-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "<meta http-equiv=\"refresh\" content=\"0; url=/vnc.html\">" > /usr/share/novnc/index.html

# Create dedicated non-root user
RUN useradd -m -s /bin/bash abc && \
    echo "abc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER abc
WORKDIR /home/abc

ENTRYPOINT ["/entrypoint.sh"]
