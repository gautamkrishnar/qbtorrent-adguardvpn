FROM lscr.io/linuxserver/qbittorrent:latest
WORKDIR /app
ENV USER=root

RUN apk add --no-cache curl docker && \
  mkdir -p /opt/adguardvpn_cli /custom-cont-init.d /dev/net && \
  mknod /dev/net/tun c 10 200 && \
  echo "* * * * * /cronjob" >> /etc/crontabs/root && \
  curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/HEAD/scripts/release/install.sh | sed 's/read -r response < \/dev\/tty/response=y/' | sh -s -- -v

COPY cronjob /
COPY functions.sh /
COPY adguard_config /custom-cont-init.d
COPY qbt_config /custom-cont-init.d

HEALTHCHECK --interval=60s --timeout=10s --start-period=45s --retries=3 \
  CMD curl -sf http://localhost:8080 > /dev/null && \
      /opt/adguardvpn_cli/adguardvpn-cli status 2>&1 | head -1 | grep -q "^Connected" || exit 1
