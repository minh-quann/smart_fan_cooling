# Test script to find exact ASUS Fan WMI endpoints and values
$log = "$PSScriptRoot\wmi_fan_debug.txt"
"=== DEBUG ASUS WMI FANS ===" | Set-Content -Path $log -Encoding UTF8

try {
    $wmi = Get-CimInstance -Namespace root/wmi -ClassName AsusAtkWmi_WMNB -ErrorAction Stop | Select-Object -First 1
    "Instance: $($wmi.InstanceName)" | Add-Content -Path $log

    # 1. Test DSTS on 0x00110013, 0x00110014, 0x00110031
    $devices = @(0x00110013, 0x00110014, 0x00110031, 0x00110022, 0x00110023)
    foreach ($dev in $devices) {
        $idHex = "0x{0:X8}" -f $dev
        try {
            $res = Invoke-CimMethod -InputObject $wmi -MethodName DSTS -Arguments @{Device_id = $dev}
            "DSTS $idHex -> Data = $($res.Data)" | Add-Content -Path $log
        } catch {
            "DSTS $idHex -> ERROR: $($_.Exception.Message)" | Add-Content -Path $log
        }
    }

    # 2. Test DEVS on 0x00110013, 0x00110014
    foreach ($dev in $devices) {
        $idHex = "0x{0:X8}" -f $dev
        try {
            $res = Invoke-CimMethod -InputObject $wmi -MethodName DEVS -Arguments @{Device_id = $dev}
            "DEVS $idHex -> Data = $($res.Data)" | Add-Content -Path $log
        } catch {
            "DEVS $idHex -> ERROR: $($_.Exception.Message)" | Add-Content -Path $log
        }
    }

    # 3. Check thermal zones in root/wmi
    $tzs = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    foreach ($tz in $tzs) {
        "Thermal Zone $($tz.InstanceName): CurrentTemp = $($tz.CurrentTemperature)" | Add-Content -Path $log
    }

} catch {
    "FATAL ERROR: $($_.Exception.Message)" | Add-Content -Path $log
}
