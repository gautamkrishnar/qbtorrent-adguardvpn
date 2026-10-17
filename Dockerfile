FROM lscr.io/linuxserver/qbittorrent:latest
WORKDIR /app
ENV USER=root

RUN apk add --no-cache curl && \
  mkdir -p /opt/adguardvpn_cli /custom-cont-init.d && \
  echo "* * * * * /cronjob" >> /etc/crontabs/root && \
  curl -fsSL --retry 3 --retry-delay 2 https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/HEAD/scripts/release/install.sh -o /tmp/adguardvpn-install.sh && \
  sh /tmp/adguardvpn-install.sh -v -a y && \
  rm /tmp/adguardvpn-install.sh

COPY cronjob /
COPY functions.sh /
COPY adguard_config /custom-cont-init.d
COPY qbt_config /custom-cont-init.d

HEALTHCHECK --interval=60s --timeout=10s --start-period=45s --retries=3 \
  CMD curl -fsS --max-time 5 http://localhost:8080/ > /dev/null && \
      /opt/adguardvpn_cli/adguardvpn-cli status 2>&1 | grep -q "^Connected to" || exit 1
