# Additional Setup and Configuration Guide

This guide covers additional setup options including environment-based configuration, Docker Desktop installation, and RustDesk remote desktop setup.

## Table of Contents

- [Environment-Based Configuration](#environment-based-configuration)
- [Installing Docker Desktop on Windows](#installing-docker-desktop-on-windows)
- [RustDesk: Alternative Remote Desktop Solution](#rustdesk-alternative-remote-desktop-solution)
- [Comparison: RDP vs RustDesk](#comparison-rdp-vs-rustdesk)

---

## Environment-Based Configuration

### Using the .env File

The repository now includes a `.env.example` file that provides a template for environment-based configuration. This allows you to manage hardware settings, credentials, and other configurations without modifying the `compose.yml` file directly.

#### Setup Steps

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the .env file:**
   ```bash
   nano .env  # or use your preferred editor
   ```

3. **Customize the settings:**
   - **Windows Configuration:** Version, language, region, keyboard
   - **User Credentials:** Username and password
   - **Hardware:** RAM size, CPU cores, disk size
   - **Network:** DHCP settings, port mappings
   - **Storage:** Volume paths

4. **Run Docker Compose:**
   ```bash
   docker compose up -d
   ```

Docker Compose will automatically read the `.env` file and use the configured values.

### Environment Variables Reference

#### Windows Configuration
```bash
VERSION=11                    # Windows version (11, 10, 2025, etc.)
LANGUAGE=English             # Installation language
REGION=en-US                 # Region setting
KEYBOARD=en-US               # Keyboard layout
```

#### User Credentials
```bash
USERNAME=Docker              # Windows username
PASSWORD=admin               # Windows password
```

#### Hardware Configuration
```bash
RAM_SIZE=4G                  # RAM allocation (4G, 8G, 16G, etc.)
CPU_CORES=2                  # Number of CPU cores
DISK_SIZE=64G                # Primary disk size
# Optional additional disks:
# DISK2_SIZE=32G
# DISK3_SIZE=64G
```

#### Network Configuration
```bash
DHCP=N                       # Enable/disable DHCP (Y/N)
WEB_PORT=8006               # Web viewer port
RDP_PORT_TCP=3389           # RDP TCP port
RDP_PORT_UDP=3389           # RDP UDP port
```

#### Volume Configuration
```bash
STORAGE_PATH=./windows       # VM storage location
# Optional volumes:
# SHARED_PATH=./shared       # Shared folder
# OEM_PATH=./oem             # Custom installation scripts
```

### Benefits of .env Configuration

- **Version Control:** Keep `.env` out of git (sensitive data) while sharing `.env.example` (template)
- **Easy Updates:** Change configuration without editing compose file
- **Multiple Environments:** Use different .env files for different setups
- **Security:** Keep credentials separate from code
- **Portability:** Share compose.yml safely without exposing settings

---

## Installing Docker Desktop on Windows

### Overview

The `install-docker-desktop.ps1` script automates the installation of Docker Desktop on Windows with WSL2 backend support.

### Prerequisites

- Windows 10 version 2004 or higher (Build 19041+) or Windows 11
- Administrator privileges
- At least 4GB of RAM available
- Virtualization enabled in BIOS

### Installation Steps

1. **Download the script** (if not already cloned):
   ```powershell
   # From this repository
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bbj4t/windows/main/install-docker-desktop.ps1" -OutFile "install-docker-desktop.ps1"
   ```
   
   > **Note:** If using a different fork or repository, replace `bbj4t/windows` with the appropriate repository path.

2. **Open PowerShell as Administrator:**
   - Right-click on PowerShell
   - Select "Run as Administrator"

3. **Run the installation script:**
   ```powershell
   .\install-docker-desktop.ps1
   ```

### Script Options

```powershell
# Install specific version
.\install-docker-desktop.ps1 -Version "4.25.0"

# Install without WSL2 (Hyper-V backend)
.\install-docker-desktop.ps1 -EnableWSL2:$false

# Install without starting Docker Desktop
.\install-docker-desktop.ps1 -StartAfterInstall:$false

# Skip prerequisite checks
.\install-docker-desktop.ps1 -SkipPrerequisites
```

### What the Script Does

1. ✅ Checks Windows version compatibility
2. ✅ Enables WSL (Windows Subsystem for Linux) feature
3. ✅ Enables Virtual Machine Platform
4. ✅ Downloads Docker Desktop installer
5. ✅ Installs Docker Desktop with WSL2 backend
6. ✅ Starts Docker Desktop (optional)
7. ✅ Cleans up temporary files

### Post-Installation

After installation:

1. Wait for Docker Desktop to initialize (1-2 minutes)
2. Verify installation:
   ```powershell
   docker --version
   docker run hello-world
   ```
3. If prompted, restart your computer to complete WSL2 setup

### Troubleshooting

**Issue:** Docker fails to start after installation
- **Solution:** Restart your computer to complete WSL2 setup

**Issue:** "Virtualization not enabled" error
- **Solution:** Enable Intel VT-x or AMD-V in BIOS settings

**Issue:** WSL2 installation fails
- **Solution:** Run Windows Update and install all pending updates

---

## RustDesk: Alternative Remote Desktop Solution

### What is RustDesk?

RustDesk is an open-source remote desktop software that serves as an alternative to traditional RDP, TeamViewer, and AnyDesk. It offers:

- 🌐 **NAT Traversal:** Connect over the internet without port forwarding
- 🔒 **Custom Relay Servers:** Host your own relay for complete privacy
- 🆓 **Free and Open-Source:** No licensing costs or restrictions
- 🖥️ **Cross-Platform:** Windows, macOS, Linux, iOS, Android
- 🔐 **End-to-End Encryption:** Secure connections
- 🚀 **Low Latency:** Fast performance even over internet

### Installing RustDesk Client

#### Basic Installation

1. **Open PowerShell as Administrator:**
   ```powershell
   # Download and run the installation script
   .\install-rustdesk.ps1
   ```

2. **The script will:**
   - Download the latest RustDesk version
   - Install the client
   - Install the RustDesk service (for unattended access)
   - Start the application

#### Custom Relay Server Installation

To connect to your own RustDesk relay server:

```powershell
.\install-rustdesk.ps1 -RelayServer "relay.yourdomain.com" -Key "your-public-key"
```

#### Advanced Options

```powershell
# Install specific version
.\install-rustdesk.ps1 -Version "1.2.3"

# Custom relay with API server
.\install-rustdesk.ps1 -RelayServer "relay.example.com" -ApiServer "api.example.com" -Key "your-key"

# Install without service (portable mode)
.\install-rustdesk.ps1 -InstallService:$false

# Install without auto-start
.\install-rustdesk.ps1 -StartAfterInstall:$false
```

### Setting Up Your Own RustDesk Relay Server

If you want complete privacy and control, you can host your own RustDesk relay server:

1. **Server Requirements:**
   - Linux server (Ubuntu 20.04+ recommended)
   - Public IP address
   - Ports: 21115-21119 (TCP), 21116 (UDP)

2. **Quick Server Setup:**
   ```bash
   # On your Linux server
   wget https://raw.githubusercontent.com/rustdesk/rustdesk-server/master/install.sh
   chmod +x install.sh
   ./install.sh
   ```

3. **Get Your Server Key:**
   ```bash
   cat /var/lib/rustdesk-server/id_ed25519.pub
   ```

4. **Configure Clients:**
   Use the installation script with your server details:
   ```powershell
   .\install-rustdesk.ps1 -RelayServer "your-server-ip" -Key "your-public-key"
   ```

### Using RustDesk

#### For Remote Access (Client):

1. Launch RustDesk
2. Note your **RustDesk ID** (shown in main window)
3. Set a password for secure access (optional)
4. Share your ID with the person who needs to connect

#### For Connecting to Another Computer:

1. Launch RustDesk
2. Enter the remote **RustDesk ID**
3. Click "Connect"
4. Enter the password (if set)

### RustDesk Configuration Files

RustDesk stores its configuration in:
- **Windows:** `%APPDATA%\RustDesk\config\RustDesk2.toml`
- **Linux:** `~/.config/rustdesk/RustDesk2.toml`

Example configuration:
```toml
relay-server = 'relay.yourdomain.com'
api-server = 'api.yourdomain.com'
key = 'your-public-key-here'
```

---

## Comparison: RDP vs RustDesk

### When to Use RDP (Port 3389)

✅ **Use RDP when:**
- On a local network (LAN)
- Connected via VPN
- Need Windows-native features
- Require Windows Server features
- Maximum performance is critical
- Network policy requires it

### When to Use RustDesk

✅ **Use RustDesk when:**
- Connecting over the internet (no VPN needed)
- Behind NAT/firewall without port forwarding
- Need cross-platform access (mobile, Linux, Mac)
- Want complete privacy with your own relay server
- RDP port (3389) is blocked or unsafe to expose
- Need file transfer and clipboard sync
- Want free, open-source solution

### Feature Comparison

| Feature | RDP | RustDesk |
|---------|-----|----------|
| **Internet Access** | Requires VPN or port forwarding | ✅ Built-in NAT traversal |
| **Port Forwarding** | Required | ❌ Not needed |
| **Cross-Platform** | Limited | ✅ Full support |
| **Mobile Apps** | Basic | ✅ Full-featured |
| **Custom Relay** | ❌ Not available | ✅ Self-hosted option |
| **Privacy** | Microsoft servers | ✅ Your own servers |
| **Cost** | License required | ✅ Free & Open-Source |
| **File Transfer** | Mapped drives | ✅ Built-in |
| **Setup Complexity** | Medium | Easy |
| **Performance** | Excellent (LAN) | Good (Internet) |

### Recommended Setup

**Best Practice:** Use both!

1. **RDP (3389):** For local/VPN connections
2. **RustDesk:** For internet access and mobile

Example compose.yml configuration:
```yaml
services:
  windows:
    image: dockurr/windows
    ports:
      - "8006:8006"      # Web viewer
      - "3389:3389"      # RDP
    environment:
      VERSION: "11"
      USERNAME: "Docker"
      PASSWORD: "admin"
```

Then install RustDesk inside Windows VM using the installation script.

---

## Security Considerations

### For .env Files
- ✅ Never commit `.env` to git (use `.gitignore`)
- ✅ Use strong passwords
- ✅ Limit file permissions: `chmod 600 .env`
- ✅ Share `.env.example`, not `.env`

### For RDP
- ✅ Use strong passwords (12+ characters)
- ✅ Enable Network Level Authentication (NLA)
- ✅ Use VPN when accessing over internet
- ⚠️ Don't expose port 3389 directly to internet

### For RustDesk
- ✅ Set a strong password in RustDesk
- ✅ Use your own relay server for sensitive data
- ✅ Keep RustDesk updated
- ✅ Enable 2FA on your RustDesk account (if using public relay)

---

## Troubleshooting

### Docker Compose Issues

**Issue:** Environment variables not loading
```bash
# Solution: Ensure .env is in the same directory as compose.yml
ls -la .env
docker compose config  # Verify variables are loaded
```

**Issue:** Ports already in use
```bash
# Solution: Change ports in .env
WEB_PORT=8007
RDP_PORT_TCP=3390
```

### Docker Desktop Issues

**Issue:** WSL2 not working after install
```powershell
# Solution: Update WSL kernel
wsl --update
wsl --set-default-version 2
```

**Issue:** Docker service won't start
```powershell
# Solution: Restart Docker Desktop service
Restart-Service docker
```

### RustDesk Issues

**Issue:** Cannot connect to custom relay
```
# Solution: Check firewall and ports
- Verify ports 21115-21119 are open
- Check relay server is running
- Verify public key matches
```

**Issue:** RustDesk ID not showing
```powershell
# Solution: Restart RustDesk service
Restart-Service RustDesk
```

---

## Additional Resources

### Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [RustDesk Documentation](https://rustdesk.com/docs/)
- [RustDesk Server Setup](https://github.com/rustdesk/rustdesk-server)

### Community
- [Docker Community](https://www.docker.com/community/)
- [RustDesk Reddit](https://www.reddit.com/r/rustdesk/)
- [RustDesk Discord](https://discord.com/invite/nDceKgxnkV)

### Security
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [RustDesk Security](https://rustdesk.com/docs/en/security/)

---

## Contributing

If you have suggestions or improvements for these setup scripts:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

This project follows the same license as the main repository. See [license.md](license.md) for details.
