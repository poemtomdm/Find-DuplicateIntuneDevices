# Duplicate Device Detection and Cleanup for Intune Managed Devices

This PowerShell script helps administrators identify and clean up duplicate devices in Intune managed environments, specifically for platforms like Windows, Android, iOS, and macOS. It leverages Microsoft Graph API to identify devices that share the same serial number or IMEI, and provides a detailed report on these duplicates, allowing for informed decisions about device removal.

## Goals:
- **Identify Duplicate Devices**: The script identifies duplicate devices based on IMEI (for iOS) or serial number (for Windows, Android, and macOS).
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

### 2. **Generate CSV Report and Delete Devices**

To generate a CSV report of duplicate devices and delete them:

```powershell
.\Find-DuplicateIntuneDevices.ps1 -TenantId "your-tenant-id" -ClientId "your-client-id" -ClientSecret "your-client-secret" -Platform "Android" -CsvOutput -Force
