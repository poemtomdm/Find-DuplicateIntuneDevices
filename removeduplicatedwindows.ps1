# Use a vault to secure register application usage
$global:tenant = "xxxxx"
$global:clientId = "xxxxx"
$global:clientSecret = "xxxx"
$SecuredPasswordPassword = ConvertTo-SecureString -String $clientSecret -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $SecuredPasswordPassword

Connect-MgGraph -TenantId $tenant -ClientSecretCredential $ClientSecretCredential


###################################################################################################################
###################################################################################################################

# Initialize collections
$allDevices = @()
$duplicateDevices = @()
$deviceSerials = @{}

# Initialize the nextLink variable
$nextLink = "https://graph.microsoft.com/beta/devicemanagement/manageddevices?`$filter=operatingsystem eq 'Windows'"

# Fetch all devices
while (![string]::IsNullOrEmpty($nextLink)) { 
    $response = Invoke-MgGraphRequest -Method GET -Uri "$nextLink"
    $allDevices += $response.value  # Add this page's devices
    $nextLink = $response.'@odata.nextLink' # Get the next page's URL
    Write-Host $nextLink
}

# Check for duplicate devices based on serial number, IMEI
# I do two seperate for each loops for safety, as i don't want to parse $alldevices array directly
foreach ($device in $allDevices) {
    $imei = $device.imei
    $serialNumber = $device.serialNumber
    $identifier = $null

    if ($serialNumber -ne $null -and $serialNumber -ne "" -and $serialNumber -ne "serialnumber" -and $serialNumber -ne "0" -and $serialNumber -ne "Defaultstring") {
        $identifier = $serialNumber
    } else {
        continue
    }
    
    if ($identifier -ne $null) {
        if ($deviceSerials.ContainsKey($identifier)) {
            Write-Host "Duplicate found for identifier: $identifier"
            $duplicateDevices += $device
        } else {
            $deviceSerials[$identifier] = $device
        }
    }
}

# I process duplicateDevices instead of alldevices array for safety
foreach ($duplicate in $duplicateDevices) {
    Write-Warning $duplicate.deviceName
    $serial = $duplicate.serialNumber
    $imei = $duplicate.imei
    # If imei is empty, i use the serial number
    if ([string]::IsNullOrEmpty($imei)) {
        $filterValue = $serial
        $filterField = "serialNumber"
    } else {
        $filterValue = $imei
        $filterField = "imei"
    }
    $uri = "https://graph.microsoft.com/beta/devicemanagement/manageddevices?`$filter=$filterField eq '$filterValue'"
    $response = Invoke-MgGraphRequest -uri $uri -Method get
    # Sort duplicated by last sync date and keep the most recent one safe
    $duplicatessorted = $response.value | Sort-Object lastsyncdatetime -Descending | Select-Object -Skip 1
    foreach ($duplicatesorted in $duplicatessorted) {
        $intuneid = $duplicatesorted.id
        $azureaddeviceid = $duplicatesorted.azureADDeviceId
        # Uncomment next line to delete the device
        #Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/devicemanagement/manageddevices/$intuneid" -Method DELETE
        $urientra = "https://graph.microsoft.com/beta/devices?`$filter=deviceid eq '$azureaddeviceid'"
        $request = Invoke-MgGraphRequest -method get -uri $urientra
        $objectid = $request.value.id
        Write-Warning "$intuneid will be deleted in intune, $objectid will be deleted in entra"
        # Uncomment next line to delete the device
        #Invoke-MgGraphRequest -method DELETE -uri "https://graph.microsoft.com/beta/devices/$objectid"
    }
}
