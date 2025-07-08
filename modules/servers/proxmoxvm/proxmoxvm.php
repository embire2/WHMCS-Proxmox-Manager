<?php
/**
 * WHMCS Proxmox VM Management Module
 * 
 * @package    WHMCS
 * @author     ProxmoxVM Plugin
 * @copyright  Copyright (c) 2025
 * @license    MIT License
 * @version    1.0.0
 */

if (!defined("WHMCS")) {
    die("This file cannot be accessed directly");
}

use WHMCS\Database\Capsule;

/**
 * Module metadata
 */
function proxmoxvm_MetaData()
{
    return array(
        'DisplayName' => 'Proxmox VM Management',
        'APIVersion' => '1.1',
        'RequiresServer' => true,
        'DefaultNonSSLPort' => '8006',
        'DefaultSSLPort' => '8006',
        'ServiceSingleSignOnLabel' => 'Login to VM Console',
    );
}

/**
 * Module configuration options
 */
function proxmoxvm_ConfigOptions()
{
    return array(
        'Node' => array(
            'Type' => 'text',
            'Size' => '25',
            'Default' => '',
            'Description' => 'Proxmox Node Name',
        ),
        'VMID' => array(
            'Type' => 'text',
            'Size' => '10',
            'Default' => '',
            'Description' => 'VM ID (leave empty for auto-assignment)',
        ),
        'OS Template' => array(
            'Type' => 'text',
            'Size' => '50',
            'Default' => 'local:vztmpl/debian-11-standard_11.3-1_amd64.tar.gz',
            'Description' => 'OS Template Path',
        ),
        'CPU Cores' => array(
            'Type' => 'text',
            'Size' => '5',
            'Default' => '1',
            'Description' => 'Number of CPU cores',
        ),
        'RAM (MB)' => array(
            'Type' => 'text',
            'Size' => '10',
            'Default' => '512',
            'Description' => 'RAM in MB',
        ),
        'Disk Size (GB)' => array(
            'Type' => 'text',
            'Size' => '10',
            'Default' => '10',
            'Description' => 'Disk size in GB',
        ),
        'Bandwidth (MB)' => array(
            'Type' => 'text',
            'Size' => '10',
            'Default' => '100',
            'Description' => 'Network bandwidth in MB/s',
        ),
        'IP Address' => array(
            'Type' => 'text',
            'Size' => '20',
            'Default' => 'dhcp',
            'Description' => 'IP Address or "dhcp"',
        ),
        'Gateway' => array(
            'Type' => 'text',
            'Size' => '20',
            'Default' => '',
            'Description' => 'Gateway IP (if static IP)',
        ),
        'Netmask' => array(
            'Type' => 'text',
            'Size' => '5',
            'Default' => '24',
            'Description' => 'Network mask (e.g., 24)',
        ),
    );
}

/**
 * Proxmox API Class
 */
class ProxmoxAPI
{
    private $hostname;
    private $username;
    private $password;
    private $realm;
    private $port;
    private $ticket;
    private $CSRFPreventionToken;
    
    public function __construct($hostname, $username, $password, $realm = 'pam', $port = 8006)
    {
        $this->hostname = $hostname;
        $this->username = $username;
        $this->password = $password;
        $this->realm = $realm;
        $this->port = $port;
    }
    
    /**
     * Login to Proxmox API
     */
    public function login()
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/access/ticket";
        $data = array(
            'username' => $this->username . '@' . $this->realm,
            'password' => $this->password,
        );
        
        $response = $this->request('POST', $url, $data, false);
        
        if ($response && isset($response['data'])) {
            $this->ticket = $response['data']['ticket'];
            $this->CSRFPreventionToken = $response['data']['CSRFPreventionToken'];
            return true;
        }
        
        return false;
    }
    
    /**
     * Make API request
     */
    private function request($method, $url, $data = null, $auth = true)
    {
        $ch = curl_init();
        
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
        
        if ($auth && $this->ticket) {
            curl_setopt($ch, CURLOPT_COOKIE, "PVEAuthCookie=" . $this->ticket);
            curl_setopt($ch, CURLOPT_HTTPHEADER, array(
                'CSRFPreventionToken: ' . $this->CSRFPreventionToken,
            ));
        }
        
        if ($method == 'POST') {
            curl_setopt($ch, CURLOPT_POST, true);
            if ($data) {
                curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
            }
        } elseif ($method == 'PUT') {
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
            if ($data) {
                curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
            }
        } elseif ($method == 'DELETE') {
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
        }
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($response) {
            return json_decode($response, true);
        }
        
        return false;
    }
    
    /**
     * Get next available VMID
     */
    public function getNextVMID()
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/cluster/nextid";
        $response = $this->request('GET', $url);
        
        if ($response && isset($response['data'])) {
            return $response['data'];
        }
        
        return 100; // Default starting VMID
    }
    
    /**
     * Create VM
     */
    public function createVM($node, $vmid, $config)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/qemu";
        
        $data = array(
            'vmid' => $vmid,
            'name' => $config['hostname'],
            'cores' => $config['cores'],
            'memory' => $config['memory'],
            'scsihw' => 'virtio-scsi-pci',
            'scsi0' => "local-lvm:{$config['disk']},cache=writeback",
            'net0' => "virtio,bridge=vmbr0",
            'ostype' => 'l26',
        );
        
        return $this->request('POST', $url, $data);
    }
    
    /**
     * Create Container (LXC)
     */
    public function createContainer($node, $vmid, $config)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/lxc";
        
        $data = array(
            'vmid' => $vmid,
            'hostname' => $config['hostname'],
            'ostemplate' => $config['ostemplate'],
            'cores' => $config['cores'],
            'memory' => $config['memory'],
            'swap' => $config['swap'] ?? 512,
            'rootfs' => "local-lvm:{$config['disk']}",
            'net0' => "name=eth0,bridge=vmbr0,ip={$config['ip']}/{$config['netmask']},gw={$config['gateway']}",
            'password' => $config['password'],
            'start' => 1,
        );
        
        if ($config['ip'] == 'dhcp') {
            $data['net0'] = "name=eth0,bridge=vmbr0,ip=dhcp";
        }
        
        return $this->request('POST', $url, $data);
    }
    
    /**
     * Start VM/Container
     */
    public function startVM($node, $vmid)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/qemu/{$vmid}/status/start";
        return $this->request('POST', $url);
    }
    
    /**
     * Stop VM/Container
     */
    public function stopVM($node, $vmid)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/qemu/{$vmid}/status/stop";
        return $this->request('POST', $url);
    }
    
    /**
     * Restart VM/Container
     */
    public function restartVM($node, $vmid)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/qemu/{$vmid}/status/reboot";
        return $this->request('POST', $url);
    }
    
    /**
     * Delete VM/Container
     */
    public function deleteVM($node, $vmid)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/qemu/{$vmid}";
        return $this->request('DELETE', $url);
    }
    
    /**
     * Get VM Status
     */
    public function getVMStatus($node, $vmid)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/qemu/{$vmid}/status/current";
        $response = $this->request('GET', $url);
        
        if ($response && isset($response['data'])) {
            return $response['data'];
        }
        
        return false;
    }
    
    /**
     * Get VNC Console
     */
    public function getVNCConsole($node, $vmid)
    {
        $url = "https://{$this->hostname}:{$this->port}/api2/json/nodes/{$node}/qemu/{$vmid}/vncproxy";
        $data = array('websocket' => 1);
        
        return $this->request('POST', $url, $data);
    }
}

/**
 * Create VM Account
 */
function proxmoxvm_CreateAccount($params)
{
    try {
        // Initialize API connection
        $api = new ProxmoxAPI(
            $params['serverhostname'],
            $params['serverusername'],
            $params['serverpassword']
        );
        
        if (!$api->login()) {
            return "Failed to connect to Proxmox API";
        }
        
        // Get configuration
        $node = $params['configoption1'];
        $vmid = $params['configoption2'] ?: $api->getNextVMID();
        $ostemplate = $params['configoption3'];
        $cores = $params['configoption4'];
        $memory = $params['configoption5'];
        $disk = $params['configoption6'];
        $bandwidth = $params['configoption7'];
        $ip = $params['configoption8'];
        $gateway = $params['configoption9'];
        $netmask = $params['configoption10'];
        
        // Generate password if not set
        $password = $params['password'] ?: substr(str_shuffle('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()'), 0, 12);
        
        // Create VM configuration
        $config = array(
            'hostname' => $params['domain'] ?: 'vm-' . $params['serviceid'],
            'ostemplate' => $ostemplate,
            'cores' => $cores,
            'memory' => $memory,
            'disk' => $disk,
            'ip' => $ip,
            'gateway' => $gateway,
            'netmask' => $netmask,
            'password' => $password,
        );
        
        // Create container
        $result = $api->createContainer($node, $vmid, $config);
        
        if ($result) {
            // Store VM details in database
            Capsule::table('mod_proxmoxvm')->insert([
                'service_id' => $params['serviceid'],
                'vmid' => $vmid,
                'node' => $node,
                'password' => encrypt($password),
                'created_at' => date('Y-m-d H:i:s'),
            ]);
            
            // Update service username with VMID
            Capsule::table('tblhosting')
                ->where('id', $params['serviceid'])
                ->update(['username' => $vmid]);
            
            return 'success';
        }
        
        return "Failed to create VM";
        
    } catch (Exception $e) {
        logModuleCall('proxmoxvm', __FUNCTION__, $params, $e->getMessage(), $e->getTraceAsString());
        return $e->getMessage();
    }
}

/**
 * Suspend VM Account
 */
function proxmoxvm_SuspendAccount($params)
{
    try {
        $api = new ProxmoxAPI(
            $params['serverhostname'],
            $params['serverusername'],
            $params['serverpassword']
        );
        
        if (!$api->login()) {
            return "Failed to connect to Proxmox API";
        }
        
        $vmDetails = Capsule::table('mod_proxmoxvm')
            ->where('service_id', $params['serviceid'])
            ->first();
        
        if (!$vmDetails) {
            return "VM details not found";
        }
        
        $result = $api->stopVM($vmDetails->node, $vmDetails->vmid);
        
        if ($result) {
            return 'success';
        }
        
        return "Failed to suspend VM";
        
    } catch (Exception $e) {
        logModuleCall('proxmoxvm', __FUNCTION__, $params, $e->getMessage(), $e->getTraceAsString());
        return $e->getMessage();
    }
}

/**
 * Unsuspend VM Account
 */
function proxmoxvm_UnsuspendAccount($params)
{
    try {
        $api = new ProxmoxAPI(
            $params['serverhostname'],
            $params['serverusername'],
            $params['serverpassword']
        );
        
        if (!$api->login()) {
            return "Failed to connect to Proxmox API";
        }
        
        $vmDetails = Capsule::table('mod_proxmoxvm')
            ->where('service_id', $params['serviceid'])
            ->first();
        
        if (!$vmDetails) {
            return "VM details not found";
        }
        
        $result = $api->startVM($vmDetails->node, $vmDetails->vmid);
        
        if ($result) {
            return 'success';
        }
        
        return "Failed to unsuspend VM";
        
    } catch (Exception $e) {
        logModuleCall('proxmoxvm', __FUNCTION__, $params, $e->getMessage(), $e->getTraceAsString());
        return $e->getMessage();
    }
}

/**
 * Terminate VM Account
 */
function proxmoxvm_TerminateAccount($params)
{
    try {
        $api = new ProxmoxAPI(
            $params['serverhostname'],
            $params['serverusername'],
            $params['serverpassword']
        );
        
        if (!$api->login()) {
            return "Failed to connect to Proxmox API";
        }
        
        $vmDetails = Capsule::table('mod_proxmoxvm')
            ->where('service_id', $params['serviceid'])
            ->first();
        
        if (!$vmDetails) {
            return "VM details not found";
        }
        
        // Stop VM first
        $api->stopVM($vmDetails->node, $vmDetails->vmid);
        sleep(2);
        
        // Delete VM
        $result = $api->deleteVM($vmDetails->node, $vmDetails->vmid);
        
        if ($result) {
            // Remove from database
            Capsule::table('mod_proxmoxvm')
                ->where('service_id', $params['serviceid'])
                ->delete();
            
            return 'success';
        }
        
        return "Failed to terminate VM";
        
    } catch (Exception $e) {
        logModuleCall('proxmoxvm', __FUNCTION__, $params, $e->getMessage(), $e->getTraceAsString());
        return $e->getMessage();
    }
}

/**
 * Client Area Output
 */
function proxmoxvm_ClientArea($params)
{
    try {
        $vmDetails = Capsule::table('mod_proxmoxvm')
            ->where('service_id', $params['serviceid'])
            ->first();
        
        if (!$vmDetails) {
            return array(
                'templatefile' => 'error',
                'vars' => array('error' => 'VM details not found'),
            );
        }
        
        // Get VM status
        $api = new ProxmoxAPI(
            $params['serverhostname'],
            $params['serverusername'],
            $params['serverpassword']
        );
        
        $status = 'Unknown';
        if ($api->login()) {
            $vmStatus = $api->getVMStatus($vmDetails->node, $vmDetails->vmid);
            if ($vmStatus) {
                $status = $vmStatus['status'];
            }
        }
        
        return array(
            'templatefile' => 'clientarea',
            'vars' => array(
                'vmid' => $vmDetails->vmid,
                'node' => $vmDetails->node,
                'status' => $status,
                'password' => decrypt($vmDetails->password),
                'cores' => $params['configoption4'],
                'memory' => $params['configoption5'],
                'disk' => $params['configoption6'],
                'ip' => $params['configoption8'],
            ),
        );
        
    } catch (Exception $e) {
        logModuleCall('proxmoxvm', __FUNCTION__, $params, $e->getMessage(), $e->getTraceAsString());
        return array(
            'templatefile' => 'error',
            'vars' => array('error' => $e->getMessage()),
        );
    }
}

/**
 * Admin Custom Button Functions
 */
function proxmoxvm_AdminCustomButtonArray()
{
    return array(
        "Start VM" => "AdminStartVM",
        "Stop VM" => "AdminStopVM",
        "Restart VM" => "AdminRestartVM",
        "Get Status" => "AdminGetStatus",
    );
}

/**
 * Client Custom Button Functions
 */
function proxmoxvm_ClientAreaCustomButtonArray()
{
    return array(
        "Start VM" => "ClientStartVM",
        "Stop VM" => "ClientStopVM",
        "Restart VM" => "ClientRestartVM",
        "Console" => "ClientConsole",
    );
}

/**
 * Admin Start VM
 */
function proxmoxvm_AdminStartVM($params)
{
    return proxmoxvm_UnsuspendAccount($params);
}

/**
 * Admin Stop VM
 */
function proxmoxvm_AdminStopVM($params)
{
    return proxmoxvm_SuspendAccount($params);
}

/**
 * Admin Restart VM
 */
function proxmoxvm_AdminRestartVM($params)
{
    try {
        $api = new ProxmoxAPI(
            $params['serverhostname'],
            $params['serverusername'],
            $params['serverpassword']
        );
        
        if (!$api->login()) {
            return "Failed to connect to Proxmox API";
        }
        
        $vmDetails = Capsule::table('mod_proxmoxvm')
            ->where('service_id', $params['serviceid'])
            ->first();
        
        if (!$vmDetails) {
            return "VM details not found";
        }
        
        $result = $api->restartVM($vmDetails->node, $vmDetails->vmid);
        
        if ($result) {
            return 'success';
        }
        
        return "Failed to restart VM";
        
    } catch (Exception $e) {
        logModuleCall('proxmoxvm', __FUNCTION__, $params, $e->getMessage(), $e->getTraceAsString());
        return $e->getMessage();
    }
}

/**
 * Client Start VM
 */
function proxmoxvm_ClientStartVM($params)
{
    return proxmoxvm_AdminStartVM($params);
}

/**
 * Client Stop VM
 */
function proxmoxvm_ClientStopVM($params)
{
    return proxmoxvm_AdminStopVM($params);
}

/**
 * Client Restart VM
 */
function proxmoxvm_ClientRestartVM($params)
{
    return proxmoxvm_AdminRestartVM($params);
}

/**
 * Service Single Sign-On
 */
function proxmoxvm_ServiceSingleSignOn($params)
{
    try {
        $vmDetails = Capsule::table('mod_proxmoxvm')
            ->where('service_id', $params['serviceid'])
            ->first();
        
        if (!$vmDetails) {
            return array('success' => false, 'errorMsg' => 'VM details not found');
        }
        
        $api = new ProxmoxAPI(
            $params['serverhostname'],
            $params['serverusername'],
            $params['serverpassword']
        );
        
        if (!$api->login()) {
            return array('success' => false, 'errorMsg' => 'Failed to connect to Proxmox API');
        }
        
        $console = $api->getVNCConsole($vmDetails->node, $vmDetails->vmid);
        
        if ($console && isset($console['data'])) {
            $consoleUrl = "https://{$params['serverhostname']}:8006/?console=lxc&vmid={$vmDetails->vmid}&node={$vmDetails->node}&novnc=1";
            
            return array(
                'success' => true,
                'redirectTo' => $consoleUrl,
            );
        }
        
        return array('success' => false, 'errorMsg' => 'Failed to get console access');
        
    } catch (Exception $e) {
        logModuleCall('proxmoxvm', __FUNCTION__, $params, $e->getMessage(), $e->getTraceAsString());
        return array('success' => false, 'errorMsg' => $e->getMessage());
    }
}
