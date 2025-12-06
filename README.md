# JDownloader2 + Proton VPN LXC Container

<p align="center">
  <img src="https://jdownloader.org/_media/knowledge/wiki/jdownloader.png" alt="JDownloader Logo" width="150"/>
</p>

A Proxmox VE helper script that creates an LXC container running **JDownloader2** with **Proton VPN CLI** pre-installed. This follows the [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) structure.

## 📋 Features

- ✅ **JDownloader2** - Powerful download manager with support for 300+ file hosters
- ✅ **Proton VPN CLI** - Secure VPN connection with kill switch support
- ✅ **MyJDownloader** - Remote management via web interface
- ✅ **Headless operation** - No GUI required, perfect for servers
- ✅ **Debian 13 (Trixie)** - Latest stable base
- ✅ **Unprivileged container** - Enhanced security

## 🚀 Quick Start

### One-Line Installation

Run this command in your Proxmox VE shell:

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/benjaminbear/jdownloader-lxc/main/ct/jdownloader.sh)"
```

### Manual Installation

1. Clone this repository to your Proxmox host
2. Run the installation script:
   ```bash
   bash ct/jdownloader.sh
   ```

## ⚙️ Default Settings

| Setting | Value |
|---------|-------|
| **OS** | Debian 13 (Trixie) |
| **CPU** | 2 cores |
| **RAM** | 2048 MB |
| **Disk** | 8 GB |
| **Container Type** | Unprivileged |
| **Downloads Path** | `/downloads` |

## 📝 Post-Installation Setup

### 1. Configure Proton VPN

Enter the container and login to Proton VPN:

```bash
# Enter the container (replace CTID with your container ID)
pct enter <CTID>

# Login to Proton VPN
protonvpn-cli login <your-proton-username>

# Connect to the fastest server
protonvpn-cli connect --fastest

# Or connect to a specific country (e.g., Switzerland)
protonvpn-cli connect --cc CH

# Enable kill switch (recommended)
protonvpn-cli ks --on
```

### 2. Configure MyJDownloader

1. Create a free account at [my.jdownloader.org](https://my.jdownloader.org)
2. Enter the container and configure JDownloader:
   ```bash
   pct enter <CTID>
   
   # Stop JDownloader service temporarily
   systemctl stop jdownloader
   
   # Configure MyJDownloader credentials
   cat > /opt/JDownloader/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json << EOF
   {
     "email" : "your-email@example.com",
     "password" : "your-myjdownloader-password",
     "devicename" : "Proxmox-JDownloader",
     "autoconnectaliases" : true
   }
   EOF
   
   # Start JDownloader service
   systemctl start jdownloader
   ```
3. Access your downloads at [my.jdownloader.org](https://my.jdownloader.org)

## 🛠️ Helper Commands

The container includes convenient helper scripts:

| Command | Description |
|---------|-------------|
| `vpn-connect` | Connect to fastest Proton VPN server |
| `vpn-disconnect` | Disconnect from Proton VPN |
| `vpn-status` | Show current VPN connection status |

## 📂 Directory Structure

```
/opt/JDownloader/          # JDownloader installation
├── JDownloader.jar        # Main application
└── cfg/                   # Configuration files

/downloads/                # Default download directory
```

## 🔧 Service Management

```bash
# Check JDownloader status
systemctl status jdownloader

# Restart JDownloader
systemctl restart jdownloader

# View JDownloader logs
journalctl -u jdownloader -f

# Check Proton VPN status
protonvpn-cli status
```

## 📁 Repository Structure

```
jdownloader-lxc/
├── ct/
│   └── jdownloader.sh           # Main entry script (runs on Proxmox host)
├── install/
│   └── jdownloader-install.sh   # Installation script (runs inside container)
├── json/
│   └── jdownloader.json         # Metadata for web interface
└── README.md                    # This file
```

## ⚠️ Important Notes

1. **VPN Login Required**: Proton VPN requires manual authentication after container creation
2. **Kill Switch**: Enable the kill switch (`protonvpn-cli ks --on`) to prevent IP leaks if VPN disconnects
3. **MyJDownloader**: Required for remote management since this runs headless
4. **Storage**: Consider mounting additional storage for large downloads

## 🔒 Security Considerations

- The container runs unprivileged for enhanced security
- TUN device access is granted for VPN functionality
- Kill switch prevents traffic leaks when VPN disconnects
- Consider using a dedicated Proton VPN account for this container

## 🐛 Troubleshooting

### VPN won't connect
```bash
# Check if TUN device is available
ls -la /dev/net/tun

# If missing, the host configuration may need updating
# On Proxmox host, check /etc/pve/lxc/<CTID>.conf for:
# lxc.cgroup2.devices.allow: c 10:200 rwm
# lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

### JDownloader not starting
```bash
# Check service status
systemctl status jdownloader

# Check logs
journalctl -u jdownloader -n 50

# Restart the service
systemctl restart jdownloader
```

### MyJDownloader not connecting
```bash
# Verify configuration file exists
cat /opt/JDownloader/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json

# Restart JDownloader after configuration changes
systemctl restart jdownloader
```

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 🙏 Credits

- [JDownloader](https://jdownloader.org/) - Download manager
- [Proton VPN](https://protonvpn.com/) - VPN provider
- [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) - Script structure inspiration

---

<p align="center">
  Made with ❤️ for the Proxmox community
</p>

