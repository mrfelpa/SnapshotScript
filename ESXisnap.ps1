
param (
    [Parameter(Mandatory = $true)]
    [string]$vCenterServer,
    [Parameter(Mandatory = $true)]
    [string]$vCenterUsername,
    [Parameter(Mandatory = $true)]
    [string]$vCenterPassword,
    [Parameter(Mandatory = $true)]
    [string]$vmName,
    [Parameter(Mandatory = $true)]
    [string]$xymonServer,
    [string]$xymonPort = "1984",
    [string]$xymonService = "esxi-snapshots",
    [string]$logFilePath = "C:\Logs\SnapshotScript.log"
)

function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

function Connect-To-vCenter {
    try {
        Write-Log "Connecting to vCenter server: $vCenterServer"
        Connect-VIServer -Server $vCenterServer -User $vCenterUsername -Password $vCenterPassword -ErrorAction Stop
        Write-Log "Connected to vCenter server successfully."
    }
    catch {
        Write-Log "Failed to connect to vCenter server: $_"
        throw "Failed to connect to vCenter server: $_"
    }
}

function Disconnect-From-vCenter {
    Write-Log "Disconnecting from vCenter server: $vCenterServer"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    Write-Log "Disconnected from vCenter server."
}

function Get-SnapshotInfo {
    param (
        [string]$vmName
    )
    try {
        Write-Log "Retrieving snapshot information for VM: $vmName"
        $snapshotInfo = Get-Snapshot -VM $vmName -ErrorAction Stop
        Write-Log "Snapshot information retrieved successfully."
        return $snapshotInfo
    }
    catch {
        Write-Log "Failed to retrieve snapshot information for VM: $vmName - $_"
        throw "Failed to retrieve snapshot information for VM: $vmName - $_"
    }
}

function Post-To-Xymon {
    param (
        [string]$hostname,
        [string]$data
    )
    try {
        Write-Log "Posting data to Xymon server: $xymonServer"
        $url = "http://$xymonServer:$xymonPort/$xymonService"
        $postData = @{
            "hostname" = $hostname
            "data" = $data
        }
        Invoke-RestMethod -Uri $url -Method Post -Body $postData -ErrorAction Stop
        Write-Log "Data posted to Xymon server successfully."
    }
    catch {
        Write-Log "Failed to post data to Xymon server: $_"
        throw "Failed to post data to Xymon server: $_"
    }
}

try {
    # Connect to vCenter server
    Connect-To-vCenter
    
    $snapshotInfo = Get-SnapshotInfo -vmName $vmName

    $snapshotData = ""
    foreach ($snapshot in $snapshotInfo) {
        $snapshotData += "Snapshot Name: $($snapshot.Name)`n"
        $snapshotData += "Created: $($snapshot.Created)`n"
        $snapshotData += "Description: $($snapshot.Description)`n"
        $snapshotData += "----------------------`n"
    }

    Post-To-Xymon -hostname $vmName -data $snapshotData

    Write-Log "Script execution completed successfully."
}
catch {
    Write-Log "Error occurred: $_"
}
finally {
    if ($global:DefaultVIServers.Count -gt 0) {
        Disconnect-From-vCenter
    }
}
