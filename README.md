## qbtorrent-adguardvpn

qBittorrent + AdGuard VPN in a single Docker container. All torrent traffic is routed through the VPN tunnel with automatic kill switch protection.

### Features

- **qBittorrent** with full web UI
- **AdGuard VPN** with automatic login and connection
- **Kill switch** — container restarts if VPN drops or IP leaks
- **Health checks** — monitors both VPN connection and web UI availability
- **IPv4-only mode** — avoids IPv6-only VPN servers that break tracker connectivity
- **Graceful shutdown** — 30s stop grace period ensures torrents save state properly
- **Separated volumes** — qBittorrent config and VPN config stored independently
- **Multi-arch** — supports `linux/amd64` and `linux/arm64`

### Quick Start

```bash
git clone https://github.com/gautamkrishnar/qbtorrent-adguardvpn.git
cd qbtorrent-adguardvpn
cp .env.example .env
# Edit .env with your AdGuard VPN credentials and download path
docker compose up -d
```

The qBittorrent web UI will be available at `http://localhost:8080`.

**Default credentials:**
- Username: `admin`
- Password: Check container logs — `docker compose logs | grep "temporary password"`

Change your password in **Tools → Options → Web UI** after first login.

### Recommended qBittorrent Settings

After first login, go to **Tools → Options** and apply these settings:

**Downloads:**
- Default Save Path: `/downloads`
- Keep incomplete torrents in: `/downloads/incomplete` (enable this)
- Pre-allocate disk space for all files: enabled

**Connection:**
- Peer connection protocol: TCP and μTP
- Global maximum number of connections: 500
- Maximum number of connections per torrent: 100

**BitTorrent:**
- DHT: enabled
- PEX: enabled
- Local Peer Discovery: enabled
- Encryption mode: Prefer encryption
- Enable anonymous mode: enabled
- Max active downloads: 5
- Max active uploads: 5
- Max active torrents: 10

**Web UI:**
- Enable CSRF protection: enabled
- Enable Host header validation: enabled (add your domain)
- Set a strong password

### Configuration

All configuration is done via the `.env` file:

| Variable | Description | Required |
|----------|-------------|----------|
| `ADGUARD_USERNAME` | AdGuard VPN account email | Yes |
| `ADGUARD_PASSWORD` | AdGuard VPN account password | Yes |
| `ADGUARD_LOCATION` | VPN server location (city/country/ISO code). Empty = fastest. | No |
| `ADGUARD_SEND_REPORTS` | Send telemetry to AdGuard (`on`/`off`) | No |
| `DOWNLOADS_PATH` | Host path for downloads | Yes |
| `PUID` | User ID for file permissions | No (default: 1000) |
| `PGID` | Group ID for file permissions | No (default: 1000) |
| `TZ` | Timezone | No (default: UTC) |
| `VIRTUAL_HOST` | Hostname for reverse proxy (nginx-proxy) | No |
| `VIRTUAL_PORT` | Port for reverse proxy (set to `8080`) | No |

### Volumes

| Volume | Path | Purpose |
|--------|------|---------|
| `qbittorrent_config` | `/config` | qBittorrent settings, torrents, resume data |
| `adguardvpn_config` | `/adguard-config` | AdGuard VPN login state and connection config |
| bind mount | `/downloads` | Download directory |

The VPN and torrent configs are separated so you can reset one without losing the other.

### Reverse Proxy

If using [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy), add these to your `.env`:

```
VIRTUAL_HOST=torrent.example.com
VIRTUAL_PORT=8080
```

And add the container to your proxy network in `docker-compose.yml`:

```yaml
services:
  qbittorrent:
    networks:
      - proxynet

networks:
  proxynet:
    external: true
```

### Pre-built Image

Pull the pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/gautamkrishnar/qbtorrent-adguardvpn:latest
```

### Building from Source

```bash
docker compose build
docker compose up -d
```

### VPN Locations

List available locations:

```bash
docker exec qbittorrent-vpn /opt/adguardvpn_cli/adguardvpn-cli list-locations
```

Change location by updating `ADGUARD_LOCATION` in `.env` and restarting:

```bash
docker compose restart
```

### How the Kill Switch Works

A cron job runs every minute inside the container:
1. Checks if the VPN is still connected
2. Monitors for IP address changes
3. Restarts the container if the VPN drops or the IP changes

This ensures torrent traffic never leaks outside the VPN tunnel.

### Health Checks

The container includes a built-in health check that verifies:
- qBittorrent web UI is responding on port 8080
- AdGuard VPN is connected

Check health status with `docker inspect --format='{{.State.Health.Status}}' qbittorrent-vpn`.

### Credits

Based on [artuselias/adguardvpn-docker](https://github.com/artuselias/adguardvpn-docker).

### License

GPL-3.0
