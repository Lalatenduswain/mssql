# Microsoft SQL Server 2022 CU19 Installation Documentation

Complete documentation for installing Microsoft SQL Server 2022 (RTM-CU19) Developer Edition on Ubuntu 24.04 LTS.

## 🚀 Automated Installation Script (NEW!)

**File:** `install-mssql-2022-ubuntu2404.sh` (23 KB)

**One-command installation** - Fully automated script that handles everything:
- ✅ System requirements check
- ✅ Microsoft GPG key import
- ✅ Repository configuration
- ✅ SQL Server 2022 CU19 installation
- ✅ OpenLDAP 2.5 dependency fix (Ubuntu 24.04)
- ✅ SQL Server configuration
- ✅ Service startup and verification
- ✅ Command-line tools installation
- ✅ Complete installation verification

### Quick Installation

```bash
# Download and run the automated script
wget https://raw.githubusercontent.com/Lalatenduswain/mssql/main/install-mssql-2022-ubuntu2404.sh
chmod +x install-mssql-2022-ubuntu2404.sh
sudo ./install-mssql-2022-ubuntu2404.sh -y
```

### Script Features

- **🎨 Color-coded output** for easy progress tracking
- **📊 Progress indicators** for long-running tasks
- **✔️ Validation checks** at each step
- **🔍 Automatic troubleshooting** and error recovery
- **📝 Detailed logging** to `/tmp/mssql-install-*.log`
- **⚙️ Configurable options** via command-line arguments

### Usage Options

```bash
# Show help
sudo ./install-mssql-2022-ubuntu2404.sh --help

# Install with custom password
sudo ./install-mssql-2022-ubuntu2404.sh -p 'MyStr0ng!Pass' -y

# Install with custom memory limit (4 GB)
sudo ./install-mssql-2022-ubuntu2404.sh -p 'MyStr0ng!Pass' -m 4096 -y

# Install Express edition
sudo ./install-mssql-2022-ubuntu2404.sh -e Express -y
```

### Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-p, --password` | SA password | SQLServer2022! |
| `-e, --edition` | Edition (Developer, Express, Standard, Enterprise) | Developer |
| `-m, --memory` | Max memory in MB | Auto-calculated |
| `-y, --yes` | Skip confirmations | Interactive |
| `-h, --help` | Show help message | - |

### What the Script Does

1. ✅ **System Check** - Verifies Ubuntu version, memory, disk space, network
2. ✅ **GPG Key** - Imports Microsoft package signing key
3. ✅ **Repository** - Adds SQL Server 2022 repository (Ubuntu 22.04 compat)
4. ✅ **Installation** - Installs SQL Server 2022 CU19 package
5. ✅ **OpenLDAP Fix** - Downloads and installs OpenLDAP 2.5 libraries
6. ✅ **Configuration** - Sets up SQL Server with your password
7. ✅ **Service Start** - Starts and enables SQL Server service
8. ✅ **Tools** - Installs sqlcmd and related utilities
9. ✅ **Verification** - Tests connection and validates version
10. ✅ **Summary** - Displays connection details and next steps

## 📚 Documentation Files

### 1. SA Password Change Guide (NEW!)
**File:** `change-sa-password-guide.md`

Complete guide for changing the SQL Server SA password via command-line interface:
- ✅ Multiple methods (mssql-conf, sqlcmd, interactive)
- ✅ Step-by-step instructions with examples
- ✅ Password requirements and validation
- ✅ Troubleshooting common issues
- ✅ Security best practices
- ✅ Automated password change script
- ✅ Quick reference commands

**Quick Example:**
```bash
sudo systemctl stop mssql-server
sudo MSSQL_SA_PASSWORD='YourNewStr0ng!Password' /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server
```

### 2. Professional PDF Documentation
**File:** `mssql-2022-documentation.pdf` (258 KB)

A beautifully formatted, publication-quality PDF document with:
- Professional title page
- Complete table of contents with hyperlinks
- Color-coded command boxes
- Syntax-highlighted code blocks
- Warning and note boxes
- Professional typography

### 2. Complete Session Log
**File:** `mssql-2022-installation-session-log.md` (19 KB)

Detailed forensic record including:
- All 47 installation steps executed
- 12 failed attempts with error messages
- All troubleshooting steps and reasoning
- 4 critical issues and their resolutions
- Complete command outputs
- Timeline of events

### 3. Clean Deployment Guide
**File:** `mssql-2022-deployment-guide.md` (15 KB)

Reusable installation guide with:
- Step-by-step instructions
- All critical workarounds included
- Ubuntu 24.04 compatibility fixes
- Troubleshooting section
- Post-installation tasks
- Performance tuning tips

## 🎯 Key Information

**Target Configuration:**
- **SQL Server Version:** 16.0.4195.2 (RTM-CU19)
- **Knowledge Base:** KB5054531
- **Operating System:** Ubuntu 24.04.3 LTS (Noble Numbat)
- **Edition:** Developer Edition (64-bit)
- **Package Version:** mssql-server=16.0.4195.2-4
- **Date Verified:** November 5, 2025

## ⚠️ Critical Ubuntu 24.04 Compatibility Issues

### Issue 1: Repository Availability
- **Problem:** Microsoft doesn't have SQL Server repository for Ubuntu 24.04 yet
- **Solution:** Use Ubuntu 22.04 (jammy) repository

### Issue 2: OpenLDAP Version Mismatch
- **Problem:** Ubuntu 24.04 ships with OpenLDAP 2.6, SQL Server requires OpenLDAP 2.5
- **Solution:** Download and install OpenLDAP 2.5 libraries from Ubuntu 22.04 packages

### Issue 3: GPG Signature Configuration
- **Problem:** Repository missing signed-by configuration
- **Solution:** Add `signed-by=/usr/share/keyrings/microsoft-prod.gpg` to repository configuration

### Issue 4: SA Password Authentication
- **Problem:** Initial password configuration may fail
- **Solution:** Reset using `mssql-conf set-sa-password` command

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 LTS
- Minimum 2 GB RAM (8 GB recommended)
- Minimum 6 GB disk space
- Root or sudo access
- Internet connection

### Installation Steps

1. **Import Microsoft GPG Key:**
   ```bash
   curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
     sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
   ```

2. **Add SQL Server Repository:**
   ```bash
   echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022 jammy main" | \
     sudo tee /etc/apt/sources.list.d/mssql-server-2022.list
   sudo apt-get update
   ```

3. **Install SQL Server:**
   ```bash
   sudo apt-get install -y mssql-server=16.0.4195.2-4
   ```

4. **Fix OpenLDAP Dependency (CRITICAL):**
   ```bash
   cd /tmp
   wget http://security.ubuntu.com/ubuntu/pool/main/o/openldap/libldap-2.5-0_2.5.16+dfsg-0ubuntu0.22.04.2_amd64.deb
   dpkg -x libldap-2.5-0_2.5.16+dfsg-0ubuntu0.22.04.2_amd64.deb /tmp/libldap-extract
   sudo cp /tmp/libldap-extract/usr/lib/x86_64-linux-gnu/liblber-2.5.so.0* /lib/x86_64-linux-gnu/
   sudo cp /tmp/libldap-extract/usr/lib/x86_64-linux-gnu/libldap-2.5.so.0* /lib/x86_64-linux-gnu/
   sudo ldconfig
   ```

5. **Configure SQL Server:**
   ```bash
   sudo MSSQL_SA_PASSWORD='YourStr0ng!Password' \
        MSSQL_PID='Developer' \
        /opt/mssql/bin/mssql-conf -n setup accept-eula
   sudo systemctl start mssql-server
   sudo systemctl enable mssql-server
   ```

6. **Install SQL Server Tools:**
   ```bash
   echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" | \
     sudo tee /etc/apt/sources.list.d/mssql-prod.list
   sudo apt-get update
   sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
   ```

7. **Verify Installation:**
   ```bash
   /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStr0ng!Password' -C -Q "SELECT @@VERSION"
   ```

## 📖 Documentation Details

### PDF Document Contents
1. Executive Summary
2. Prerequisites
3. Installation Procedure (8 detailed steps)
4. Troubleshooting Guide (4 common issues)
5. Session History (complete timeline)
6. Post-Installation Configuration
7. Service Management
8. Quick Reference

### Total Statistics
- **Total Installation Steps:** 47
- **Failed Attempts:** 12
- **Critical Issues Resolved:** 4
- **Time to Resolution:** ~25 minutes
- **Package Downloads:** ~300 MB + ~1 GB LaTeX packages
- **Memory Usage:** ~781 MB
- **Disk Space Used:** ~1.4 GB

## 🔧 Service Management

```bash
# Check status
sudo systemctl status mssql-server

# Start/Stop/Restart
sudo systemctl start mssql-server
sudo systemctl stop mssql-server
sudo systemctl restart mssql-server

# View logs
sudo journalctl -u mssql-server -f
sudo tail -f /var/opt/mssql/log/errorlog
```

## 📂 Important File Locations

| Component | Location |
|-----------|----------|
| SQL Server Binaries | `/opt/mssql/` |
| Database Files | `/var/opt/mssql/data/` |
| Log Files | `/var/opt/mssql/log/` |
| Configuration | `/var/opt/mssql/mssql.conf` |
| Command-Line Tools | `/opt/mssql-tools18/bin/` |

## 🔗 Resources

- [Official SQL Server on Linux Documentation](https://docs.microsoft.com/en-us/sql/linux/)
- [SQL Server 2022 Release Notes](https://docs.microsoft.com/en-us/sql/sql-server/)
- [sqlcmd Utility](https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility)

## 📝 License

Microsoft SQL Server Developer Edition is free for development and testing purposes. For production use, you need to purchase a license or use Express/Standard/Enterprise editions.

## 🤝 Contributing

For issues or suggestions, please open an issue or submit a pull request.

## 📧 Contact

Repository maintained by: Lalatendu Swain

---

**Document Version:** 1.0
**Last Updated:** November 5, 2025
**Tested and Verified:** Ubuntu 24.04.3 LTS
