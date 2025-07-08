# Changelog

All notable changes to the WHMCS Proxmox VM Management Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-01-02

### Added
- Comprehensive step-by-step installation guide for non-technical users
- Detailed troubleshooting section with common issues and solutions
- Example file paths for different hosting environments (cPanel, Plesk, etc.)
- Security best practices section
- Support resources and contact information
- Table structure for easy module configuration reference

### Changed
- Enhanced documentation with clearer formatting and organization
- Improved error handling with more descriptive messages
- Updated file permission recommendations for better security
- Reorganized README sections for better flow

### Fixed
- Password encryption using WHMCS built-in encryption functions
- Database table creation with proper error checking
- Module logging for better debugging capabilities

### Security
- Added recommendations for API user permissions
- Included firewall configuration guidelines
- Enhanced password generation algorithm

## [1.0.1] - 2025-01-01

### Fixed
- Database table creation issue when provisioning first VM
- API error handling for better error messages
- Connection test functionality in server configuration

### Added
- Automatic database table creation on first use
- Better error logging for troubleshooting

## [1.0.0] - 2025-01-01

### Added
- Initial release of WHMCS Proxmox VM Management Plugin
- Full VM lifecycle management (create, start, stop, restart, terminate)
- Web-based console access via noVNC
- Customer self-service portal with VM controls
- Admin management interface with full control
- Automatic provisioning on order placement
- Support for LXC containers
- Configurable resource allocation (CPU, RAM, disk, bandwidth)
- Secure password generation and storage
- Multi-language support structure
- Module debug logging support

### Features
- **Administrator Features:**
  - Configure multiple Proxmox servers/clusters
  - Set up API authentication
  - Link customer accounts to VMs
  - Configure VM templates and limits
  - Monitor VM status and resources
  - Administrative actions (start, stop, restart, terminate)

- **Customer Features:**
  - View VM details and status
  - Start, stop, and restart VMs
  - Access VM console via browser
  - View assigned resources
  - Secure password management

[1.0.2]: https://github.com/embire2/WHMCS-Proxmox-Manager/releases/tag/v1.0.2
[1.0.1]: https://github.com/embire2/WHMCS-Proxmox-Manager/releases/tag/v1.0.1
[1.0.0]: https://github.com/embire2/WHMCS-Proxmox-Manager/releases/tag/v1.0.0
