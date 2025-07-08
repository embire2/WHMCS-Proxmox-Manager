# WHMCS Proxmox VM Management Plugin

A comprehensive WHMCS module that enables full integration with Proxmox VE clusters, allowing administrators to manage Proxmox API connections and customers to control their virtual machines.

**Version:** 1.0.2  
**GitHub:** https://github.com/embire2/WHMCS-Proxmox-Manager  
**Requirements:** WHMCS 8.0+, PHP 7.4+, Proxmox VE 6.0+

## 🚀 Quick Start Guide

### Step 1: Download the Plugin

1. Download the latest release from: https://github.com/embire2/WHMCS-Proxmox-Manager/releases
2. Extract the downloaded ZIP file to your computer

### Step 2: Upload to WHMCS

1. Connect to your server using FTP or File Manager
2. Navigate to your WHMCS installation directory (usually `/home/username/public_html/` or `/var/www/html/`)
3. Upload the `proxmoxvm` folder to:
   ```
   /path/to/your/whmcs/modules/servers/
   ```
   
   **Example paths:**
   - cPanel: `/home/username/public_html/modules/servers/`
   - Plesk: `/var/www/vhosts/yourdomain.com/httpdocs/modules/servers/`
   - Standard: `/var/www/html/modules/servers/`

4. After upload, you should have this structure:
   ```
   modules/
   └── servers/
       └── proxmoxvm/
           ├── proxmoxvm.php
           ├── hooks.php
           ├── README.md
           ├── LICENSE
           └── templates/
               ├── clientarea.tpl
               └── error.tpl
   ```

### Step 3: Set File Permissions

Using your FTP client or File Manager, set the following permissions:

1. Right-click on the `proxmoxvm` folder → Properties/Permissions → Set to `755`
2. Right-click on all `.php` files → Properties/Permissions → Set to `644`
3. Right-click on the `templates` folder → Properties/Permissions → Set to `755`
4. Right-click on all `.tpl` files → Properties/Permissions → Set to `644`

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

## 🔧 Configuration Guide

### Step 1: Create Proxmox API User

1. **Access your Proxmox server via SSH:**
   ```bash
   ssh root@your-proxmox-server-ip
   ```

2. **Create a dedicated user for WHMCS:**
   ```bash
   pveum user add whmcs@pve --password your-secure-password
   ```
   
   ⚠️ **Important:** Replace `your-secure-password` with a strong password!

3. **Create a role with necessary permissions:**
   ```bash
   pveum role add WHMCS -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt VM.Audit Datastore.AllocateSpace Datastore.Audit Sys.Audit"
   ```

4. **Assign the role to the user:**
   ```bash
   pveum aclmod / -user whmcs@pve -role WHMCS
   ```

### Step 2: Configure WHMCS Server

1. **Log in to WHMCS Admin Area**

2. **Navigate to Server Configuration:**
   - Go to `Setup` → `Products/Services` → `Servers`
   - Click `Add New Server`

3. **Fill in the server details:**
   - **Name:** Give your server a friendly name (e.g., "Proxmox Server 1")
   - **Hostname:** Your Proxmox server IP or domain (e.g., `192.168.1.100` or `proxmox.yourdomain.com`)
   - **IP Address:** Same as hostname
   - **Username:** `whmcs` (without @pve)
   - **Password:** The password you created in Step 1
   - **Type:** Select "Proxmox VM Management"
   - **Secure:** ✅ Check this box (required)
   - **Port:** `8006` (default Proxmox port)

4. **Click "Test Connection"** to verify settings

5. **Click "Save Changes"**

### Step 3: Create a Product

1. **Navigate to Product Setup:**
   - Go to `Setup` → `Products/Services` → `Products/Services`
   - Click `Create a New Product`

2. **Configure Basic Settings:**
   - **Product Type:** Server/VPS
   - **Product Name:** Enter a descriptive name (e.g., "Linux VPS Small")
   - **Product Group:** Select or create a group

3. **Click "Continue"**

4. **Configure Module Settings:**
   
   In the **Module Settings** tab, configure:
   
   | Setting | Description | Example |
   |---------|-------------|---------|
   | **Module Name** | Select "Proxmox VM Management" | - |
   | **Node** | Your Proxmox node name | `pve1` |
   | **VMID** | Leave empty for auto-assignment | ` ` |
   | **OS Template** | Path to your container template | `local:vztmpl/debian-11-standard_11.3-1_amd64.tar.gz` |
   | **CPU Cores** | Number of CPU cores | `1` |
   | **RAM (MB)** | Memory in megabytes | `1024` |
   | **Disk Size (GB)** | Storage in gigabytes | `20` |
   | **Bandwidth (MB)** | Network speed in MB/s | `100` |
   | **IP Address** | Static IP or "dhcp" | `dhcp` |
   | **Gateway** | Gateway IP (if static) | `192.168.1.1` |
   | **Netmask** | Network mask | `24` |

5. **Configure Pricing** in the Pricing tab

6. **Click "Save Changes"**

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

### Common Issues and Solutions

**1. Connection Failed Error**
- ✅ Verify Proxmox server is accessible from WHMCS server
- ✅ Check firewall allows port 8006
- ✅ Ensure API credentials are correct
- ✅ Verify SSL certificate (self-signed is OK)

**2. VM Creation Failed**
- ✅ Check the OS template exists on Proxmox
- ✅ Verify sufficient resources on the node
- ✅ Ensure API user has correct permissions
- ✅ Check for VMID conflicts

**3. Console Access Not Working**
- ✅ Ensure noVNC is enabled on Proxmox
- ✅ Check browser allows pop-ups
- ✅ Verify network connectivity

### Enable Debug Mode

To troubleshoot issues:

1. **Enable Module Debug Logging:**
   - Go to `Setup` → `General Settings` → `Other`
   - Enable "Module Debug Logging"
   - Click "Save Changes"

2. **View Debug Logs:**
   - Go to `Utilities` → `Logs` → `Module Log`
   - Look for entries related to "proxmoxvm"

## 🔒 Security Best Practices

1. **API Security:**
   - Use strong passwords for API users
   - Limit API access to WHMCS server IP only
   - Regularly rotate API credentials

2. **Network Security:**
   - Use firewall rules to restrict access
   - Enable HTTPS/SSL on both WHMCS and Proxmox
   - Consider VPN for server-to-server communication

3. **VM Security:**
   - Use secure password generation
   - Enable firewall on VMs
   - Keep templates updated

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

This table is created automatically when the first VM is provisioned.

## 🆘 Getting Help

### Support Resources

1. **Documentation:** This README file
2. **GitHub Issues:** https://github.com/embire2/WHMCS-Proxmox-Manager/issues
3. **WHMCS Community:** https://whmcs.community

### Before Requesting Support

Please provide:
- WHMCS version
- PHP version
- Proxmox version
- Error messages from Module Log
- Steps to reproduce the issue

## 📄 License

This module is released under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 Changelog

### Version 1.0.2 (2025-01-02)
- Enhanced documentation with step-by-step installation guide
- Added comprehensive troubleshooting section
- Improved error handling and logging
- Added support for custom VM hostnames
- Fixed password encryption for better security
- Updated file permission recommendations

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
