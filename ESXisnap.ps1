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
        [string]$message,
        [ValidateSet("Info", "Error")]
        [string]$logLevel = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $logLevel: $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

function Connect-To-vCenter {
    try {
        Write-Log "Connecting to vCenter server: $vCenterServer" -logLevel "Info"
        Connect-VIServer -Server $vCenterServer -User $vCenterUsername -Password $vCenterPassword -ErrorAction Stop
        Write-Log "Connected to vCenter server successfully." -logLevel "Info"
    }
    catch {
        Write-Log "Failed to connect to vCenter server: $_" -logLevel "Error"
        throw "Failed to connect to vCenter server: $_"
    }
}

function Disconnect-From-vCenter {
    Write-Log "Disconnecting from vCenter server: $vCenterServer" -logLevel "Info"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    Write-Log "Disconnected from vCenter server." -logLevel "Info"
}

function Get-SnapshotInfo {
    param (
        [string]$vmName
    )
    try {
        Write-Log "Retrieving snapshot information for VM: $vmName" -logLevel "Info"
        if ($vmName -eq "") {
            Write-Log "Invalid VM name. Please provide a valid VM name." -logLevel "Error"
            return
        }
        $snapshotInfo = Get-Snapshot -VM $vmName -ErrorAction Stop
        Write-Log "Snapshot information retrieved successfully." -logLevel "Info"
        return $snapshotInfo
    }
    catch {
        Write-Log "Failed to retrieve snapshot information for VM: $vmName - $_" -logLevel "Error"
        throw "Failed to retrieve snapshot information for VM: $vmName - $_"
    }
}

function Post-To-Xymon {
    param (
        [string]$hostname,
        [string]$data
    )
    try {
        Write-Log "Posting data to Xymon server: $xymonServer" -logLevel "Info"
        if ($hostname -eq "" -or $data -eq "") {
            Write-Log "Invalid hostname or data. Please provide valid values." -logLevel "Error"
            return
        }
        $url = "http://$xymonServer:$xymonPort/$xymonService"
        $postData = @{
            "hostname" = $hostname
            "data" = $data
        }
        Invoke-RestMethod -Uri $url -Method Post -Body $postData -ErrorAction Stop
        Write-Log "Data posted to Xymon server successfully." -logLevel "Info"
    }
    catch {
        Write-Log "Failed to post data to Xymon server: $_" -logLevel "Error"
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

    Write-Log "Script execution completed successfully." -logLevel "Info"
}
catch {
    Write-Log "Error occurred: $_" -logLevel "Error"
}
finally {
    if ($global:DefaultVIServers.Count -gt 0) {
        Disconnect-From-vCenter
    }
}
