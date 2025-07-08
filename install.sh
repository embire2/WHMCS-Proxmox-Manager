#!/bin/bash

#==============================================================================
# WHMCS Proxmox VM Management Plugin - Automated Installer
# Version: 1.0.2
# GitHub: https://github.com/embire2/WHMCS-Proxmox-Manager
# Description: One-click installation script with auto-detection and self-healing
#==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/embire2/WHMCS-Proxmox-Manager.git"
MODULE_NAME="proxmoxvm"
REQUIRED_PHP_VERSION="7.4"
WHMCS_MIN_VERSION="8.0"

# Global variables
WHMCS_PATH=""
WEB_USER=""
MYSQL_USER=""
MYSQL_PASS=""
MYSQL_DB=""
INSTALL_LOG="/tmp/proxmoxvm_install.log"

#==============================================================================
# Utility Functions
#==============================================================================

print_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    WHMCS Proxmox VM Management Plugin                       ║${NC}"
    echo -e "${PURPLE}║                           Automated Installer v1.0.2                       ║${NC}"
    echo -e "${PURPLE}║                                                                              ║${NC}"
    echo -e "${PURPLE}║  This script will automatically:                                            ║${NC}"
    echo -e "${PURPLE}║  • Detect your WHMCS installation path                                      ║${NC}"
    echo -e "${PURPLE}║  • Download and install the plugin from GitHub                              ║${NC}"
    echo -e "${PURPLE}║  • Set up required databases and permissions                                ║${NC}"
    echo -e "${PURPLE}║  • Configure everything for immediate use                                   ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$INSTALL_LOG"
    echo -e "$1"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

error() {
    log "${RED}✗ ERROR: $1${NC}"
}

warning() {
    log "${YELLOW}⚠ WARNING: $1${NC}"
}

info() {
    log "${BLUE}ℹ INFO: $1${NC}"
}

progress() {
    log "${CYAN}→ $1${NC}"
}

#==============================================================================
# System Checks
#==============================================================================

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons."
        echo -e "${YELLOW}Please run as a regular user with sudo privileges.${NC}"
        exit 1
    fi
}

check_dependencies() {
    progress "Checking system dependencies..."
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in git curl php mysql unzip wget; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        progress "Installing missing dependencies..."
        
        # Auto-install based on distribution
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y "${missing_deps[@]}" 2>/dev/null || {
                error "Failed to install dependencies. Please install manually: ${missing_deps[*]}"
                exit 1
            }
        elif command -v yum &> /dev/null; then
            sudo yum install -y "${missing_deps[@]}" 2>/dev/null || {
                error "Failed to install dependencies. Please install manually: ${missing_deps[*]}"
                exit 1
            }
        else
            error "Unsupported package manager. Please install manually: ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    success "All dependencies are available"
}

check_php_version() {
    progress "Checking PHP version..."
    
    local php_version=$(php -r "echo PHP_VERSION;" 2>/dev/null || echo "0.0.0")
    local required_version="$REQUIRED_PHP_VERSION"
    
    if ! php -r "exit(version_compare(PHP_VERSION, '$required_version', '>=') ? 0 : 1);" 2>/dev/null; then
        error "PHP version $required_version or higher is required. Found: $php_version"
        progress "Attempting to install PHP $required_version..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y "php$required_version" "php$required_version-mysql" "php$required_version-curl" "php$required_version-json" 2>/dev/null || {
                error "Failed to install PHP $required_version. Please install manually."
                exit 1
            }
        else
            error "Please install PHP $required_version or higher manually."
            exit 1
        fi
    fi
    
    success "PHP version check passed: $php_version"
}

#==============================================================================
# WHMCS Detection
#==============================================================================

detect_whmcs_path() {
    progress "Auto-detecting WHMCS installation path..."
    
    local possible_paths=(
        "/var/www/html"
        "/var/www/html/whmcs"
        "/var/www/whmcs"
        "/home/*/public_html"
        "/home/*/public_html/whmcs"
        "/var/www/vhosts/*/httpdocs"
        "/var/www/vhosts/*/httpdocs/whmcs"
        "/usr/local/apache2/htdocs"
        "/usr/local/apache2/htdocs/whmcs"
        "/opt/lampp/htdocs"
        "/opt/lampp/htdocs/whmcs"
    )
    
    # Expand wildcards and check each path
    for pattern in "${possible_paths[@]}"; do
        for path in $pattern; do
            if [[ -f "$path/configuration.php" && -d "$path/modules/servers" ]]; then
                # Verify it's actually WHMCS by checking for specific files
                if [[ -f "$path/init.php" && -f "$path/vendor/whmcs/whmcs/lib/init.php" ]] || [[ -f "$path/includes/functions.php" ]]; then
                    WHMCS_PATH="$path"
                    success "WHMCS installation detected at: $WHMCS_PATH"
                    return 0
                fi
            fi
        done
    done
    
    # If auto-detection fails, ask user
    warning "Could not auto-detect WHMCS installation path."
    echo -e "${YELLOW}Please enter your WHMCS installation path:${NC}"
    read -p "WHMCS Path: " -r user_path
    
    if [[ -f "$user_path/configuration.php" && -d "$user_path/modules/servers" ]]; then
        WHMCS_PATH="$user_path"
        success "WHMCS path confirmed: $WHMCS_PATH"
    else
        error "Invalid WHMCS path. Please ensure WHMCS is properly installed."
        exit 1
    fi
}

detect_web_user() {
    progress "Detecting web server user..."
    
    # Common web server users
    local web_users=("www-data" "apache" "nginx" "httpd" "nobody")
    
    for user in "${web_users[@]}"; do
        if id "$user" &>/dev/null; then
            WEB_USER="$user"
            success "Web server user detected: $WEB_USER"
            return 0
        fi
    done
    
    # Fallback: check process ownership
    local web_process=$(ps aux | grep -E "(apache|nginx|httpd)" | grep -v grep | head -1 | awk '{print $1}')
    if [[ -n "$web_process" ]]; then
        WEB_USER="$web_process"
        success "Web server user detected from process: $WEB_USER"
        return 0
    fi
    
    warning "Could not detect web server user. Using current user: $(whoami)"
    WEB_USER=$(whoami)
}

#==============================================================================
# Database Configuration
#==============================================================================

get_database_config() {
    progress "Extracting database configuration from WHMCS..."
    
    local config_file="$WHMCS_PATH/configuration.php"
    
    if [[ ! -f "$config_file" ]]; then
        error "WHMCS configuration file not found: $config_file"
        exit 1
    fi
    
    # Extract database credentials from configuration.php
    MYSQL_USER=$(grep -oP "(?<=db_username = \")[^\"]*" "$config_file" 2>/dev/null || echo "")
    MYSQL_PASS=$(grep -oP "(?<=db_password = \")[^\"]*" "$config_file" 2>/dev/null || echo "")
    MYSQL_DB=$(grep -oP "(?<=db_name = \")[^\"]*" "$config_file" 2>/dev/null || echo "")
    
    if [[ -z "$MYSQL_USER" || -z "$MYSQL_DB" ]]; then
        error "Could not extract database configuration from WHMCS config file."
        echo -e "${YELLOW}Please enter your MySQL credentials:${NC}"
        read -p "MySQL Username: " -r MYSQL_USER
        read -s -p "MySQL Password: " MYSQL_PASS
        echo ""
        read -p "MySQL Database: " -r MYSQL_DB
    fi
    
    success "Database configuration extracted successfully"
}

test_database_connection() {
    progress "Testing database connection..."
    
    if mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "SELECT 1;" &>/dev/null; then
        success "Database connection successful"
    else
        error "Database connection failed. Please check your credentials."
        
        # Self-healing: try to fix common issues
        progress "Attempting to diagnose and fix database issues..."
        
        # Check if MySQL service is running
        if ! systemctl is-active --quiet mysql && ! systemctl is-active --quiet mariadb; then
            progress "Starting MySQL/MariaDB service..."
            sudo systemctl start mysql 2>/dev/null || sudo systemctl start mariadb 2>/dev/null || {
                error "Could not start MySQL/MariaDB service."
                exit 1
            }
        fi
        
        # Retry connection
        if mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "SELECT 1;" &>/dev/null; then
            success "Database connection restored"
        else
            error "Database connection still failing. Please check your WHMCS configuration."
            exit 1
        fi
    fi
}

#==============================================================================
# Plugin Installation
#==============================================================================

download_plugin() {
    progress "Downloading plugin from GitHub..."
    
    local temp_dir="/tmp/proxmoxvm_install_$$"
    local target_dir="$WHMCS_PATH/modules/servers/$MODULE_NAME"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Clone repository
    if git clone "$REPO_URL" . &>/dev/null; then
        success "Plugin downloaded successfully"
    else
        error "Failed to download plugin from GitHub"
        
        # Fallback: try wget
        progress "Trying alternative download method..."
        if wget -q -O main.zip "https://github.com/embire2/WHMCS-Proxmox-Manager/archive/refs/heads/main.zip"; then
            unzip -q main.zip
            mv WHMCS-Proxmox-Manager-main/* .
            rm -rf WHMCS-Proxmox-Manager-main main.zip
            success "Plugin downloaded via fallback method"
        else
            error "All download methods failed. Please check your internet connection."
            exit 1
        fi
    fi
    
    # Remove existing installation if present
    if [[ -d "$target_dir" ]]; then
        warning "Existing installation found. Creating backup..."
        sudo mv "$target_dir" "${target_dir}.backup.$(date +%s)"
    fi
    
    # Create target directory
    sudo mkdir -p "$target_dir"
    
    # Copy files
    sudo cp -r modules/servers/proxmoxvm/* "$target_dir/"
    
    success "Plugin files installed to: $target_dir"
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

set_permissions() {
    progress "Setting proper file permissions..."
    
    local target_dir="$WHMCS_PATH/modules/servers/$MODULE_NAME"
    
    # Set ownership
    sudo chown -R "$WEB_USER:$WEB_USER" "$target_dir"
    
    # Set permissions
    sudo find "$target_dir" -type d -exec chmod 755 {} \;
    sudo find "$target_dir" -type f -name "*.php" -exec chmod 644 {} \;
    sudo find "$target_dir" -type f -name "*.tpl" -exec chmod 644 {} \;
    sudo find "$target_dir" -type f -name "*.md" -exec chmod 644 {} \;
    
    success "File permissions set correctly"
}

setup_database() {
    progress "Setting up database tables..."
    
    local sql_script="/tmp/proxmoxvm_setup.sql"
    
    # Create SQL script for database setup
    cat > "$sql_script" << 'EOF'
CREATE TABLE IF NOT EXISTS `mod_proxmoxvm` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `vmid` int(11) NOT NULL,
  `node` varchar(255) NOT NULL,
  `password` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_id` (`service_id`),
  KEY `idx_service_id` (`service_id`),
  KEY `idx_vmid` (`vmid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
    
    # Execute SQL script
    if mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" < "$sql_script" &>/dev/null; then
        success "Database tables created successfully"
    else
        error "Failed to create database tables"
        
        # Self-healing: check if table already exists
        if mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "DESCRIBE mod_proxmoxvm;" &>/dev/null; then
            warning "Database table already exists - skipping creation"
        else
            error "Database setup failed. Please check MySQL permissions."
            exit 1
        fi
    fi
    
    # Cleanup
    rm -f "$sql_script"
}

#==============================================================================
# Verification and Testing
#==============================================================================

verify_installation() {
    progress "Verifying installation..."
    
    local target_dir="$WHMCS_PATH/modules/servers/$MODULE_NAME"
    local required_files=("proxmoxvm.php" "hooks.php")
    
    # Check required files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$target_dir/$file" ]]; then
            error "Required file missing: $file"
            return 1
        fi
    done
    
    # Check PHP syntax
    for php_file in "$target_dir"/*.php; do
        if ! php -l "$php_file" &>/dev/null; then
            error "PHP syntax error in: $(basename "$php_file")"
            return 1
        fi
    done
    
    # Check database table
    if ! mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "DESCRIBE mod_proxmoxvm;" &>/dev/null; then
        error "Database table verification failed"
        return 1
    fi
    
    # Check file permissions
    local owner=$(stat -c '%U' "$target_dir/proxmoxvm.php" 2>/dev/null || echo "unknown")
    if [[ "$owner" != "$WEB_USER" ]]; then
        warning "File ownership may be incorrect. Expected: $WEB_USER, Found: $owner"
    fi
    
    success "Installation verification completed successfully"
    return 0
}

create_activation_guide() {
    local guide_file="$WHMCS_PATH/modules/servers/$MODULE_NAME/ACTIVATION_GUIDE.txt"
    
    cat > "$guide_file" << EOF
WHMCS Proxmox VM Management Plugin - Activation Guide
====================================================

Installation completed successfully! Follow these steps to activate:

1. CREATE PROXMOX API USER
   SSH to your Proxmox server and run:
   
   pveum user add whmcs@pve --password "YourSecurePassword123!"
   pveum role add WHMCS -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt VM.Audit Datastore.AllocateSpace Datastore.Audit Sys.Audit"
   pveum aclmod / -user whmcs@pve -role WHMCS

2. CONFIGURE WHMCS SERVER
   - Go to: Setup → Products/Services → Servers
   - Click: Add New Server
   - Type: Proxmox VM Management
   - Enter your Proxmox server details

3. CREATE VM PRODUCT
   - Go to: Setup → Products/Services → Products/Services
   - Create new Server/VPS product
   - Module: Proxmox VM Management
   - Configure resource limits

Installation Details:
- WHMCS Path: $WHMCS_PATH
- Module Path: $WHMCS_PATH/modules/servers/$MODULE_NAME
- Database Table: mod_proxmoxvm
- Web User: $WEB_USER

For support: https://github.com/embire2/WHMCS-Proxmox-Manager/issues
EOF
    
    success "Activation guide created: $guide_file"
}

#==============================================================================
# Self-Healing Functions
#==============================================================================

self_heal() {
    progress "Running self-healing diagnostics..."
    
    local issues_found=0
    
    # Check file permissions
    local target_dir="$WHMCS_PATH/modules/servers/$MODULE_NAME"
    if [[ -d "$target_dir" ]]; then
        local perms=$(stat -c '%a' "$target_dir" 2>/dev/null || echo "000")
        if [[ "$perms" != "755" ]]; then
            warning "Fixing directory permissions..."
            sudo chmod 755 "$target_dir"
            ((issues_found++))
        fi
        
        # Fix file permissions
        find "$target_dir" -name "*.php" -not -perm 644 -exec sudo chmod 644 {} \; 2>/dev/null && ((issues_found++))
    fi
    
    # Check ownership
    if [[ -f "$target_dir/proxmoxvm.php" ]]; then
        local owner=$(stat -c '%U' "$target_dir/proxmoxvm.php" 2>/dev/null || echo "unknown")
        if [[ "$owner" != "$WEB_USER" ]]; then
            warning "Fixing file ownership..."
            sudo chown -R "$WEB_USER:$WEB_USER" "$target_dir"
            ((issues_found++))
        fi
    fi
    
    # Check database connection
    if ! mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "SELECT 1;" &>/dev/null; then
        warning "Database connection issue detected. Attempting to restart MySQL..."
        sudo systemctl restart mysql 2>/dev/null || sudo systemctl restart mariadb 2>/dev/null
        ((issues_found++))
    fi
    
    if [[ $issues_found -eq 0 ]]; then
        success "No issues found during self-healing check"
    else
        success "Fixed $issues_found issues during self-healing"
    fi
}

#==============================================================================
# Main Installation Process
#==============================================================================

main() {
    print_header
    
    # Initialize log
    echo "WHMCS Proxmox VM Plugin Installation Log" > "$INSTALL_LOG"
    echo "Started: $(date)" >> "$INSTALL_LOG"
    echo "=========================================" >> "$INSTALL_LOG"
    
    info "Starting automated installation process..."
    
    # Pre-installation checks
    check_root
    check_dependencies
    check_php_version
    
    # Detection phase
    detect_whmcs_path
    detect_web_user
    get_database_config
    test_database_connection
    
    # Installation phase
    download_plugin
    set_permissions
    setup_database
    
    # Verification phase
    if verify_installation; then
        success "Installation completed successfully!"
    else
        error "Installation verification failed. Running self-healing..."
        self_heal
        
        if verify_installation; then
            success "Installation fixed and verified!"
        else
            error "Installation failed. Please check the log: $INSTALL_LOG"
            exit 1
        fi
    fi
    
    # Post-installation
    create_activation_guide
    
    # Final summary
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                          INSTALLATION SUCCESSFUL!                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Installation Summary:${NC}"
    echo -e "  • WHMCS Path: ${YELLOW}$WHMCS_PATH${NC}"
    echo -e "  • Module Path: ${YELLOW}$WHMCS_PATH/modules/servers/$MODULE_NAME${NC}"
    echo -e "  • Database Table: ${YELLOW}mod_proxmoxvm${NC}"
    echo -e "  • Web User: ${YELLOW}$WEB_USER${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  1. Check activation guide: ${YELLOW}$WHMCS_PATH/modules/servers/$MODULE_NAME/ACTIVATION_GUIDE.txt${NC}"
    echo -e "  2. Create Proxmox API user on your Proxmox server"
    echo -e "  3. Configure server in WHMCS Admin: Setup → Products/Services → Servers"
    echo -e "  4. Create VM products: Setup → Products/Services → Products/Services"
    echo ""
    echo -e "${CYAN}Support:${NC}"
    echo -e "  • Documentation: ${YELLOW}https://github.com/embire2/WHMCS-Proxmox-Manager${NC}"
    echo -e "  • Issues: ${YELLOW}https://github.com/embire2/WHMCS-Proxmox-Manager/issues${NC}"
    echo -e "  • Installation Log: ${YELLOW}$INSTALL_LOG${NC}"
    echo ""
    
    success "Installation completed in $(date)"
}

# Handle script interruption
trap 'error "Installation interrupted by user"; exit 1' INT TERM

# Run main installation
main "$@"
