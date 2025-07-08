<?php
/**
 * WHMCS Proxmox VM Module Hooks
 */

if (!defined("WHMCS")) {
    die("This file cannot be accessed directly");
}

use WHMCS\Database\Capsule;

/**
 * Create database table on activation
 */
add_hook('AfterModuleCreate', 1, function($vars) {
    if ($vars['producttype'] == 'server' && $vars['module'] == 'proxmoxvm') {
        try {
            if (!Capsule::schema()->hasTable('mod_proxmoxvm')) {
                Capsule::schema()->create('mod_proxmoxvm', function ($table) {
                    $table->increments('id');
                    $table->integer('service_id')->unique();
                    $table->integer('vmid');
                    $table->string('node');
                    $table->text('password');
                    $table->timestamps();
                    $table->index('service_id');
                });
            }
        } catch (Exception $e) {
            logActivity('Proxmox VM Module: Failed to create database table - ' . $e->getMessage());
        }
    }
});
