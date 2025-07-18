WHMCS Proxmox VM Management Plugin
A comprehensive WHMCS module that enables full integration with Proxmox VE clusters, allowing administrators to manage Proxmox API connections and customers to control their virtual machines.

Features
Administrator Features
Configure multiple Proxmox servers/clusters
Set up API authentication details
Link customer accounts to specific nodes and VMs
Configure VM templates and resource limits
Monitor VM status and resource usage
Perform administrative actions (start, stop, restart, terminate)
Customer Features
View VM details and current status
Start, stop, and restart VMs
Access VM console via web interface
View assigned resources (CPU, RAM, disk, IP)
Secure password management
Requirements
WHMCS 8.0 or higher
PHP 7.4 or higher
Proxmox VE 6.0 or higher
SSL certificate on Proxmox server (self-signed is acceptable)
Proxmox API user with appropriate permissions
Installation Instructions
Step 1: Upload Module Files
Upload the entire proxmoxvm folder to your WHMCS installation:

/path/to/whmcs/modules/servers/proxmoxvm/
Ensure proper file permissions:

chmod 755 /path/to/whmcs/modules/servers/proxmoxvm
chmod 644 /path/to/whmcs/modules/servers/proxmoxvm/*.php
chmod 755 /path/to/whmcs/modules/servers/proxmoxvm/templates
chmod 644 /path/to/whmcs/modules/servers/proxmoxvm/templates/*.tpl
Step 2: Create Proxmox API User
Log in to your Proxmox server via SSH

Create a new user for WHMCS:

pveum user add whmcs@pve --password your-secure-password
Create a role with necessary permissions:

pveum role add WHMCS -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt VM.Audit Datastore.AllocateSpace Datastore.Audit Sys.Audit"
Assign the role to the user:

pveum aclmod / -user whmcs@pve -role WHMCS
Step 3: Configure WHMCS Server
Log in to WHMCS Admin Area

Navigate to Setup → Products/Services → Servers

Click Add New Server

Fill in the server details:

Name: Your Proxmox Server Name
Hostname: Your Proxmox server IP or hostname
IP Address: Your Proxmox server IP
Assigned IP Addresses: (Optional) List of available IPs
Username: whmcs (without @pve)
Password: The password you set in Step 2
Type: Select "Proxmox VM Management"
Secure: Check this box (Proxmox uses HTTPS)
Port: 8006 (default Proxmox port)
Click Save Changes

Step 4: Create Product
Navigate to Setup → Products/Services → Products/Services

Click Create a New Product

Configure the product:

Product Type: Server/VPS
Product Name: Your VM product name
Product Group: Select or create a group
Module: Select "Proxmox VM Management"
Click Continue

In the Module Settings tab, configure:

Node: The Proxmox node name (e.g., pve1)
VMID: Leave empty for auto-assignment or specify a starting ID
OS Template: Path to template (e.g., local:vztmpl/debian-11-standard_11.3-1_amd64.tar.gz)
CPU Cores: Number of CPU cores
RAM (MB): Amount of RAM in megabytes
Disk Size (GB): Disk space in gigabytes
Bandwidth (MB): Network bandwidth limit
IP Address: Static IP or "dhcp"
Gateway: Gateway IP (if using static IP)
Netmask: Network mask (e.g., 24)
Configure pricing and other options as needed

Click Save Changes

Step 5: Database Setup
The module will automatically create the required database table when the first VM is provisioned. The table structure is:

CREATE TABLE `mod_proxmoxvm` (
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
Usage
For Administrators
Provisioning: When a new order is placed, the module will automatically:

Create a new VM/container on the specified node
Assign the configured resources
Generate a secure root password
Start the VM
Store VM details in the database
Management: From the admin area, you can:

View VM status
Start/Stop/Restart VMs
Suspend/Unsuspend accounts
Terminate VMs
For Customers
Client Area: Customers can access their VM details by:

Logging into the client area
Navigating to their service
Viewing VM information and status
VM Controls: Available actions:

Start VM: Start a stopped VM
Stop VM: Gracefully shut down the VM
Restart VM: Reboot the VM
Open Console: Access the VM console via web browser
Troubleshooting
Common Issues
Connection Failed

Verify Proxmox server is accessible
Check firewall rules (port 8006)
Ensure API credentials are correct
Check SSL certificate issues
VM Creation Failed

Verify the OS template exists
Check available resources on the node
Ensure proper permissions for the API user
Check VMID conflicts
Console Access Issues

Ensure noVNC is enabled on Proxmox
Check browser compatibility
Verify network connectivity
Debug Mode
To enable debug logging:

Enable WHMCS Module Debug Logging:

Go to Setup → General Settings → Other
Enable "Module Debug Logging"
Check logs at:

Utilities → Logs → Module Log
Security Considerations
API Credentials: Store securely and use strong passwords
Network Security: Use firewall rules to restrict API access
SSL Certificates: Always use HTTPS for API communication
Password Storage: VM passwords are encrypted in the database
Permission Scope: Limit API user permissions to minimum required
API Permissions Required
The Proxmox API user needs the following minimum permissions:

VM.Allocate
VM.Clone
VM.Config.*
VM.Console
VM.Monitor
VM.PowerMgmt
VM.Audit
Datastore.AllocateSpace
Datastore.Audit
Sys.Audit
Support
For issues or feature requests:

Check the module logs for error details
Verify all configuration settings
Ensure Proxmox and WHMCS are up to date
Contact your system administrator
License
This module is provided under the MIT License. See LICENSE file for details.

Changelog
Version 1.0.0 (2025-01-01)
Initial release
Full VM lifecycle management
Web-based console access
Customer self-service portal
Admin management interface
Automatic provisioning and termination
