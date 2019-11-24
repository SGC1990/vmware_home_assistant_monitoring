<#
.SYNOPSIS
  Name: esxi_to_home-assistant.ps1
 This is a script that is supplying Home-Assistant with data from VMware ESXi.
.DESCRIPTION
  Both PowerCLI and Home-Assistant and the PowerShell Module is required to run this scrip.
  https://www.vmware.com/support/developer/PowerCLI/
  https://github.com/flemmingss/Home-Assistant-PowerShell-Module
.NOTES
    Original release Date: Nov 2019
  Author: Flemming Sørvollen Skaret (https://github.com/flemmingss/)
.LINK
  https://github.com/flemmingss/
  https://flemmingss.com/
.EXAMPLE
 See https://flemmingss.com/monitoring-vmware-esxi-in-home-assistant-with-powershell
#>

###Home-Assistant access configuration

$ha_ip = "10.0.24.4" #HA ip
$ha_port = "8123" #HA port
$ha_access_token = "eyYfo49g036gdKg5LSki4w04tkifulaglgkMn3idnf2w57x5eyfog036gdKg5LSkgw04tkifulaglgkMidnf2w57axyYfo49g036gdKLSkgi4w04tkifaglgkMn3idnf2w57axyYfo49g036gdKg5LSkgi4w04tkifulaglgkMn3idnf2w57ax5" #HA Long-Lived Access Tokens, replace this

###ESXI access configuration

$esxi_ip = "10.0.1.10" #esxi ip
$esxi_protocol = "https" #esxi protocol
$esxi_user = "root" #esxi user
$esxi_password = "MyEsxiPw" #esxi password


###Connect to ESXI host

Connect-VIServer -Server $esxi_ip -Protocol $esxi_protocol -User $esxi_user -Password $esxi_password

### Collect data from ESXI

# Get data from ESXI host
$vmhost_info = get-vmhost
$esxi_cpu_usage_mhz = ($vmhost_info | Select-Object CpuUsageMhz).CpuUsageMhz
$esxi_cpu_total_mhz = ($vmhost_info | Select-Object CpuTotalMhz).CpuTotalMhz
$esxi_memory_usage_mb = ($vmhost_info | Select-Object MemoryUsageMB).MemoryUsageMB
$esxi_memory_total_mb = [math]::Round(($vmhost_info | Select-Object MemoryTotalMB).MemoryTotalMB)

# Get data from ESXI datastores
$datastore_info = Get-Datastore
$esxi_datastore1_space_free_gb = [Math]::Truncate(($datastore_info | Where-Object {$_.Name -eq "datastore1"} | Select-Object FreeSpaceGB).FreeSpaceGB*100)/100
$esxi_datastore1_space_total_gb = [Math]::Truncate(($datastore_info | Where-Object {$_.Name -eq "datastore1"} | Select-Object CapacityGB).CapacityGB*100)/100
$esxi_datastore2_space_free_gb = [Math]::Truncate(($datastore_info | Where-Object {$_.Name -eq "datastore2"} | Select-Object FreeSpaceGB).FreeSpaceGB*100)/100
$esxi_datastore2_space_total_gb = [Math]::Truncate(($datastore_info | Where-Object {$_.Name -eq "datastore2"} | Select-Object CapacityGB).CapacityGB*100)/100
$esxi_datastore3_space_free_gb = [Math]::Truncate(($datastore_info | Where-Object {$_.Name -eq "datastore3"} | Select-Object FreeSpaceGB).FreeSpaceGB*100)/100
$esxi_datastore3_space_total_gb = [Math]::Truncate(($datastore_info | Where-Object {$_.Name -eq "datastore3"} | Select-Object CapacityGB).CapacityGB*100)/100

# Get uptime for ESXI host
$esxi_uptime_total_seconds = ($vmhost_info | Get-View | select Name, @{N="Uptime"; E={(Get-Date) - $_.Summary.Runtime.BootTime}}).Uptime.TotalSeconds

# Get VM stat
$vm_name = "Admin-Server" #name of VM
$timeframe_minutes = 30 #For how long time period
$stat_info = Get-Stat -Entity "$vm_name" -Start (Get-Date).AddMinutes(-$timeframe_minutes) -ErrorAction SilentlyContinue
$esxi_vm_admin_server_avg_cpu_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='CPU(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'cpu.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."CPU(%)"
$esxi_vm_admin_server_avg_memory_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Memory(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'mem.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Memory(%)"
$esxi_vm_admin_server_avg_net_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Net(KBps';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'net.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Net(KBps"
$esxi_vm_admin_server_avg_disk_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Disk(KBps)';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'disk.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Disk(KBps)"

$vm_name = "Home-Assistant"
$timeframe_minutes = 30 
$stat_info = Get-Stat -Entity "$vm_name" -Start (Get-Date).AddMinutes(-$timeframe_minutes) -ErrorAction SilentlyContinue
$esxi_vm_home_assistant_avg_cpu_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='CPU(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'cpu.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."CPU(%)"
$esxi_vm_home_assistant_avg_memory_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Memory(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'mem.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Memory(%)"
$esxi_vm_home_assistant_avg_net_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Net(KBps';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'net.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Net(KBps"
$esxi_vm_home_assistant_avg_disk_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Disk(KBps)';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'disk.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Disk(KBps)"

$vm_name = "Plex"
$timeframe_minutes = 30 
$stat_info = Get-Stat -Entity "$vm_name" -Start (Get-Date).AddMinutes(-$timeframe_minutes) -ErrorAction SilentlyContinue
$esxi_vm_plex_avg_cpu_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='CPU(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'cpu.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."CPU(%)"
$esxi_vm_plex_avg_memory_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Memory(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'mem.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Memory(%)"
$esxi_vm_plex_avg_net_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Net(KBps';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'net.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Net(KBps"
$esxi_vm_plex_avg_disk_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Disk(KBps)';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'disk.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Disk(KBps)"

$vm_name = "Deluge"
$timeframe_minutes = 30 
$stat_info = Get-Stat -Entity "$vm_name" -Start (Get-Date).AddMinutes(-$timeframe_minutes) -ErrorAction SilentlyContinue
$esxi_vm_deluge_avg_cpu_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='CPU(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'cpu.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."CPU(%)"
$esxi_vm_deluge_avg_memory_usage_pct = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Memory(%)';E={"{0:N1}" -f ($_.Group | where{$_.MetricId -eq 'mem.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Memory(%)"
$esxi_vm_deluge_avg_net_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Net(KBps';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'net.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Net(KBps"
$esxi_vm_deluge_avg_disk_usage_kbps = ($stat_info | Group-Object -Property {$_.Entity.Name} | Select @{N='Disk(KBps)';E={"{0:N2}" -f ($_.Group | where{$_.MetricId -eq 'disk.usage.average'} | Measure-Object -Property Value -Average | select -ExpandProperty Average)}})."Disk(KBps)"

# Get VM state
$vm_info = get-vm

$vm_name = "Admin-Server"
$esxi_vm_admin_server_powerstate = ($vm_info | Where-Object {$_.Name -eq $vm_name} | Select-Object PowerState).PowerState #PoweredOff, PoweredOn or Suspended

$vm_name = "Home-Assistant"
$esxi_vm_home_assistant_powerstate = ($vm_info | Where-Object {$_.Name -eq $vm_name} | Select-Object PowerState).PowerState #PoweredOff, PoweredOn or Suspended

$vm_name = "Plex"
$esxi_vm_plex_powerstate = ($vm_info | Where-Object {$_.Name -eq $vm_name} | Select-Object PowerState).PowerState #PoweredOff, PoweredOn or Suspended

$vm_name = "Deluge"
$esxi_vm_deluge_powerstate = ($vm_info | Where-Object {$_.Name -eq $vm_name} | Select-Object PowerState).PowerState #PoweredOff, PoweredOn or Suspended

###Disconnect from ESXI
Disconnect-VIServer -confirm:$false

###Connect to Home-Assistant
New-HomeAssistantSession -ip $ha_ip -port $ha_port -token $ha_access_token #Auth Settings

### Update var entities in Home-Assistant

#Hash table with entities and values
$var_to_ha_hash_table = @{
    "var.esxi_vm_admin_server_avg_cpu_usage_pct" = $esxi_vm_admin_server_avg_cpu_usage_pct
    "var.esxi_vm_admin_server_avg_memory_usage_pct" = $esxi_vm_admin_server_avg_memory_usage_pct
    "var.esxi_vm_admin_server_avg_net_usage_kbps" = $esxi_vm_admin_server_avg_net_usage_kbps
    "var.esxi_vm_admin_server_avg_disk_usage_kbps" = $esxi_vm_admin_server_avg_disk_usage_kbps
    "var.esxi_vm_home_assistant_avg_cpu_usage_pct" = $esxi_vm_home_assistant_avg_cpu_usage_pct
    "var.esxi_vm_home_assistant_avg_memory_usage_pct" = $esxi_vm_home_assistant_avg_memory_usage_pct
    "var.esxi_vm_home_assistant_avg_net_usage_kbps" = $esxi_vm_home_assistant_avg_net_usage_kbps
    "var.esxi_vm_home_assistant_avg_disk_usage_kbps" = $esxi_vm_home_assistant_avg_disk_usage_kbps
    "var.esxi_vm_plex_avg_cpu_usage_pct" = $esxi_vm_plex_avg_cpu_usage_pct
    "var.esxi_vm_plex_avg_memory_usage_pct" = $esxi_vm_plex_avg_memory_usage_pct
    "var.esxi_vm_plex_avg_net_usage_kbps" = $esxi_vm_plex_avg_net_usage_kbps
    "var.esxi_vm_plex_avg_disk_usage_kbps" = $esxi_vm_plex_avg_disk_usage_kbps
    "var.esxi_vm_deluge_avg_cpu_usage_pct" = $esxi_vm_deluge_avg_cpu_usage_pct
    "var.esxi_vm_deluge_avg_memory_usage_pct" = $esxi_vm_deluge_avg_memory_usage_pct
    "var.esxi_vm_deluge_avg_net_usage_kbps" = $esxi_vm_deluge_avg_net_usage_kbps
    "var.esxi_vm_deluge_avg_disk_usage_kbps" = $esxi_vm_deluge_avg_disk_usage_kbps
    "var.esxi_cpu_usage_mhz" = $esxi_cpu_usage_mhz
    "var.esxi_cpu_total_mhz" = $esxi_cpu_total_mhz
    "var.esxi_memory_usage_mb" = $esxi_memory_usage_mb
    "var.esxi_memory_total_mb" = $esxi_memory_total_mb
    "var.esxi_datastore1_space_free_gb" = $esxi_datastore1_space_free_gb
    "var.esxi_datastore1_space_total_gb" = $esxi_datastore1_space_total_gb
    "var.esxi_datastore2_space_free_gb" = $esxi_datastore2_space_free_gb
    "var.esxi_datastore2_space_total_gb" = $esxi_datastore2_space_total_gb
    "var.esxi_datastore3_space_free_gb" = $esxi_datastore3_space_free_gb
    "var.esxi_datastore3_space_total_gb" = $esxi_datastore3_space_total_gb
    "var.esxi_uptime_total_seconds" = $esxi_uptime_total_seconds
}

#Sending info in above hash table to Home-Assistant
foreach($var_entity in $var_to_ha_hash_table.GetEnumerator())
{

    $var_entity_key = ($var_entity).key
    $var_entity_value = ($var_entity).value

    if ($var_entity_value -eq $null) {$var_entity_value = 0} #set value to zero if empty

    $json_to_send = '{"entity_id":' + '"' +  "$var_entity_key" + '",' + '"value":' + '"' +  "$var_entity_value" + '"' + '}'
    Invoke-HomeAssistantService -service var.set -json $json_to_send
    #Write-Host $json_to_send
    Clear-Variable -Name json_to_send
}

### Update input_text entities in Home-Assistant

#Hash table with entities and values
$input_text_to_ha_hash_table = @{
    "input_text.esxi_vm_admin_server_powerstate" = $esxi_vm_admin_server_powerstate
    "input_text.esxi_vm_home_assistant_powerstate" = "$esxi_vm_home_assistant_powerstate"
    "input_text.esxi_vm_deluge_powerstate" = "$esxi_vm_deluge_powerstate"
    "input_text.esxi_vm_plex_powerstate" = "$esxi_vm_plex_powerstate"
}

# Sending info in above hash table to Home-Assistant
foreach($input_text_entity in $input_text_to_ha_hash_table.GetEnumerator())
{

    $input_text_entity_key = ($input_text_entity).key
    $input_text_entity_value = ($input_text_entity).value

    if ($input_text_entity_value -eq $null) {$input_text_entity_value = 0} #set value to zero if empty

    $json_to_send = '{"entity_id":' + '"' +  "$input_text_entity_key" + '",' + '"value":' + '"' +  "$input_text_entity_value" + '"' + '}'
    Invoke-HomeAssistantService -service input_text.set_value -json $json_to_send
    Clear-Variable -Name json_to_send

}
# End of script #