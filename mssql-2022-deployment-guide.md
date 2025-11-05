# Microsoft SQL Server 2022 CU19 Deployment Guide
## Ubuntu 24.04 LTS - Clean Installation Steps

**Target Version:** SQL Server 2022 (RTM-CU19) (KB5054531) - 16.0.4195.2
**Edition:** Developer Edition (64-bit)
**Tested On:** Ubuntu 24.04.3 LTS (Noble Numbat)

---

## Prerequisites

- Ubuntu 24.04 LTS (fresh installation recommended)
- Minimum 2 GB RAM (4 GB+ recommended)
- Minimum 6 GB disk space
- Root or sudo access
- Internet connection

---

## Installation Overview

This guide includes workarounds for Ubuntu 24.04 compatibility issues:
1. ✅ Using Ubuntu 22.04 repository (24.04 not yet available)
2. ✅ Installing OpenLDAP 2.5 libraries (Ubuntu 24.04 ships with 2.6)
3. ✅ Proper repository configuration with GPG signing

---

## Step 1: System Preparation

### 1.1 Verify System Information
```bash
# Check Ubuntu version
cat /etc/os-release

# Expected: Ubuntu 24.04 LTS (Noble Numbat)
```

### 1.2 Update System
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

---

## Step 2: Install Microsoft Repository Key

### 2.1 Import Microsoft GPG Key
```bash
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
```

**Expected Result:** No output indicates success

---

## Step 3: Add SQL Server Repository

### 3.1 Add SQL Server 2022 Repository (Ubuntu 22.04)
```bash
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022 jammy main" | \
  sudo tee /etc/apt/sources.list.d/mssql-server-2022.list
```

**Note:** Using Ubuntu 22.04 repository because 24.04 is not yet available

### 3.2 Update Package Lists
```bash
sudo apt-get update
```

**Expected Output:** Should fetch packages from packages.microsoft.com without GPG errors

---

## Step 4: Install SQL Server

### 4.1 Check Available Versions (Optional)
```bash
apt-cache madison mssql-server | grep 16.0.4195.2
```

**Expected Output:**
```
mssql-server | 16.0.4195.2-4 | https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022 jammy/main amd64 Packages
```

### 4.2 Install SQL Server 2022 CU19
```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mssql-server=16.0.4195.2-4
```

**Expected Output:**
```
Setting up mssql-server (16.0.4195.2-4) ...
+--------------------------------------------------------------+
Please run 'sudo /opt/mssql/bin/mssql-conf setup'
to complete the setup of Microsoft SQL Server
+--------------------------------------------------------------+
```

---

## Step 5: Fix OpenLDAP Dependency (Critical for Ubuntu 24.04)

**IMPORTANT:** Ubuntu 24.04 ships with OpenLDAP 2.6, but SQL Server 2022 requires OpenLDAP 2.5. This step is CRITICAL.

### 5.1 Download OpenLDAP 2.5 from Ubuntu 22.04
```bash
cd /tmp
wget http://security.ubuntu.com/ubuntu/pool/main/o/openldap/libldap-2.5-0_2.5.16+dfsg-0ubuntu0.22.04.2_amd64.deb
```

### 5.2 Extract Libraries
```bash
dpkg -x libldap-2.5-0_2.5.16+dfsg-0ubuntu0.22.04.2_amd64.deb /tmp/libldap-extract
```

### 5.3 Install OpenLDAP 2.5 Libraries
```bash
sudo cp /tmp/libldap-extract/usr/lib/x86_64-linux-gnu/liblber-2.5.so.0* /lib/x86_64-linux-gnu/
sudo cp /tmp/libldap-extract/usr/lib/x86_64-linux-gnu/libldap-2.5.so.0* /lib/x86_64-linux-gnu/
sudo ldconfig
```

### 5.4 Verify Libraries
```bash
ls -la /lib/x86_64-linux-gnu/liblber-2.5* /lib/x86_64-linux-gnu/libldap-2.5*
```

**Expected Output:**
```
-rw-r--r-- 1 root root  63992 ... /lib/x86_64-linux-gnu/liblber-2.5.so.0
-rw-r--r-- 1 root root  63992 ... /lib/x86_64-linux-gnu/liblber-2.5.so.0.1.11
-rw-r--r-- 1 root root 376512 ... /lib/x86_64-linux-gnu/libldap-2.5.so.0
-rw-r--r-- 1 root root 376512 ... /lib/x86_64-linux-gnu/libldap-2.5.so.0.1.11
```

### 5.5 Verify No Missing Dependencies
```bash
ldd /opt/mssql/bin/sqlservr | grep -i "not found"
```

**Expected Output:** No output (all dependencies satisfied)

---

## Step 6: Configure SQL Server

### 6.1 Run Initial Setup
```bash
sudo MSSQL_SA_PASSWORD='YourStr0ng!Password' \
     MSSQL_PID='Developer' \
     /opt/mssql/bin/mssql-conf -n setup accept-eula
```

**Replace `YourStr0ng!Password` with your own strong password.**

**Password Requirements:**
- At least 8 characters
- Contains uppercase letters
- Contains lowercase letters
- Contains digits
- Contains special characters

**Expected Output:**
```
Configuring SQL Server...
Setup has completed successfully. SQL Server is now starting.
```

### 6.2 Start SQL Server Service
```bash
sudo systemctl start mssql-server
```

### 6.3 Verify Service Status
```bash
sudo systemctl status mssql-server
```

**Expected Output:**
```
● mssql-server.service - Microsoft SQL Server Database Engine
     Loaded: loaded
     Active: active (running)
```

### 6.4 Enable Service to Start on Boot
```bash
sudo systemctl enable mssql-server
```

---

## Step 7: Install SQL Server Command-Line Tools

### 7.1 Add Microsoft Production Repository
```bash
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" | \
  sudo tee /etc/apt/sources.list.d/mssql-prod.list
```

### 7.2 Update Package Lists
```bash
sudo apt-get update
```

### 7.3 Install SQL Server Tools
```bash
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
```

**Expected Output:**
```
Setting up msodbcsql18 (18.5.1.1-1) ...
Setting up mssql-tools18 (18.4.1.1-1) ...
```

### 7.4 Add Tools to PATH (Optional but Recommended)
```bash
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

---

## Step 8: Verify Installation

### 8.1 Test Connection
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStr0ng!Password' -C -Q "SELECT @@VERSION" -W
```

**Replace `YourStr0ng!Password` with the password you set in Step 6.1**

**Expected Output:**
```
Microsoft SQL Server 2022 (RTM-CU19) (KB5054531) - 16.0.4195.2 (X64)
	Apr 18 2025 13:42:14
	Copyright (C) 2022 Microsoft Corporation
	Developer Edition (64-bit) on Linux (Ubuntu 24.04.3 LTS) <X64>

(1 rows affected)
```

### 8.2 Interactive Connection Test
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourStr0ng!Password' -C
```

**Once connected, try:**
```sql
SELECT name FROM sys.databases;
GO

SELECT @@SERVERNAME;
GO

quit
```

---

## Step 9: Security Hardening

### 9.1 Change SA Password (Recommended)
```bash
sudo systemctl stop mssql-server
sudo /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server
```

### 9.2 Configure Firewall (If Needed)
```bash
# Allow SQL Server default port
sudo ufw allow 1433/tcp

# Or allow from specific IP
sudo ufw allow from 192.168.1.0/24 to any port 1433
```

### 9.3 Enable Encryption (Optional)
```bash
sudo /opt/mssql/bin/mssql-conf set network.forceencryption 1
sudo systemctl restart mssql-server
```

---

## Post-Installation Tasks

### Configure SQL Server Memory
```bash
# Set maximum memory (in MB) - recommended: leave 25% for OS
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 2048
sudo systemctl restart mssql-server
```

### Enable SQL Server Agent
```bash
sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true
sudo systemctl restart mssql-server
```

### Configure Trace Flags (If Needed)
```bash
sudo /opt/mssql/bin/mssql-conf traceflag 1234 on
sudo systemctl restart mssql-server
```

---

## Service Management Commands

### Check Service Status
```bash
sudo systemctl status mssql-server
```

### Start Service
```bash
sudo systemctl start mssql-server
```

### Stop Service
```bash
sudo systemctl stop mssql-server
```

### Restart Service
```bash
sudo systemctl restart mssql-server
```

### View Real-Time Logs
```bash
# Using journalctl
sudo journalctl -u mssql-server -f

# Using SQL Server error log
sudo tail -f /var/opt/mssql/log/errorlog
```

### Check SQL Server Version
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -C -Q "SELECT @@VERSION" -W
```

---

## Troubleshooting

### Issue: Service Won't Start

**Check logs:**
```bash
sudo journalctl -u mssql-server -n 50
sudo cat /var/opt/mssql/log/errorlog | tail -50
```

**Check dependencies:**
```bash
ldd /opt/mssql/bin/sqlservr | grep -i "not found"
```

**Common causes:**
- Missing OpenLDAP 2.5 libraries (see Step 5)
- Insufficient memory (minimum 2 GB RAM required)
- Port 1433 already in use

### Issue: Cannot Connect with SA User

**Reset SA password:**
```bash
sudo systemctl stop mssql-server
sudo MSSQL_SA_PASSWORD='NewStr0ng!Password' /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server
```

### Issue: "Login failed" Error

**Check if SQL Server is running:**
```bash
sudo systemctl status mssql-server
```

**Check if listening on port 1433:**
```bash
sudo netstat -tlnp | grep 1433
# or
sudo ss -tlnp | grep 1433
```

**Check error log:**
```bash
sudo grep -i "login" /var/opt/mssql/log/errorlog | tail -20
```

### Issue: High Memory Usage

**Check current memory configuration:**
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -C -Q "EXEC sp_configure 'max server memory'" -W
```

**Set memory limit:**
```bash
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 2048
sudo systemctl restart mssql-server
```

### Issue: OpenLDAP Library Errors

**Re-verify libraries are installed:**
```bash
ls -la /lib/x86_64-linux-gnu/liblber-2.5* /lib/x86_64-linux-gnu/libldap-2.5*
```

**Check library versions:**
```bash
strings /lib/x86_64-linux-gnu/liblber-2.5.so.0 | grep OPENLDAP
```

**Expected output should include:** `OPENLDAP_2.5_0`

**If missing, repeat Step 5**

---

## Backup and Restore

### Create Database Backup
```sql
-- Connect to SQL Server
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -C

-- Create backup
BACKUP DATABASE [YourDatabase]
TO DISK = N'/var/opt/mssql/data/YourDatabase.bak'
WITH FORMAT, INIT;
GO
```

### Restore Database
```sql
RESTORE DATABASE [YourDatabase]
FROM DISK = N'/var/opt/mssql/data/YourDatabase.bak'
WITH REPLACE;
GO
```

---

## Uninstallation (If Needed)

### Remove SQL Server Completely
```bash
# Stop service
sudo systemctl stop mssql-server

# Remove packages
sudo apt-get purge -y mssql-server mssql-tools18 msodbcsql18

# Remove data and logs
sudo rm -rf /var/opt/mssql
sudo rm -rf /opt/mssql

# Remove repositories
sudo rm /etc/apt/sources.list.d/mssql-server-2022.list
sudo rm /etc/apt/sources.list.d/mssql-prod.list

# Remove OpenLDAP 2.5 libraries (optional)
sudo rm /lib/x86_64-linux-gnu/liblber-2.5*
sudo rm /lib/x86_64-linux-gnu/libldap-2.5*
sudo ldconfig

# Update package lists
sudo apt-get update
```

---

## Important File Locations

| Component | Location |
|-----------|----------|
| SQL Server Binaries | `/opt/mssql/` |
| Database Files | `/var/opt/mssql/data/` |
| Log Files | `/var/opt/mssql/log/` |
| Configuration | `/var/opt/mssql/mssql.conf` |
| Systemd Service | `/usr/lib/systemd/system/mssql-server.service` |
| Command-Line Tools | `/opt/mssql-tools18/bin/` |
| ODBC Driver | `/opt/microsoft/msodbcsql18/` |

---

## Configuration Files

### mssql.conf Location
```bash
/var/opt/mssql/mssql.conf
```

### View Current Configuration
```bash
cat /var/opt/mssql/mssql.conf
```

### Example mssql.conf
```ini
[EULA]
accepteula = Y

[coredump]
captureminiandfull = true

[filelocation]
defaultbackupdir = /var/opt/mssql/data/
defaultdatadir = /var/opt/mssql/data/
defaultdumpdir = /var/opt/mssql/data/
defaultlogdir = /var/opt/mssql/data/

[language]
lcid = 1033

[memory]
memorylimitmb = 2048

[network]
forceencryption = 0
ipaddress = 0.0.0.0
tcpport = 1433
```

---

## Quick Reference Commands

### Connection String Format
```
Server=localhost,1433;Database=master;User Id=SA;Password=YourStr0ng!Password;TrustServerCertificate=True;
```

### Quick Connection
```bash
sqlcmd -S localhost -U SA -C
```

### Execute Query from Command Line
```bash
sqlcmd -S localhost -U SA -C -Q "SELECT name FROM sys.databases"
```

### Execute SQL File
```bash
sqlcmd -S localhost -U SA -C -i /path/to/script.sql
```

### Export Query Results to File
```bash
sqlcmd -S localhost -U SA -C -Q "SELECT * FROM sys.databases" -o output.txt
```

---

## Performance Tuning Tips

### 1. Set Appropriate Memory Limits
```bash
# Leave 25% memory for OS
# For 8 GB system: set to 6144 MB
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 6144
```

### 2. Enable Lock Pages in Memory (For Production)
```bash
sudo /opt/mssql/bin/mssql-conf set memory.enablelockedpagesinsql true
```

### 3. Configure TempDB
```sql
-- Add multiple TempDB files (1 per CPU core, up to 8)
ALTER DATABASE tempdb ADD FILE (NAME = tempdev2, FILENAME = '/var/opt/mssql/data/tempdb2.ndf', SIZE = 8MB, FILEGROWTH = 64MB);
ALTER DATABASE tempdb ADD FILE (NAME = tempdev3, FILENAME = '/var/opt/mssql/data/tempdb3.ndf', SIZE = 8MB, FILEGROWTH = 64MB);
ALTER DATABASE tempdb ADD FILE (NAME = tempdev4, FILENAME = '/var/opt/mssql/data/tempdb4.ndf', SIZE = 8MB, FILEGROWTH = 64MB);
GO
```

### 4. Set Max Degree of Parallelism
```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max degree of parallelism', 4; -- Set to number of CPU cores
RECONFIGURE;
GO
```

---

## System Requirements

### Minimum Requirements
- **Processor:** x64-compatible 1.4 GHz
- **Memory:** 2 GB RAM
- **Disk Space:** 6 GB
- **File System:** XFS or EXT4
- **Network:** TCP port 1433 available

### Recommended Requirements
- **Processor:** x64-compatible 2.0 GHz or faster, 4+ cores
- **Memory:** 8 GB RAM or more
- **Disk Space:** 20 GB or more (depends on database size)
- **File System:** XFS (best performance)
- **Disk:** SSD for database files

---

## Additional Resources

### Official Documentation
- SQL Server on Linux: https://docs.microsoft.com/en-us/sql/linux/
- SQL Server 2022 Release Notes: https://docs.microsoft.com/en-us/sql/sql-server/

### Useful Commands Documentation
- sqlcmd utility: https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility
- mssql-conf: https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-mssql-conf

---

## Version Information

- **Guide Version:** 1.0
- **Last Updated:** November 5, 2025
- **Tested On:** Ubuntu 24.04.3 LTS
- **SQL Server Version:** 2022 (RTM-CU19) - 16.0.4195.2
- **Package Version:** mssql-server=16.0.4195.2-4

---

## License

Microsoft SQL Server Developer Edition is free for development and testing purposes. For production use, you need to purchase a license or use Express/Standard/Enterprise editions.

---

## Support and Updates

For the latest updates and security patches:
```bash
# Check for updates
apt-cache policy mssql-server

# Update to latest CU
sudo apt-get update
sudo apt-get upgrade mssql-server
```

---

## End of Guide

This guide provides a complete, tested deployment procedure for SQL Server 2022 CU19 on Ubuntu 24.04 LTS with all necessary workarounds for compatibility issues.

For issues or questions, consult the official Microsoft documentation or the troubleshooting section above.
