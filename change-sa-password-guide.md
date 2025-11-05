# How to Change SQL Server SA Password via CLI

Complete guide for changing the SA (System Administrator) password in Microsoft SQL Server 2022 on Ubuntu 24.04 LTS using command-line interface.

---

## Table of Contents

1. [Quick Methods](#quick-methods)
2. [Method 1: Using mssql-conf (Recommended)](#method-1-using-mssql-conf-recommended)
3. [Method 2: Using sqlcmd](#method-2-using-sqlcmd)
4. [Method 3: Interactive mssql-conf](#method-3-interactive-mssql-conf)
5. [Verification](#verification)
6. [Password Requirements](#password-requirements)
7. [Troubleshooting](#troubleshooting)
8. [Security Best Practices](#security-best-practices)

---

## Quick Methods

### Quick Change (One Command)
```bash
sudo systemctl stop mssql-server && \
sudo MSSQL_SA_PASSWORD='YourNewStr0ng!Password' /opt/mssql/bin/mssql-conf set-sa-password && \
sudo systemctl start mssql-server
```

**Replace `YourNewStr0ng!Password` with your desired password.**

---

## Method 1: Using mssql-conf (Recommended)

This is the **safest and recommended method** for changing the SA password.

### Step 1: Stop SQL Server Service

```bash
sudo systemctl stop mssql-server
```

**Expected Output:**
```
(No output - service stopped successfully)
```

### Step 2: Set New Password

```bash
sudo MSSQL_SA_PASSWORD='YourNewStr0ng!Password' /opt/mssql/bin/mssql-conf set-sa-password
```

**Replace `YourNewStr0ng!Password` with your actual new password.**

**Expected Output:**
```
Configuring SQL Server...
The system administrator password has been changed.
Please run 'sudo systemctl start mssql-server' to start SQL Server.
```

### Step 3: Start SQL Server Service

```bash
sudo systemctl start mssql-server
```

**Wait a few seconds for the service to fully start:**
```bash
sleep 5
```

### Step 4: Verify Service is Running

```bash
sudo systemctl status mssql-server
```

**Expected Output:**
```
● mssql-server.service - Microsoft SQL Server Database Engine
     Loaded: loaded
     Active: active (running)
```

### Step 5: Test New Password

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourNewStr0ng!Password' -C -Q "SELECT @@VERSION"
```

---

## Method 2: Using sqlcmd

This method changes the password while SQL Server is running.

### Prerequisites

- SQL Server must be running
- You must know the current SA password

### Step 1: Connect to SQL Server

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'CurrentPassword' -C
```

### Step 2: Execute Password Change Command

At the `1>` prompt, enter:

```sql
ALTER LOGIN SA WITH PASSWORD = 'YourNewStr0ng!Password';
GO
```

**Expected Output:**
```
(0 rows affected)
```

### Step 3: Exit sqlcmd

```sql
EXIT
```
or press `Ctrl+C`

### Step 4: Test New Password

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourNewStr0ng!Password' -C -Q "SELECT @@VERSION"
```

### One-Line Command (Using sqlcmd)

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'CurrentPassword' -C -Q "ALTER LOGIN SA WITH PASSWORD = 'YourNewStr0ng!Password';"
```

---

## Method 3: Interactive mssql-conf

This method prompts you to enter the password interactively (more secure - doesn't show in command history).

### Step 1: Stop SQL Server

```bash
sudo systemctl stop mssql-server
```

### Step 2: Run Interactive Password Change

```bash
sudo /opt/mssql/bin/mssql-conf set-sa-password
```

**You'll be prompted:**
```
Enter the SQL Server system administrator password:
Confirm the SQL Server system administrator password:
```

Type your new password (it won't be displayed) and press Enter.

### Step 3: Start SQL Server

```bash
sudo systemctl start mssql-server
```

### Step 4: Test Connection

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -C
```

Enter your new password when prompted.

---

## Verification

### Verify Password Was Changed Successfully

**Method 1: Simple Version Check**
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourNewPassword' -C -Q "SELECT @@VERSION"
```

**Method 2: Full Connection Test**
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourNewPassword' -C -Q "SELECT SUSER_NAME() AS CurrentUser, GETDATE() AS CurrentDateTime"
```

**Expected Output:**
```
CurrentUser CurrentDateTime
----------- ---------------
sa          2025-11-05 15:30:00.000

(1 rows affected)
```

### Check SQL Server Service Status

```bash
sudo systemctl status mssql-server --no-pager
```

### View Recent Login Attempts (Optional)

```bash
sudo tail -20 /var/opt/mssql/log/errorlog | grep -i "login"
```

---

## Password Requirements

SQL Server passwords must meet the following requirements:

### Minimum Requirements

- ✅ **At least 8 characters** long
- ✅ **Contains uppercase** letters (A-Z)
- ✅ **Contains lowercase** letters (a-z)
- ✅ **Contains digits** (0-9)
- ✅ **Contains special characters** (e.g., !@#$%^&*()_+-=[]{}|;:,.<>?)

### Examples of Valid Passwords

```
✓ MyStr0ng!Password
✓ Admin@2024
✓ P@ssw0rd123!
✓ Secure#Pass2024
✓ DbAdmin!2024
```

### Examples of Invalid Passwords

```
✗ password          (too simple, no uppercase/special chars)
✗ Password          (no digits/special chars)
✗ Password123       (no special characters)
✗ Pass!             (too short)
✗ 12345678          (no letters)
```

---

## Troubleshooting

### Issue 1: Password Change Fails

**Error:**
```
The password does not meet SQL Server password policy requirements
```

**Solution:**
Ensure your password meets all requirements (see Password Requirements section above).

**Example Fix:**
```bash
# Bad password
sudo MSSQL_SA_PASSWORD='simple' /opt/mssql/bin/mssql-conf set-sa-password

# Good password
sudo MSSQL_SA_PASSWORD='MyStr0ng!Pass2024' /opt/mssql/bin/mssql-conf set-sa-password
```

---

### Issue 2: SQL Server Won't Start After Password Change

**Error:**
```
Job for mssql-server.service failed
```

**Solution:**

1. Check the error log:
```bash
sudo journalctl -u mssql-server -n 50 --no-pager
```

2. Try resetting the password again:
```bash
sudo systemctl stop mssql-server
sudo MSSQL_SA_PASSWORD='ValidStr0ng!Pass' /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server
```

3. Wait longer for service to start:
```bash
sudo systemctl start mssql-server
sleep 10
sudo systemctl status mssql-server
```

---

### Issue 3: Login Failed After Password Change

**Error:**
```
Login failed for user 'SA'. (Error: 18456)
```

**Possible Causes:**

1. **Password typed incorrectly** - Double-check for typos
2. **Special characters in shell** - Escape or quote properly
3. **Cache in GUI tools** - Clear cached credentials

**Solutions:**

**Clear and verify:**
```bash
# Test current password
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourPassword' -C -Q "SELECT 1"

# If fails, reset password
sudo systemctl stop mssql-server
sudo MSSQL_SA_PASSWORD='NewValidP@ss123' /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server
sleep 10

# Test again
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'NewValidP@ss123' -C -Q "SELECT @@VERSION"
```

**For GUI tools (SSMS/Azure Data Studio):**
- Remove saved credentials
- Re-enter password manually
- Check "Trust Server Certificate"

---

### Issue 4: Special Characters in Password

If your password contains special characters like `$`, `!`, `\`, or `` ` ``, you need to properly escape them.

**Problem:**
```bash
# This may fail due to shell interpretation
sudo MSSQL_SA_PASSWORD='P@ss$word!' /opt/mssql/bin/mssql-conf set-sa-password
```

**Solution - Use Single Quotes:**
```bash
# Single quotes prevent shell interpretation
sudo MSSQL_SA_PASSWORD='P@ss$word!' /opt/mssql/bin/mssql-conf set-sa-password
```

**Solution - Escape Special Characters:**
```bash
# Escape with backslash
sudo MSSQL_SA_PASSWORD="P@ss\$word\!" /opt/mssql/bin/mssql-conf set-sa-password
```

**Best Practice - Use Interactive Mode:**
```bash
sudo systemctl stop mssql-server
sudo /opt/mssql/bin/mssql-conf set-sa-password
# Enter password when prompted (no escaping needed)
sudo systemctl start mssql-server
```

---

## Security Best Practices

### 1. Use Strong Passwords

**Good Example:**
```bash
sudo MSSQL_SA_PASSWORD='MyC0mplex!Passw0rd#2024' /opt/mssql/bin/mssql-conf set-sa-password
```

**Characteristics:**
- At least 12+ characters
- Mix of uppercase, lowercase, numbers, symbols
- No dictionary words
- Not related to username or server name

### 2. Avoid Storing Passwords in Scripts

**❌ Bad Practice:**
```bash
#!/bin/bash
PASSWORD="Admin@123"  # Never do this!
sqlcmd -S localhost -U SA -P $PASSWORD -C
```

**✅ Good Practice:**
```bash
#!/bin/bash
# Prompt for password
read -sp "Enter SA password: " PASSWORD
echo
sqlcmd -S localhost -U SA -P "$PASSWORD" -C
```

### 3. Use Environment Variables (For Automation)

**For automated scripts only (not for manual use):**
```bash
export MSSQL_SA_PASSWORD='YourStr0ng!Password'
sudo -E /opt/mssql/bin/mssql-conf set-sa-password
```

### 4. Rotate Passwords Regularly

Set a reminder to change the SA password every 90 days:

```bash
# Add to crontab or calendar
# Change password quarterly
sudo systemctl stop mssql-server
sudo /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server
```

### 5. Create Additional Admin Users

Don't rely solely on the SA account:

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -C << EOF
CREATE LOGIN MyAdmin WITH PASSWORD = 'Str0ng!Pass123';
GO
ALTER SERVER ROLE sysadmin ADD MEMBER MyAdmin;
GO
EXIT
EOF
```

### 6. Disable SA Account (Optional - Advanced)

For production environments:

```sql
ALTER LOGIN SA DISABLE;
GO
```

**To re-enable:**
```sql
ALTER LOGIN SA ENABLE;
GO
```

### 7. Monitor Failed Login Attempts

Check logs regularly:
```bash
sudo grep "Login failed" /var/opt/mssql/log/errorlog | tail -20
```

Set up alerts for multiple failed attempts:
```bash
sudo journalctl -u mssql-server -f | grep "Login failed"
```

---

## Quick Reference Card

### Change Password (Stop/Start Method)
```bash
sudo systemctl stop mssql-server
sudo MSSQL_SA_PASSWORD='NewP@ssw0rd' /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server
```

### Change Password (While Running)
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'CurrentPass' -C -Q "ALTER LOGIN SA WITH PASSWORD = 'NewPass';"
```

### Test Connection
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'YourPassword' -C -Q "SELECT @@VERSION"
```

### Check Service Status
```bash
sudo systemctl status mssql-server
```

### View Logs
```bash
sudo journalctl -u mssql-server -n 50
sudo tail -50 /var/opt/mssql/log/errorlog
```

---

## Complete Example: Changing from Admin@123 to New Password

### Step-by-Step Example

Let's change the password from `Admin@123` to `MySecure!Pass2024`:

```bash
# Step 1: Stop SQL Server
sudo systemctl stop mssql-server

# Step 2: Set new password
sudo MSSQL_SA_PASSWORD='MySecure!Pass2024' /opt/mssql/bin/mssql-conf set-sa-password

# Step 3: Start SQL Server
sudo systemctl start mssql-server

# Step 4: Wait for service to be ready
sleep 10

# Step 5: Verify service is running
sudo systemctl status mssql-server --no-pager | grep Active

# Step 6: Test new password
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'MySecure!Pass2024' -C -Q "SELECT @@VERSION, SUSER_NAME() AS CurrentUser, GETDATE() AS LoginTime"

# Step 7: Confirm success
echo "Password changed successfully from Admin@123 to MySecure!Pass2024"
```

---

## Automated Password Change Script

Save this as `change-mssql-password.sh`:

```bash
#!/bin/bash

# SQL Server SA Password Change Script
# Usage: sudo ./change-mssql-password.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}SQL Server SA Password Change Tool${NC}"
echo "======================================"
echo

# Prompt for current password
read -sp "Enter current SA password: " CURRENT_PASSWORD
echo

# Prompt for new password
read -sp "Enter new SA password: " NEW_PASSWORD
echo

# Prompt for confirmation
read -sp "Confirm new SA password: " NEW_PASSWORD_CONFIRM
echo

# Check if passwords match
if [ "$NEW_PASSWORD" != "$NEW_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords do not match!${NC}"
    exit 1
fi

# Validate password strength (basic check)
if [ ${#NEW_PASSWORD} -lt 8 ]; then
    echo -e "${RED}Error: Password must be at least 8 characters!${NC}"
    exit 1
fi

echo
echo "Changing password..."
echo

# Stop SQL Server
echo -e "${YELLOW}[1/5]${NC} Stopping SQL Server..."
sudo systemctl stop mssql-server

# Set new password
echo -e "${YELLOW}[2/5]${NC} Setting new password..."
sudo MSSQL_SA_PASSWORD="$NEW_PASSWORD" /opt/mssql/bin/mssql-conf set-sa-password

# Start SQL Server
echo -e "${YELLOW}[3/5]${NC} Starting SQL Server..."
sudo systemctl start mssql-server

# Wait for service
echo -e "${YELLOW}[4/5]${NC} Waiting for SQL Server to be ready..."
sleep 10

# Test connection
echo -e "${YELLOW}[5/5]${NC} Testing new password..."
if /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$NEW_PASSWORD" -C -Q "SELECT 1" &>/dev/null; then
    echo
    echo -e "${GREEN}✓ Password changed successfully!${NC}"
    echo
else
    echo
    echo -e "${RED}✗ Password change failed - connection test unsuccessful${NC}"
    echo -e "${YELLOW}Attempting to restore previous password...${NC}"
    sudo systemctl stop mssql-server
    sudo MSSQL_SA_PASSWORD="$CURRENT_PASSWORD" /opt/mssql/bin/mssql-conf set-sa-password
    sudo systemctl start mssql-server
    exit 1
fi
```

**Make it executable:**
```bash
chmod +x change-mssql-password.sh
```

**Run it:**
```bash
sudo ./change-mssql-password.sh
```

---

## Additional Resources

- [Official SQL Server on Linux Documentation](https://docs.microsoft.com/en-us/sql/linux/)
- [mssql-conf Documentation](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-mssql-conf)
- [SQL Server Security Best Practices](https://docs.microsoft.com/en-us/sql/relational-databases/security/)

---

## Summary

**Recommended Method:**
```bash
sudo systemctl stop mssql-server && \
sudo MSSQL_SA_PASSWORD='YourNewStr0ng!Password' /opt/mssql/bin/mssql-conf set-sa-password && \
sudo systemctl start mssql-server
```

**Key Points:**
- Always use strong passwords (8+ chars, mixed case, numbers, symbols)
- Test the new password after changing
- Keep passwords secure (don't store in scripts)
- Consider creating additional admin accounts
- Rotate passwords regularly
- Monitor failed login attempts

---

**Document Version:** 1.0
**Last Updated:** November 5, 2025
**Tested On:** Ubuntu 24.04.3 LTS with SQL Server 2022 CU19
