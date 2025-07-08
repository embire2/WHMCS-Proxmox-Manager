# WHMCS Proxmox VM Management Plugin

A comprehensive WHMCS module that enables full integration with Proxmox VE clusters, allowing administrators to manage Proxmox API connections and customers to control their virtual machines.

**Version:** 1.0.2  
**GitHub:** https://github.com/embire2/WHMCS-Proxmox-Manager  
**Requirements:** WHMCS 8.0+, PHP 7.4+, Proxmox VE 6.0+

## 🚀 Quick Installation (Recommended)

### **One-Command Installation**

Simply run this command on your server to automatically install everything:

```bash
curl -sSL https://raw.githubusercontent.com/embire2/WHMCS-Proxmox-Manager/main/install.sh | bash
```

**Or download and run manually:**

```bash
wget https://raw.githubusercontent.com/embire2/WHMCS-Proxmox-Manager/main/install.sh
chmod +x install.sh
./install.sh
```

### **What the installer does automatically:**

✅ **Auto-detects your WHMCS installation path**  
✅ **Downloads plugin from GitHub**  
✅ **Sets up database tables**  
✅ **Configures file permissions**  
✅ **Verifies installation**  
✅ **Creates activation guide**  
✅ **Self-healing troubleshooting**  

The installer will:
- Find your WHMCS installation automatically
- Download the latest version from GitHub
- Set up all required database tables
- Configure proper file permissions
- Test everything works correctly
- Provide you with next steps

---

## 🔧 Manual Installation (Advanced Users)

<details>
<summary>Click here for manual installation instructions</summary>

### Step 1: Download and Install the Plugin

**Method 1: Using Git (Recommended)**

1. **Navigate to your WHMCS modules directory:**
   ```bash
   cd /path/to/your/whmcs/modules/servers/
   ```
   
   **Common WHMCS paths:**
   - cPanel: `cd /home/username/public_html/modules/servers/`
   - Plesk: `cd /var/www/vhosts/yourdomain.com/httpdocs/modules/servers/`
   - Standard: `cd /var/www/html/modules/servers/`
   - Custom: `cd /var/www/whmcs/modules/servers/`

2. **Clone the repository:**
   ```bash
   git clone https://github.com/embire2/WHMCS-Proxmox-Manager.git proxmoxvm
   ```

3. **Set proper file permissions:**
   ```bash
   chmod -R 755 proxmoxvm/
   chmod 644 proxmoxvm/*.php
   chmod 644 proxmoxvm/templates/*.tpl
   ```

**Method 2: Manual Download**

1. **Download the latest release:**
   ```bash
   cd /tmp
   wget https://github.com/embire2/WHMCS-Proxmox-Manager/archive/refs/heads/main.zip
   ```

2. **Extract and move to WHMCS:**
   ```bash
   unzip main.zip
   mv WHMCS-Proxmox-Manager-main /path/to/your/whmcs/modules/servers/proxmoxvm
   ```

3. **Set permissions:**
   ```bash
   cd /path/to/your/whmcs/modules/servers/
   chmod -R 755 proxmoxvm/
   chmod 644 proxmoxvm/*.php
   chmod 644 proxmoxvm/templates/*.tpl
   ```

### Step 2: Set Ownership

```bash
# For Apache (www-data)
sudo chown -R www-data:www-data /path/to/your/whmcs/modules/servers/proxmoxvm

# For Nginx (nginx)
sudo chown -R nginx:nginx /path/to/your/whmcs/modules/servers/proxmoxvm

# For cPanel (username)
sudo chown -R username:username /home/username/public_html/modules/servers/proxmoxvm
```

</details>

---

## 🔧 WHMCS Activation Guide

After installation (automatic or manual), follow these steps to activate the plugin:

### Step 1: Create Proxmox API User

SSH into your Proxmox server and run these commands:

```bash
# Create WHMCS user
pveum user add whmcs@pve --password "YourSecurePassword123!"

# Create role with required permissions
pveum role add WHMCS -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt VM.Audit Datastore.AllocateSpace Datastore.Audit Sys.Audit"

# Assign role to user
pveum aclmod / -user whmcs@pve -role WHMCS

# Verify user creation
pveum user list
```

### Step 2: Configure WHMCS Server

1. **Access WHMCS Admin Area:** `https://yourdomain.com/admin/`
2. **Navigate to:** `Setup` → `Products/Services` → `Servers`
3. **Click:** `Add New Server`
4. **Configure:**

   | Field | Value | Example |
   |-------|-------|---------|
   | **Name** | Friendly server name | `Proxmox Server 1` |
   | **Hostname** | Proxmox server IP/domain | `192.168.1.100` |
   | **Username** | API username (without @pve) | `whmcs` |
   | **Password** | API user password | `YourSecurePassword123!` |
   | **Type** | Select from dropdown | `Proxmox VM Management` |
   | **Secure** | ✅ Enable SSL | `Checked` |
   | **Port** | Proxmox web port | `8006` |

5. **Test Connection** and **Save Changes**

### Step 3: Create VM Product

1. **Navigate to:** `Setup` → `Products/Services` → `Products/Services`
2. **Click:** `Create a New Product`
3. **Configure:**
   - **Product Type:** `Server/VPS`
   - **Product Name:** `Linux VPS - Small`
   - **Module Name:** `Proxmox VM Management`
   - **Configure resource limits** (CPU, RAM, Disk, etc.)

4. **Set pricing** and **Save Changes**

---

## 📋 Features

### Administrator Features
- ✅ Configure multiple Proxmox servers/clusters
- ✅ Set up API authentication details
- ✅ Link customer accounts to specific nodes and VMs
- ✅ Configure VM templates and resource limits
- ✅ Monitor VM status and resource usage
- ✅ Perform administrative actions (start, stop, restart, terminate)

### Customer Features
- ✅ View VM details and current status
- ✅ Start, stop, and restart VMs
- ✅ Access VM console via web interface
- ✅ View assigned resources (CPU, RAM, disk, IP)
- ✅ Secure password management

---

## 🔍 Troubleshooting

### If Installation Fails

The automated installer includes self-healing capabilities, but if you encounter issues:

1. **Check the installation log:**
   ```bash
   cat /tmp/proxmoxvm_install.log
   ```

2. **Run the installer again** (it's safe to re-run):
   ```bash
   curl -sSL https://raw.githubusercontent.com/embire2/WHMCS-Proxmox-Manager/main/install.sh | bash
   ```

3. **Manual verification:**
   ```bash
   # Check if module files exist
   ls -la /path/to/your/whmcs/modules/servers/proxmoxvm/
   
   # Check database table
   mysql -u whmcs_user -p whmcs_database -e "DESCRIBE mod_proxmoxvm;"
   
   # Check file permissions
   ls -la /path/to/your/whmcs/modules/servers/proxmoxvm/proxmoxvm.php
   ```

### Common Issues

**Module not appearing in WHMCS:**
```bash
# Fix permissions
sudo chown -R www-data:www-data /path/to/your/whmcs/modules/servers/proxmoxvm/
sudo chmod -R 755 /path/to/your/whmcs/modules/servers/proxmoxvm/
```

**Database connection issues:**
```bash
# Restart MySQL
sudo systemctl restart mysql
# or
sudo systemctl restart mariadb
```

---

## 🔄 Updating the Plugin

### Using the Installer (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/embire2/WHMCS-Proxmox-Manager/main/install.sh | bash
```

### Manual Update
```bash
cd /path/to/your/whmcs/modules/servers/proxmoxvm
git pull origin main
chmod -R 755 .
chmod 644 *.php templates/*.tpl
```

---

## 🆘 Getting Help

### Support Resources

1. **Documentation:** This README file
2. **GitHub Issues:** https://github.com/embire2/WHMCS-Proxmox-Manager/issues
3. **Installation Guide:** Check `ACTIVATION_GUIDE.txt` in your module directory

### Before Requesting Support

Please provide:
- Installation log: `/tmp/proxmoxvm_install.log`
- WHMCS version and PHP version
- Error messages from WHMCS Module Log
- Output of: `ls -la /path/to/your/whmcs/modules/servers/proxmoxvm/`

---

## 📄 License

This module is released under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📝 Changelog

### Version 1.0.2 (2025-01-02)
- ✅ **Added automated installation script with auto-detection**
- ✅ **Self-healing troubleshooting capabilities**
- ✅ **One-command installation process**
- ✅ **Automatic WHMCS path detection**
- ✅ **Database setup automation**
- ✅ **Comprehensive error handling and recovery**

### Version 1.0.1 (2025-01-01)
- Fixed database table creation issue
- Improved API error handling
- Added connection test functionality

### Version 1.0.0 (2025-01-01)
- Initial release
- Full VM lifecycle management
- Web-based console access
- Customer self-service portal

---

**Made with ❤️ for the WHMCS community**

**Quick Install Command:**
```bash
curl -sSL https://raw.githubusercontent.com/embire2/WHMCS-Proxmox-Manager/main/install.sh | bash
```
