## qbtorrent-adguardvpn

qBittorrent + AdGuard VPN in a single Docker container. qBittorrent is bound to the VPN tunnel interface, while a watchdog checks the VPN connection and public IP.

### Features

- **qBittorrent** with full web UI
- **AdGuard VPN** with automatic login and connection
- **Kill switch** — qBittorrent is bound to the VPN interface; the watchdog gracefully restarts the container if the VPN disconnects or a public IP check fails
- **Health checks** — monitors both VPN connection and web UI availability
- **IPv4-only mode** — avoids IPv6-only VPN servers that break tracker connectivity
- **Graceful shutdown** — s6 receives `SIGTERM` and gets up to 60 seconds to stop processes; Docker allows 75 seconds for the full shutdown
- **Separated volumes** — qBittorrent config and VPN config stored independently
- **Multi-arch** — supports `linux/amd64` and `linux/arm64`

### Quick Start

```bash
git clone https://github.com/gautamkrishnar/qbtorrent-adguardvpn.git
cd qbtorrent-adguardvpn
cp .env.example .env
# Edit .env with your AdGuard VPN credentials and download path
docker compose pull
docker compose up -d
```

Run these commands from the repository root. The default `docker-compose.yml` pulls the published image from GHCR; it does not build from source. The qBittorrent web UI will be available at `http://localhost:8080`.

To update an existing installation to the latest published image, run from the repository root:

```bash
docker compose pull
docker compose up -d
```

The Docker host must provide `/dev/net/tun` (load the Linux `tun` module if needed); the container uses this device and `NET_ADMIN` for AdGuard's TUN mode.

**Credentials:**

Set `QBT_USERNAME` and `QBT_PASSWORD` in your `.env` file to auto-configure credentials on first boot. If not set, qBittorrent generates a temporary password — check it with `docker compose logs | grep "temporary password"`.

You can also change credentials later in **Tools → Options → Web UI**.

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
| `ADGUARD_SEND_REPORTS` | Send crash reports to AdGuard (`on`/`off`) | No |
| `QBT_USERNAME` | qBittorrent web UI username (auto-set on first boot) | No |
| `QBT_PASSWORD` | qBittorrent web UI password (auto-set on first boot, also used by cronjob to auto-resume errored torrents) | No |
| `QBT_VPN_INTERFACE` | qBittorrent network interface binding (default: `tun0`) | No |
| `DOWNLOADS_PATH` | Host path for downloads | Yes |
| `PUID` | User ID for file permissions | No (default: 1000) |
| `PGID` | Group ID for file permissions | No (default: 1000) |
| `TZ` | Timezone | No (default: UTC) |

### Volumes

| Volume | Path | Purpose |
|--------|------|---------|
| `qbittorrent_config` | `/config` | qBittorrent settings, torrents, resume data |
| `adguardvpn_config` | `/adguard-config` | AdGuard VPN login state and connection config |
| bind mount | `/downloads` | Download directory |

The VPN and torrent configs are separated so you can reset one without losing the other.

### Use the Published Image

The default `docker-compose.yml` uses `ghcr.io/gautamkrishnar/qbtorrent-adguardvpn:latest`. Pull and start it from the repository root:

```bash
docker compose pull
docker compose up -d
```

### Build from Local Source

To build the image from your checked-out source instead, combine the main Compose file with the local override:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d --build
```

Compose merges files in the order listed. The main file provides the full service configuration, and `docker-compose.local.yml` adds a local build for the same `qbittorrent` service. The override is intentionally not a standalone deployment file; use both files in the command above.

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
2. Checks the public IP every four seconds and fails closed if the check errors or differs from the connected VPN IP
3. Sends `SIGTERM` to s6 if the VPN drops or the IP check fails. s6 stops qBittorrent cleanly, then Docker's `unless-stopped` policy restarts the container.

qBittorrent is configured to use the VPN interface directly, so torrent transfers stop if that interface disappears. The web UI remains available through the container's published port. `docker compose stop` remains a manual stop and leaves the container stopped.

If `QBT_USERNAME` and `QBT_PASSWORD` are set, the cronjob also auto-resumes any errored torrents.

### Health Checks

The container includes a built-in health check that verifies:
- qBittorrent web UI is responding on port 8080
- AdGuard VPN is connected

Check health status with `docker inspect --format='{{.State.Health.Status}}' qbittorrent-vpn`.

### Credits

Based on [artuselias/adguardvpn-docker](https://github.com/artuselias/adguardvpn-docker).

### License

GPL-3.0
