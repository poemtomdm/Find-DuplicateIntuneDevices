# Duplicate Device Detection and Cleanup for Intune Managed Devices

This PowerShell script helps administrators identify and clean up duplicate devices in Intune managed environments, specifically for platforms like Windows, Android, iOS, and macOS. It leverages Microsoft Graph API to identify devices that share the same serial number or IMEI, and provides a detailed report on these duplicates, allowing for informed decisions about device removal.

## Goals:
- **Identify Duplicate Devices**: The script identifies duplicate devices based on IMEI or serial number, depending on the platform.
- **Generate Detailed Reports**: The script generates reports that can be exported in both JSON and CSV formats for easy review.
- **Device Cleanup**: Optionally, the script can delete duplicate devices from Intune and Entra, with confirmation prompts or force deletion for automation.
- **Flexible Use**: Supports multiple platforms (Windows, Android, iOS, macOS) and various reporting options for better management and auditing.

## Features:
- **Platform Support**: Handles device management across multiple platforms (Windows, Android, iOS, macOS).
- **Detailed Reporting**: Outputs detailed information on duplicate devices in either CSV or JSON formats.
- **Flexible Cleanup Options**: Allows for a `-ReportOnly` mode to simulate deletions, as well as a `-Force` option to automatically remove duplicate devices without confirmation.
- **Interactive Prompts**: In case of deletion, users are prompted for confirmation before any device removal occurs.
- **Microsoft Graph Integration**: Utilizes Microsoft Graph API for real-time device management and deletion.

## Example Usages:

### 1. **Run in Report-Only Mode (Simulate Deletions)**

To identify duplicate devices and generate a report in JSON format without performing any deletions:

```powershell
.\Find-DuplicateIntuneDevices.ps1 -TenantId "your-tenant-id" -ClientId "your-client-id" -ClientSecret "your-client-secret" -Platform "Windows" -ReportOnly -JsonOutput
```
This command will fetch Windows devices from Intune, check for duplicates based on serial number, and generate a JSON report of the duplicate devices without deleting them.

### 2. **Generate CSV Report and Delete Devices**

To generate a CSV report of duplicate devices and delete them:

```powershell
.\Find-DuplicateIntuneDevices.ps1 -TenantId "your-tenant-id" -ClientId "your-client-id" -ClientSecret "your-client-secret" -Platform "Android" -CsvOutput -Force
```

This will fetch Android devices from Intune, identify duplicates, generate a CSV report, and automatically delete the duplicates without needing confirmation.

### 3. Force Deletion with Confirmation

If you want to review the devices before deletion, run the script without -Force, and you'll be prompted to confirm deletion:

```powershell
.\Find-DuplicateIntuneDevices.ps1 -TenantId "your-tenant-id" -ClientId "your-client-id" -ClientSecret "your-client-secret" -Platform "macOS"
```


This will list the macOS duplicate devices and ask if you want to delete them.

## Prerequisites:

PowerShell: The script requires PowerShell to be installed.

Microsoft Graph API: The script uses Microsoft Graph API for device management, so a valid TenantId, ClientId, and ClientSecret for accessing the API are required.

Permissions: The necessary permissions to read and delete devices from Intune and Entra are needed. Ensure that your service principal has the required access rights.


## How it works:
- **Authentication**: Handles device management across multiple platforms (Windows, Android, iOS, macOS).
- **Fetching Devices**: Outputs detailed information on duplicate devices in either CSV or JSON formats.
- **Identifying Duplicates**: Allows for a `-ReportOnly` mode to simulate deletions, as well as a `-Force` option to automatically remove duplicate devices without confirmation.
- **Generating Reports**: In case of deletion, users are prompted for confirmation before any device removal occurs.
- **Cleanup Option**: Utilizes Microsoft Graph API for real-time device management and deletion.

## Customization:
You can modify the script to adjust the device identification logic (e.g., add more fields), change how the duplicates are processed, or customize the reporting format.

## Contributing:
Feel free to fork the repository, submit issues, and create pull requests. Contributions to improve the script or add new features are always welcome!

## License:
This project is licensed under the MIT License

## Disclaimer:
Use at your own risk. This script is provided "as-is" without any warranty of any kind, either express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, or non-infringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the script or the use or other dealings in the script.

Before running this script in a production environment, test in a non-production environment to avoid potential issues.

