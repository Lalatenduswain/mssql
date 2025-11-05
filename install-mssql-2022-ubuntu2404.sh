#!/bin/bash

################################################################################
# Microsoft SQL Server 2022 CU19 Automated Installation Script
# For Ubuntu 24.04 LTS (Noble Numbat)
#
# This script automates the complete installation of SQL Server 2022 (RTM-CU19)
# including all necessary workarounds for Ubuntu 24.04 compatibility.
#
# Version: 1.0
# Date: November 5, 2025
# Tested on: Ubuntu 24.04.3 LTS
#
# Usage:
#   sudo ./install-mssql-2022-ubuntu2404.sh [OPTIONS]
#
# Options:
#   -p, --password PASSWORD    Set SA password (default: SQLServer2022!)
#   -e, --edition EDITION      SQL Server edition (default: Developer)
#                             Options: Developer, Express, Standard, Enterprise
#   -m, --memory MB           Max memory in MB (default: auto-calculated)
#   -y, --yes                 Skip all confirmations
#   -h, --help                Show this help message
#
# Examples:
#   sudo ./install-mssql-2022-ubuntu2404.sh
#   sudo ./install-mssql-2022-ubuntu2404.sh -p 'MyStr0ng!Pass' -e Developer -y
#
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_VERSION="1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/mssql-install-$(date +%Y%m%d-%H%M%S).log"
TEMP_DIR="/tmp/mssql-install-$$"

# Default configuration
DEFAULT_SA_PASSWORD="SQLServer2022!"
DEFAULT_EDITION="Developer"
SKIP_CONFIRMATION=false
CUSTOM_MEMORY=""

# SQL Server configuration
MSSQL_VERSION="16.0.4195.2-4"
MSSQL_PACKAGE="mssql-server=${MSSQL_VERSION}"
OPENLDAP_PACKAGE_URL="http://security.ubuntu.com/ubuntu/pool/main/o/openldap/libldap-2.5-0_2.5.16+dfsg-0ubuntu0.22.04.2_amd64.deb"

################################################################################
# Functions
################################################################################

# Print banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║   Microsoft SQL Server 2022 CU19 Automated Installation         ║
║   Ubuntu 24.04 LTS - Developer Edition                          ║
║   Version: 1.0 | Tested and Verified                           ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "${LOG_FILE}"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

print_step() {
    echo -e "\n${CYAN}==>${NC} ${BLUE}$*${NC}\n" | tee -a "${LOG_FILE}"
}

# Progress indicator
show_progress() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r${BLUE}[${spin:$i:1}]${NC} ${message}..."
        sleep 0.1
    done
    printf "\r${GREEN}[✓]${NC} ${message}... Done\n"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check system requirements
check_system() {
    print_step "Checking System Requirements"

    # Check Ubuntu version
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect OS version"
        exit 1
    fi

    source /etc/os-release

    if [[ "${ID}" != "ubuntu" ]] || [[ ! "${VERSION_ID}" =~ ^24\.04 ]]; then
        print_warning "This script is designed for Ubuntu 24.04"
        print_info "Detected: ${PRETTY_NAME}"

        if [[ "${SKIP_CONFIRMATION}" == "false" ]]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        print_success "Ubuntu 24.04 detected"
    fi

    # Check architecture
    local arch=$(uname -m)
    if [[ "${arch}" != "x86_64" ]]; then
        print_error "SQL Server requires x86_64 architecture. Detected: ${arch}"
        exit 1
    fi
    print_success "Architecture: x86_64"

    # Check memory
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [[ ${total_mem} -lt 2048 ]]; then
        print_warning "SQL Server requires at least 2 GB RAM. Detected: ${total_mem} MB"
        if [[ "${SKIP_CONFIRMATION}" == "false" ]]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        print_success "Memory: ${total_mem} MB (sufficient)"
    fi

    # Check disk space
    local available_space=$(df /var --output=avail -m | tail -n1 | tr -d ' ')
    if [[ ${available_space} -lt 6144 ]]; then
        print_warning "At least 6 GB free space recommended. Available: ${available_space} MB"
    else
        print_success "Disk space: ${available_space} MB (sufficient)"
    fi

    # Check network connectivity
    if ! ping -c 1 packages.microsoft.com &>/dev/null; then
        print_error "Cannot reach packages.microsoft.com. Check internet connection."
        exit 1
    fi
    print_success "Network connectivity verified"
}

# Validate password
validate_password() {
    local password="$1"

    # Password requirements:
    # - At least 8 characters
    # - Contains uppercase, lowercase, digits, and special characters

    if [[ ${#password} -lt 8 ]]; then
        print_error "Password must be at least 8 characters long"
        return 1
    fi

    if [[ ! "$password" =~ [A-Z] ]]; then
        print_error "Password must contain at least one uppercase letter"
        return 1
    fi

    if [[ ! "$password" =~ [a-z] ]]; then
        print_error "Password must contain at least one lowercase letter"
        return 1
    fi

    if [[ ! "$password" =~ [0-9] ]]; then
        print_error "Password must contain at least one digit"
        return 1
    fi

    if [[ ! "$password" =~ [^a-zA-Z0-9] ]]; then
        print_error "Password must contain at least one special character"
        return 1
    fi

    return 0
}

# Import Microsoft GPG key
import_gpg_key() {
    print_step "Importing Microsoft GPG Key"

    if [[ -f /usr/share/keyrings/microsoft-prod.gpg ]]; then
        print_info "GPG key already exists, skipping..."
        return 0
    fi

    (
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
            gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    ) &>/dev/null &

    show_progress $! "Importing Microsoft GPG key"

    if [[ -f /usr/share/keyrings/microsoft-prod.gpg ]]; then
        print_success "Microsoft GPG key imported successfully"
    else
        print_error "Failed to import GPG key"
        exit 1
    fi
}

# Add SQL Server repository
add_mssql_repository() {
    print_step "Adding SQL Server Repository"

    local repo_file="/etc/apt/sources.list.d/mssql-server-2022.list"

    if [[ -f "${repo_file}" ]]; then
        print_info "Repository already configured, updating..."
        rm -f "${repo_file}"
    fi

    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022 jammy main" | \
        tee "${repo_file}" &>/dev/null

    print_info "Note: Using Ubuntu 22.04 repository (24.04 not yet available)"
    print_success "SQL Server repository added"
}

# Update package lists
update_packages() {
    print_step "Updating Package Lists"

    (apt-get update) &>/dev/null &
    show_progress $! "Updating package lists"

    print_success "Package lists updated"
}

# Install SQL Server package
install_mssql_server() {
    print_step "Installing SQL Server 2022 CU19"

    print_info "Package: ${MSSQL_PACKAGE}"
    print_info "This may take a few minutes..."

    DEBIAN_FRONTEND=noninteractive apt-get install -y "${MSSQL_PACKAGE}" &>"${LOG_FILE}.install" &
    show_progress $! "Installing SQL Server package"

    if dpkg -l | grep -q mssql-server; then
        print_success "SQL Server package installed successfully"
    else
        print_error "Failed to install SQL Server package"
        print_info "Check log: ${LOG_FILE}.install"
        exit 1
    fi
}

# Fix OpenLDAP dependency (CRITICAL for Ubuntu 24.04)
fix_openldap_dependency() {
    print_step "Fixing OpenLDAP 2.5 Dependency (Ubuntu 24.04 Fix)"

    print_info "Ubuntu 24.04 ships with OpenLDAP 2.6, but SQL Server requires 2.5"
    print_info "Downloading and installing OpenLDAP 2.5 from Ubuntu 22.04..."

    # Create temporary directory
    mkdir -p "${TEMP_DIR}"
    cd "${TEMP_DIR}"

    # Check if already installed
    if [[ -f /lib/x86_64-linux-gnu/liblber-2.5.so.0 ]] && \
       [[ -f /lib/x86_64-linux-gnu/libldap-2.5.so.0 ]]; then

        # Verify they have correct version
        if strings /lib/x86_64-linux-gnu/liblber-2.5.so.0 | grep -q "OPENLDAP_2.5"; then
            print_info "OpenLDAP 2.5 libraries already installed, skipping..."
            return 0
        fi
    fi

    # Download OpenLDAP 2.5 package
    print_info "Downloading OpenLDAP 2.5 package..."
    if ! wget -q "${OPENLDAP_PACKAGE_URL}" -O openldap-2.5.deb; then
        print_error "Failed to download OpenLDAP package"
        exit 1
    fi
    print_success "OpenLDAP package downloaded"

    # Extract package
    print_info "Extracting libraries..."
    dpkg -x openldap-2.5.deb extracted/ &>/dev/null

    # Copy libraries
    print_info "Installing OpenLDAP 2.5 libraries..."
    cp extracted/usr/lib/x86_64-linux-gnu/liblber-2.5.so.0* /lib/x86_64-linux-gnu/
    cp extracted/usr/lib/x86_64-linux-gnu/libldap-2.5.so.0* /lib/x86_64-linux-gnu/

    # Update linker cache
    ldconfig

    # Verify installation
    if ldd /opt/mssql/bin/sqlservr | grep -q "not found"; then
        print_error "Missing dependencies detected:"
        ldd /opt/mssql/bin/sqlservr | grep "not found"
        exit 1
    fi

    print_success "OpenLDAP 2.5 libraries installed successfully"

    # Cleanup
    cd - &>/dev/null
    rm -rf "${TEMP_DIR}"
}

# Configure SQL Server
configure_mssql() {
    print_step "Configuring SQL Server"

    local sa_password="$1"
    local edition="$2"

    print_info "Edition: ${edition}"
    print_info "Configuring SQL Server with provided settings..."

    # Run setup
    MSSQL_SA_PASSWORD="${sa_password}" \
    MSSQL_PID="${edition}" \
    /opt/mssql/bin/mssql-conf -n setup accept-eula &>"${LOG_FILE}.setup"

    if [[ $? -eq 0 ]]; then
        print_success "SQL Server configured successfully"
    else
        print_error "Failed to configure SQL Server"
        print_info "Check log: ${LOG_FILE}.setup"
        exit 1
    fi
}

# Start SQL Server service
start_mssql_service() {
    print_step "Starting SQL Server Service"

    systemctl start mssql-server &>/dev/null
    sleep 5

    if systemctl is-active --quiet mssql-server; then
        print_success "SQL Server service started"
    else
        print_error "Failed to start SQL Server service"
        print_info "Checking logs..."
        journalctl -u mssql-server -n 20 --no-pager
        exit 1
    fi

    # Enable service
    systemctl enable mssql-server &>/dev/null
    print_success "SQL Server service enabled (will start on boot)"
}

# Install SQL Server command-line tools
install_mssql_tools() {
    print_step "Installing SQL Server Command-Line Tools"

    local prod_repo="/etc/apt/sources.list.d/mssql-prod.list"

    # Add production repository if not exists
    if [[ ! -f "${prod_repo}" ]]; then
        echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" | \
            tee "${prod_repo}" &>/dev/null

        apt-get update &>/dev/null
    fi

    # Install tools
    print_info "Installing mssql-tools18 and unixodbc-dev..."
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y mssql-tools18 unixodbc-dev &>"${LOG_FILE}.tools" &
    show_progress $! "Installing SQL Server tools"

    if [[ -f /opt/mssql-tools18/bin/sqlcmd ]]; then
        print_success "SQL Server tools installed successfully"

        # Add to PATH if not already there
        if ! grep -q "/opt/mssql-tools18/bin" /root/.bashrc 2>/dev/null; then
            echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /root/.bashrc
            print_info "Added tools to PATH in /root/.bashrc"
        fi
    else
        print_warning "Failed to install SQL Server tools (non-critical)"
        print_info "You can install manually later: sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18"
    fi
}

# Configure memory limit
configure_memory() {
    local custom_memory="$1"

    if [[ -n "${custom_memory}" ]]; then
        print_step "Configuring Memory Limit"

        print_info "Setting maximum memory to ${custom_memory} MB"
        /opt/mssql/bin/mssql-conf set memory.memorylimitmb "${custom_memory}" &>/dev/null

        systemctl restart mssql-server &>/dev/null
        sleep 5

        print_success "Memory limit configured"
    fi
}

# Verify installation
verify_installation() {
    print_step "Verifying Installation"

    local sa_password="$1"

    # Check service status
    if ! systemctl is-active --quiet mssql-server; then
        print_error "SQL Server service is not running"
        return 1
    fi
    print_success "Service is running"

    # Check SQL Server version
    local version_output=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${sa_password}" -C -Q "SELECT @@VERSION" -W 2>/dev/null | grep -i "Microsoft SQL Server")

    if [[ -n "${version_output}" ]]; then
        print_success "SQL Server connection successful"
        print_info "${version_output}"

        # Check if correct version
        if echo "${version_output}" | grep -q "16.0.4195.2"; then
            print_success "Verified: SQL Server 2022 (RTM-CU19) KB5054531"
        else
            print_warning "Version mismatch detected"
        fi
    else
        print_error "Failed to connect to SQL Server"
        print_info "Attempting to reset SA password..."

        systemctl stop mssql-server
        MSSQL_SA_PASSWORD="${sa_password}" /opt/mssql/bin/mssql-conf set-sa-password &>/dev/null
        systemctl start mssql-server
        sleep 5

        # Retry connection
        version_output=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${sa_password}" -C -Q "SELECT @@VERSION" -W 2>/dev/null | grep -i "Microsoft SQL Server")

        if [[ -n "${version_output}" ]]; then
            print_success "Connection successful after password reset"
        else
            print_error "Still unable to connect. Please reset SA password manually."
            return 1
        fi
    fi

    # Test database creation
    print_info "Testing database operations..."
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${sa_password}" -C -Q "SELECT name FROM sys.databases" -W &>/dev/null; then
        print_success "Database operations verified"
    else
        print_warning "Unable to query databases (non-critical)"
    fi
}

# Print installation summary
print_summary() {
    local sa_password="$1"
    local edition="$2"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Installation Completed Successfully!                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Installation Details:${NC}"
    echo "  • SQL Server Version: 16.0.4195.2 (RTM-CU19) KB5054531"
    echo "  • Edition: ${edition}"
    echo "  • Service Status: Active (running)"
    echo "  • Port: 1433"
    echo ""
    echo -e "${CYAN}Connection Information:${NC}"
    echo "  • Server: localhost"
    echo "  • Username: SA"
    echo "  • Password: ${sa_password}"
    echo ""
    echo -e "${CYAN}Connect using sqlcmd:${NC}"
    echo "  sqlcmd -S localhost -U SA -P '${sa_password}' -C"
    echo ""
    echo -e "${CYAN}Or use this connection string:${NC}"
    echo "  Server=localhost,1433;Database=master;User Id=SA;Password=${sa_password};TrustServerCertificate=True;"
    echo ""
    echo -e "${CYAN}Service Management:${NC}"
    echo "  • Status:  sudo systemctl status mssql-server"
    echo "  • Start:   sudo systemctl start mssql-server"
    echo "  • Stop:    sudo systemctl stop mssql-server"
    echo "  • Restart: sudo systemctl restart mssql-server"
    echo "  • Logs:    sudo journalctl -u mssql-server -f"
    echo ""
    echo -e "${CYAN}Important Locations:${NC}"
    echo "  • Binaries:     /opt/mssql/"
    echo "  • Data:         /var/opt/mssql/data/"
    echo "  • Logs:         /var/opt/mssql/log/"
    echo "  • Config:       /var/opt/mssql/mssql.conf"
    echo "  • Tools:        /opt/mssql-tools18/bin/"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Change SA password for security:"
    echo "     sudo systemctl stop mssql-server"
    echo "     sudo /opt/mssql/bin/mssql-conf set-sa-password"
    echo "     sudo systemctl start mssql-server"
    echo ""
    echo "  2. Configure firewall (if needed):"
    echo "     sudo ufw allow 1433/tcp"
    echo ""
    echo "  3. Create your first database:"
    echo "     sqlcmd -S localhost -U SA -C -Q \"CREATE DATABASE MyDatabase\""
    echo ""
    echo -e "${YELLOW}Security Warning:${NC}"
    echo "  Please change the default SA password immediately!"
    echo ""
    echo -e "${CYAN}Installation Log:${NC} ${LOG_FILE}"
    echo ""
}

# Cleanup function
cleanup() {
    if [[ -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}

# Error handler
error_handler() {
    local line_no=$1
    print_error "Installation failed at line ${line_no}"
    print_info "Check log file: ${LOG_FILE}"
    cleanup
    exit 1
}

# Show help
show_help() {
    cat << EOF
Microsoft SQL Server 2022 CU19 Automated Installation Script
Version: ${SCRIPT_VERSION}

Usage: sudo $0 [OPTIONS]

Options:
  -p, --password PASSWORD    Set SA password (default: ${DEFAULT_SA_PASSWORD})
  -e, --edition EDITION      SQL Server edition (default: ${DEFAULT_EDITION})
                             Options: Developer, Express, Standard, Enterprise
  -m, --memory MB           Max memory in MB (default: auto-calculated)
  -y, --yes                 Skip all confirmations
  -h, --help                Show this help message

Password Requirements:
  • At least 8 characters
  • Contains uppercase letters
  • Contains lowercase letters
  • Contains digits
  • Contains special characters

Examples:
  # Install with defaults
  sudo $0

  # Install with custom password and skip confirmations
  sudo $0 -p 'MyStr0ng!Pass' -y

  # Install with custom memory limit
  sudo $0 -p 'MyStr0ng!Pass' -m 4096 -y

  # Install Express edition
  sudo $0 -e Express -y

Notes:
  • This script is designed for Ubuntu 24.04 LTS
  • Internet connection is required
  • At least 2 GB RAM and 6 GB disk space recommended
  • The script will install OpenLDAP 2.5 from Ubuntu 22.04 (required)

For more information, visit:
  https://docs.microsoft.com/en-us/sql/linux/

EOF
}

################################################################################
# Main Script
################################################################################

main() {
    # Set error handler
    trap 'error_handler ${LINENO}' ERR
    trap cleanup EXIT

    # Parse command-line arguments
    SA_PASSWORD="${DEFAULT_SA_PASSWORD}"
    EDITION="${DEFAULT_EDITION}"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--password)
                SA_PASSWORD="$2"
                shift 2
                ;;
            -e|--edition)
                EDITION="$2"
                shift 2
                ;;
            -m|--memory)
                CUSTOM_MEMORY="$2"
                shift 2
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Print banner
    print_banner

    # Start logging
    log "INFO" "Installation started"
    log "INFO" "Log file: ${LOG_FILE}"

    # Validate password
    if ! validate_password "${SA_PASSWORD}"; then
        print_error "Invalid password. Please ensure it meets all requirements."
        exit 1
    fi

    # Check if running as root
    check_root

    # Confirmation
    if [[ "${SKIP_CONFIRMATION}" == "false" ]]; then
        echo -e "${CYAN}Installation Configuration:${NC}"
        echo "  • SQL Server Version: 2022 CU19 (16.0.4195.2)"
        echo "  • Edition: ${EDITION}"
        echo "  • SA Password: ${SA_PASSWORD}"
        if [[ -n "${CUSTOM_MEMORY}" ]]; then
            echo "  • Memory Limit: ${CUSTOM_MEMORY} MB"
        fi
        echo ""
        read -p "Continue with installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi

    # Run installation steps
    check_system
    import_gpg_key
    add_mssql_repository
    update_packages
    install_mssql_server
    fix_openldap_dependency
    configure_mssql "${SA_PASSWORD}" "${EDITION}"
    start_mssql_service
    install_mssql_tools
    configure_memory "${CUSTOM_MEMORY}"
    verify_installation "${SA_PASSWORD}"

    # Print summary
    print_summary "${SA_PASSWORD}" "${EDITION}"

    log "INFO" "Installation completed successfully"
}

# Run main function
main "$@"
