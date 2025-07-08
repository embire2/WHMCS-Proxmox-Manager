# WHMCS Proxmox VM Management Plugin

A comprehensive WHMCS module that enables full integration with Proxmox VE clusters, allowing administrators to manage Proxmox API connections and customers to control their virtual machines.

**Version:** 1.0.2  
**GitHub:** https://github.com/embire2/WHMCS-Proxmox-Manager  
**Requirements:** WHMCS 8.0+, PHP 7.4+, Proxmox VE 6.0+

## 🚀 Installation Guide

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

4. **Verify installation:**
   ```bash
   ls -la proxmoxvm/
   ```
   
   You should see:
   ```
   drwxr-xr-x  3 www-data www-data  4096 Jan  2 12:00 .
   drwxr-xr-x 15 www-data www-data  4096 Jan  2 12:00 ..
   -rw-r--r--  1 www-data www-data  1234 Jan  2 12:00 CHANGELOG.md
   -rw-r--r--  1 www-data www-data  1067 Jan  2 12:00 LICENSE
   -rw-r--r--  1 www-data www-data 12345 Jan  2 12:00 README.md
   -rw-r--r--  1 www-data www-data  2345 Jan  2 12:00 hooks.php
   -rw-r--r--  1 www-data www-data 23456 Jan  2 12:00 proxmoxvm.php
   drwxr-xr-x  2 www-data www-data  4096 Jan  2 12:00 templates
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

4. **Clean up:**
   ```bash
   rm /tmp/main.zip
   ```

### Step 2: Verify WHMCS File Structure

After installation, verify the correct structure:

```bash
cd /path/to/your/whmcs/modules/servers/proxmoxvm
tree
```

Expected structure:
```
proxmoxvm/
├── CHANGELOG.md
├── LICENSE
├── README.md
├── hooks.php
├── proxmoxvm.php
└── templates/
    ├── clientarea.tpl
    └── error.tpl
```

### Step 3: Set Ownership (if needed)

If your web server runs under a different user:

```bash
# For Apache (www-data)
sudo chown -R www-data:www-data /path/to/your/whmcs/modules/servers/proxmoxvm

# For Nginx (nginx)
sudo chown -R nginx:nginx /path/to/your/whmcs/modules/servers/proxmoxvm

# For cPanel (username)
sudo chown -R username:username /home/username/public_html/modules/servers/proxmoxvm
```

## 🔧 WHMCS Activation Guide

### Step 1: Create Proxmox API User

Before configuring WHMCS, create a dedicated API user on your Proxmox server:

1. **SSH into your Proxmox server:**
   ```bash
   ssh root@your-proxmox-server-ip
   ```

2. **Create WHMCS user:**
   ```bash
   pveum user add whmcs@pve --password "YourSecurePassword123!"
   ```

3. **Create role with required permissions:**
   ```bash
   pveum role add WHMCS -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt VM.Audit Datastore.AllocateSpace Datastore.Audit Sys.Audit"
   ```

4. **Assign role to user:**
   ```bash
   pveum aclmod / -user whmcs@pve -role WHMCS
   ```

5. **Verify user creation:**
   ```bash
   pveum user list
   pveum acl list
   ```

### Step 2: Configure WHMCS Server

1. **Access WHMCS Admin Area:**
   - Open your browser and go to: `https://yourdomain.com/admin/`
   - Log in with your admin credentials

2. **Navigate to Server Management:**
   - Go to: `Setup` → `Products/Services` → `Servers`
   - Click: `Add New Server`

3. **Configure Server Settings:**

   | Field | Value | Example |
   |-------|-------|---------|
   | **Name** | Friendly server name | `Proxmox Server 1` |
   | **Hostname** | Proxmox server IP/domain | `192.168.1.100` or `proxmox.example.com` |
   | **IP Address** | Same as hostname | `192.168.1.100` |
   | **Username** | API username (without @pve) | `whmcs` |
   | **Password** | API user password | `YourSecurePassword123!` |
   | **Type** | Select from dropdown | `Proxmox VM Management` |
   | **Secure** | ✅ Enable SSL | `Checked` |
   | **Port** | Proxmox web port | `8006` |
   | **Max Accounts** | Leave empty for unlimited | ` ` |

4. **Test Connection:**
   - Click `Test Connection` button
   - You should see: "Connection Successful"
   - If failed, check firewall and credentials

5. **Save Configuration:**
   - Click `Save Changes`

### Step 3: Create VM Product

1. **Navigate to Products:**
   - Go to: `Setup` → `Products/Services` → `Products/Services`
   - Click: `Create a New Product`

2. **Basic Product Configuration:**
   - **Product Type:** `Server/VPS`
   - **Product Name:** `Linux VPS - Small`
   - **Product Group:** Select existing or create new
   - **Hidden:** Leave unchecked
   - Click `Continue`

3. **Configure Module Settings Tab:**

   | Setting | Description | Example Value |
   |---------|-------------|---------------|
   | **Module Name** | Select from dropdown | `Proxmox VM Management` |
   | **Server Group** | Select your Proxmox server | `Proxmox Server 1` |
   | **Node** | Proxmox node name | `pve1` |
   | **VMID** | Leave empty for auto | ` ` |
   | **OS Template** | Container template path | `local:vztmpl/debian-11-standard_11.3-1_amd64.tar.gz` |
   | **CPU Cores** | Number of cores | `1` |
   | **RAM (MB)** | Memory in MB | `1024` |
   | **Disk Size (GB)** | Storage in GB | `20` |
   | **Bandwidth (MB)** | Network speed | `100` |
   | **IP Address** | IP or "dhcp" | `dhcp` |
   | **Gateway** | Gateway IP (if static) | `192.168.1.1` |
   | **Netmask** | Network mask | `24` |

4. **Configure Pricing:**
   - Go to `Pricing` tab
   - Set your desired pricing structure
   - Configure billing cycles

5. **Save Product:**
   - Click `Save Changes`

### Step 4: Verify Installation

1. **Check Module Status:**
   ```bash
   # Check if module files are readable by web server
   sudo -u www-data php -l /path/to/your/whmcs/modules/servers/proxmoxvm/proxmoxvm.php
   ```

2. **Check WHMCS Logs:**
   - In WHMCS Admin: `Utilities` → `Logs` → `Module Log`
   - Look for any "proxmoxvm" entries

3. **Test VM Creation:**
   - Create a test order for your new product
   - Check if VM is created in Proxmox
   - Verify customer can access VM controls

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

## 🎯 Usage Guide

### For Administrators

**Provisioning Process:**
When a customer orders a VM, the module automatically:
1. Creates a new container on the specified Proxmox node
2. Assigns the configured resources
3. Generates a secure root password
4. Starts the VM
5. Emails credentials to the customer

**Management Actions:**
- View VM status in client service details
- Start/Stop/Restart VMs using action buttons
- Suspend/Unsuspend accounts
- Terminate VMs when needed

### For Customers

**Accessing VM Controls:**
1. Log into the client area
2. Go to "My Services"
3. Click on your VM service
4. Use the available action buttons

**Available Actions:**
- **Start VM** - Boot up a stopped VM
- **Stop VM** - Gracefully shut down the VM
- **Restart VM** - Reboot the VM
- **Console** - Open web-based console access

## 🔍 Troubleshooting

### Common Installation Issues

**1. Module Not Appearing in WHMCS**
```bash
# Check file permissions
ls -la /path/to/your/whmcs/modules/servers/proxmoxvm/
# Should show 755 for directories, 644 for files

# Check file ownership
ls -la /path/to/your/whmcs/modules/servers/
# Should be owned by web server user (www-data, nginx, etc.)
```

**2. Permission Denied Errors**
```bash
# Fix ownership
sudo chown -R www-data:www-data /path/to/your/whmcs/modules/servers/proxmoxvm/

# Fix permissions
sudo chmod -R 755 /path/to/your/whmcs/modules/servers/proxmoxvm/
sudo chmod 644 /path/to/your/whmcs/modules/servers/proxmoxvm/*.php
```

**3. Connection Failed Error**
```bash
# Test Proxmox connectivity
curl -k https://your-proxmox-ip:8006/api2/json/version

# Check firewall
sudo ufw status
sudo iptables -L

# Test from WHMCS server
telnet your-proxmox-ip 8006
```

### Enable Debug Mode

1. **Enable Module Debug Logging:**
   - WHMCS Admin → `Setup` → `General Settings` → `Other`
   - Enable "Module Debug Logging"
   - Click "Save Changes"

2. **View Debug Logs:**
   ```bash
   # Check WHMCS activity log
   tail -f /path/to/your/whmcs/storage/logs/activity.log | grep proxmoxvm
   
   # Or via WHMCS Admin
   # Utilities → Logs → Module Log
   ```

## 🔒 Security Best Practices

### Server Security
```bash
# Restrict API access to WHMCS server IP only
# Add to Proxmox firewall rules
pve-firewall localnet add 192.168.1.0/24 -comment "WHMCS Network"

# Enable fail2ban for additional protection
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### File Security
```bash
# Secure configuration files
chmod 600 /path/to/your/whmcs/configuration.php

# Regular security updates
sudo apt update && sudo apt upgrade

# Monitor file changes
sudo apt install aide
sudo aide --init
```

## 📊 Database Information

The module creates a table `mod_proxmoxvm` to store VM information:

```sql
CREATE TABLE IF NOT EXISTS `mod_proxmoxvm` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `vmid` int(11) NOT NULL,
  `node` varchar(255) NOT NULL,
  `password` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_id` (`service_id`),
  KEY `idx_service_id` (`service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**Check database table:**
```bash
mysql -u whmcs_user -p whmcs_database -e "DESCRIBE mod_proxmoxvm;"
```

## 🔄 Updating the Plugin

### Using Git
```bash
cd /path/to/your/whmcs/modules/servers/proxmoxvm
git pull origin main
chmod -R 755 .
chmod 644 *.php templates/*.tpl
```

### Manual Update
```bash
cd /tmp
wget https://github.com/embire2/WHMCS-Proxmox-Manager/archive/refs/heads/main.zip
unzip main.zip
cp -r WHMCS-Proxmox-Manager-main/* /path/to/your/whmcs/modules/servers/proxmoxvm/
rm -rf WHMCS-Proxmox-Manager-main main.zip
```

## 🆘 Getting Help

### Support Resources

1. **Documentation:** This README file
2. **GitHub Issues:** https://github.com/embire2/WHMCS-Proxmox-Manager/issues
3. **WHMCS Community:** https://whmcs.community

### Before Requesting Support

Please provide:
- WHMCS version: `php -v` and check Admin → System Health
- PHP version: `php -v`
- Proxmox version: `pveversion`
- Error messages from Module Log
- Output of: `ls -la /path/to/your/whmcs/modules/servers/proxmoxvm/`

### Collect Debug Information
```bash
# System information
uname -a
php -v
mysql --version

# WHMCS permissions
ls -la /path/to/your/whmcs/modules/servers/proxmoxvm/

# Recent logs
tail -n 50 /path/to/your/whmcs/storage/logs/activity.log
```

## 📄 License

This module is released under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please:

1. **Fork and clone:**
   ```bash
   git clone https://github.com/yourusername/WHMCS-Proxmox-Manager.git
   cd WHMCS-Proxmox-Manager
   ```

2. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make changes and commit:**
   ```bash
   git add .
   git commit -m "Add your feature description"
   ```

4. **Push and create PR:**
   ```bash
   git push origin feature/your-feature-name
   ```

## 📝 Changelog

### Version 1.0.2 (2025-01-02)
- Added comprehensive Linux command-line installation guide
- Included Git clone instructions for easy installation
- Added WHMCS activation steps with detailed configuration
- Enhanced troubleshooting section with CLI commands
- Improved security recommendations with command examples
- Added update procedures using Git and manual methods

### Version 1.0.1 (2025-01-01)
- Fixed database table creation issue
- Improved API error handling
- Added connection test functionality

### Version 1.0.0 (2025-01-01)
- Initial release
- Full VM lifecycle management
- Web-based console access
- Customer self-service portal
- Admin management interface
- Automatic provisioning and termination

---

**Made with ❤️ for the WHMCS community**

**Quick Install Command:**
```bash
cd /path/to/your/whmcs/modules/servers/ && git clone https://github.com/embire2/WHMCS-Proxmox-Manager.git proxmoxvm && chmod -R 755 proxmoxvm/ && chmod 644 proxmoxvm/*.php proxmoxvm/templates/*.tpl
```
