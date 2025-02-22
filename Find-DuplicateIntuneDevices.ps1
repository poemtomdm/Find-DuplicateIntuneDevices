param (
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientSecret,
    [ValidateSet("Windows", "Android", "iOS", "macOS")]
    [string]$Platform,
    [switch]$ReportOnly,
    [switch]$JsonOutput,
    [switch]$CsvOutput,
    [switch]$Force
)

# Authenticate with Microsoft Graph
$SecuredPasswordPassword = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecuredPasswordPassword
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome

# Initialize collections
$allDevices = @()
$duplicateDevices = @()
$result = @()
$deviceIdentifiers = @{}

# API Endpoint based on platform
$nextLink = "https://graph.microsoft.com/beta/devicemanagement/manageddevices?`$filter=operatingsystem eq '$Platform'"

Write-Host "Getting all $Platform devices. Please wait..." -ForegroundColor Yellow
# Fetch all devices
while (![string]::IsNullOrEmpty($nextLink)) {
    $response = Invoke-MgGraphRequest -Method GET -Uri $nextLink
    $allDevices += $response.value
    $nextLink = $response.'@odata.nextLink'
}

write-host "Found $($allDevices.Count) $Platform devices." -ForegroundColor Green

# Identify duplicates based on IMEI or Serial Number
foreach ($device in $allDevices) {
    $imei = $device.imei
    $serialNumber = $device.serialNumber
    $identifier = $null

    if ($Platform -eq "Windows" -or $Platform -eq "macOS") {
        if ($serialNumber -ne $null -and $serialNumber -ne "" -and $serialNumber -ne "serialnumber" -and $serialNumber -ne "0" -and $serialNumber -ne "Defaultstring") {
            $identifier = $serialNumber
        }
    } elseif ($Platform -eq "iOS" -or $Platform -eq "Android") {
        if ($imei -ne $null -and $imei -ne "") {
            $identifier = $imei
        } elseif ($serialNumber -ne $null -and $serialNumber -ne "" -and $serialNumber -ne "0" -and $serialNumber -ne "serialnumber") {
            $identifier = $serialNumber
        }
    }

    if ($identifier -ne $null) {
        if ($deviceIdentifiers.ContainsKey($identifier)) {
            $duplicateDevices += $device
        } else {
            $deviceIdentifiers[$identifier] = $device
        }
    }
}

# Process duplicates
foreach ($duplicate in $duplicateDevices) {
    $serial = $duplicate.serialNumber
    $imei = $duplicate.imei
    $filterValue = if ([string]::IsNullOrEmpty($imei)) { $serial } else { $imei }
    $filterField = if ([string]::IsNullOrEmpty($imei)) { "serialNumber" } else { "imei" }

    $uri = "https://graph.microsoft.com/beta/devicemanagement/manageddevices?`$filter=$filterField eq '$filterValue'"
    $response = Invoke-MgGraphRequest -Uri $uri -Method GET

    # Sort duplicates by last sync date and skip the most recent one
    $duplicatessorted = $response.value | Sort-Object lastsyncdatetime -Descending | Select-Object -Skip 1

    foreach ($duplicatesorted in $duplicatessorted) {
        $result += [PSCustomObject]@{
            DeviceName     = $duplicatesorted.deviceName
            IntuneID       = $duplicatesorted.id
            EntraObjectID  = $duplicatesorted.azureADDeviceId
        }
    }
}

write-host "Found $($result.Count) duplicate $Platform devices." -ForegroundColor Yellow

# Output results
if ($result.Count -gt 0) {
    if ($JsonOutput) {
        # Export results to JSON format
        $result | ConvertTo-Json -Depth 3
    } elseif ($CsvOutput) {
        # Export the results to a CSV file
        $csvPath = "DuplicateDevicesReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $result | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Report exported to $csvPath" -ForegroundColor Green
    } else {
        # Output to the console
        $result | ForEach-Object {
            $message = if ($ReportOnly) {
                "Would delete {0}. Intune ID: {1}. Entra object: {2}" -f $_.DeviceName, $_.IntuneID, $_.EntraObjectID
            } else {
                "Device {0}. Intune ID: {1}. Entra object: {2}" -f $_.DeviceName, $_.IntuneID, $_.EntraObjectID
            }
            Write-Host $message -ForegroundColor Yellow
        }
    }

    if (-not $ReportOnly -and -not $Force) {
        # Ask for confirmation before deleting
        $confirmation = read-host "Do you want to delete these $($result.Count) devices? [Y/N]"
        if ($confirmation -match "^[Yy]$") {
            # Perform deletion for each device
            foreach ($duplicatesorted in $result) {
                Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/devicemanagement/manageddevices/$($duplicatesorted.IntuneID)" -Method DELETE

                $uriEntra = "https://graph.microsoft.com/beta/devices?`$filter=deviceid eq '$($duplicatesorted.EntraObjectID)'"
                $request = Invoke-MgGraphRequest -Method GET -Uri $uriEntra
                $objectId = $request.value.id

                Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/devices/$objectId"

                Write-Host "Deleted device: $($duplicatesorted.DeviceName). Intune ID: $($duplicatesorted.IntuneID). Entra Object ID: $($duplicatesorted.EntraObjectID)" -ForegroundColor Green
            }
        } else {
            Write-Host "No devices were deleted." -ForegroundColor Red
        }
    } elseif ($Force) {
        # Directly delete all devices without confirmation
        foreach ($duplicatesorted in $result) {
            Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/devicemanagement/manageddevices/$($duplicatesorted.IntuneID)" -Method DELETE

            $uriEntra = "https://graph.microsoft.com/beta/devices?`$filter=deviceid eq '$($duplicatesorted.EntraObjectID)'"
            $request = Invoke-MgGraphRequest -Method GET -Uri $uriEntra
            $objectId = $request.value.id

            Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/devices/$objectId"

            Write-Host "Deleted device: $($duplicatesorted.DeviceName). Intune ID: $($duplicatesorted.IntuneID). Entra Object ID: $($duplicatesorted.EntraObjectID)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "No duplicate devices found." -ForegroundColor Green
}
