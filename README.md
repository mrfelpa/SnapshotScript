
# Main Features

- Connection to vCenter server.
- Retrieval of snapshot information for a specified VM.
- Formatting of snapshot data.
- Sending the formatted data to the Xymon server.

# Instructions for Use

- Clone or download this repository to your local environment.
- Open a PowerShell terminal.
- Navigate to the directory where the script is located.
- Run the ESXisnap.ps1 script with the following parameters:
  
        .\ESXisnapscript.ps1 -vCenterServer "your_server_vcenter" -vCenterUsername "your_user_vcenter" -vCenterPassword "your_password_vcenter" -vmName "name_of_vm" -xymonServer "your_server_xymon"

# Logs
- The script generates logs to track execution and any errors encountered during the process.
- The default log ***file path is C: Logs SnapshotScript.log,*** but you can modify this path if you need.
