param(
    [string]$LhmDllPath = "$PSScriptRoot\lhm\LibreHardwareMonitorLib.dll"
)

try {
    $hidDll = Join-Path (Split-Path $LhmDllPath) "HidSharp.dll"
    if (Test-Path $hidDll) { [System.Reflection.Assembly]::LoadFile($hidDll) | Out-Null }
    [System.Reflection.Assembly]::LoadFile($LhmDllPath) | Out-Null

    $computer = New-Object LibreHardwareMonitor.Hardware.Computer
    $computer.IsCpuEnabled = $true
    $computer.IsGpuEnabled = $true
    $computer.IsMotherboardEnabled = $true
    $computer.IsControllerEnabled = $true
    $computer.Open()

    function Update-Hardware($hw) {
        $hw.Update()
        foreach ($sub in $hw.SubHardware) {
            Update-Hardware $sub
        }
    }

    foreach ($hw in $computer.Hardware) {
        Update-Hardware $hw
    }

    $cpuTemp = 0.0
    $cpuPowerW = 0.0
    $cpuFanRpm = 0
    $gpuFanRpm = 0

    foreach ($hw in $computer.Hardware) {
        if ($hw.HardwareType -eq [LibreHardwareMonitor.Hardware.HardwareType]::Cpu) {
            foreach ($sensor in $hw.Sensors) {
                # 1. Temperature: Prioritize CPU Package > Core Average > Core Max
                if ($sensor.SensorType -eq [LibreHardwareMonitor.Hardware.SensorType]::Temperature) {
                    if ($sensor.Name -eq "CPU Package" -or $sensor.Name -eq "Package") {
                        if ($sensor.Value -and $sensor.Value -gt 0) {
                            $cpuTemp = [math]::Round($sensor.Value, 1)
                        }
                    } elseif ($cpuTemp -eq 0.0 -and ($sensor.Name -eq "Core Average" -or $sensor.Name -eq "Core Max")) {
                        if ($sensor.Value -and $sensor.Value -gt 0) {
                            $cpuTemp = [math]::Round($sensor.Value, 1)
                        }
                    }
                } 
                # 2. Power: Prioritize CPU Package (Total Wattage) instead of CPU Cores (0.3W)
                elseif ($sensor.SensorType -eq [LibreHardwareMonitor.Hardware.SensorType]::Power) {
                    if ($sensor.Name -eq "CPU Package" -or $sensor.Name -eq "Package") {
                        if ($sensor.Value -and $sensor.Value -gt 0) {
                            $cpuPowerW = [math]::Round($sensor.Value, 1)
                        }
                    } elseif ($cpuPowerW -eq 0.0 -and ($sensor.Name -like "*Package*" -or $sensor.Name -like "*CPU Total*")) {
                        if ($sensor.Value -and $sensor.Value -gt 0) {
                            $cpuPowerW = [math]::Round($sensor.Value, 1)
                        }
                    }
                }
            }
        }

        # 3. Fan Speeds: Scan Motherboard, Controller, and SubHardware
        foreach ($sensor in $hw.Sensors) {
            if ($sensor.SensorType -eq [LibreHardwareMonitor.Hardware.SensorType]::Fan) {
                if ($sensor.Name -like "*CPU*" -or $sensor.Name -like "*Fan #1*" -or $sensor.Name -like "*Fan 1*") {
                    if ($sensor.Value -and $sensor.Value -gt 0) {
                        $cpuFanRpm = [math]::Round($sensor.Value)
                    }
                } elseif ($sensor.Name -like "*GPU*" -or $sensor.Name -like "*Fan #2*" -or $sensor.Name -like "*Fan 2*") {
                    if ($sensor.Value -and $sensor.Value -gt 0) {
                        $gpuFanRpm = [math]::Round($sensor.Value)
                    }
                }
            }
        }

        foreach ($sub in $hw.SubHardware) {
            foreach ($sensor in $sub.Sensors) {
                if ($sensor.SensorType -eq [LibreHardwareMonitor.Hardware.SensorType]::Fan) {
                    if ($sensor.Name -like "*CPU*" -or $sensor.Name -like "*Fan #1*" -or $sensor.Name -like "*Fan 1*") {
                        if ($sensor.Value -and $sensor.Value -gt 0) {
                            $cpuFanRpm = [math]::Round($sensor.Value)
                        }
                    } elseif ($sensor.Name -like "*GPU*" -or $sensor.Name -like "*Fan #2*" -or $sensor.Name -like "*Fan 2*") {
                        if ($sensor.Value -and $sensor.Value -gt 0) {
                            $gpuFanRpm = [math]::Round($sensor.Value)
                        }
                    }
                }
            }
        }
    }

    $computer.Close()

    # 4. Direct ASUS ROG WMI Query (AsusAtkWmi_WMNB) for CPU & GPU Fans
    if ($cpuFanRpm -eq 0 -or $gpuFanRpm -eq 0) {
        try {
            $asusWmi = Get-CimInstance -Namespace root/wmi -ClassName AsusAtkWmi_WMNB -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($asusWmi) {
                if ($cpuFanRpm -eq 0) {
                    $cRes = Invoke-CimMethod -InputObject $asusWmi -MethodName DEVS -Arguments @{Device_id = 0x00110013} -ErrorAction SilentlyContinue
                    if ($cRes -and $cRes.Data -gt 0) {
                        $v = [int]($cRes.Data -band 0xFFFF)
                        if ($v -gt 0 -and $v -lt 100) { $cpuFanRpm = $v * 100 } elseif ($v -ge 100) { $cpuFanRpm = $v }
                    }
                }
                if ($gpuFanRpm -eq 0) {
                    $gRes = Invoke-CimMethod -InputObject $asusWmi -MethodName DEVS -Arguments @{Device_id = 0x00110014} -ErrorAction SilentlyContinue
                    if ($gRes -and $gRes.Data -gt 0) {
                        $vG = [int]($gRes.Data -band 0xFFFF)
                        if ($vG -gt 0 -and $vG -lt 100) { $gpuFanRpm = $vG * 100 } elseif ($vG -ge 100) { $gpuFanRpm = $vG }
                    }
                }
            }
        } catch {}
    }

    $result = @{
        cpuTemp = $cpuTemp
        cpuPowerW = $cpuPowerW
        cpuFanRpm = $cpuFanRpm
        gpuFanRpm = $gpuFanRpm
    }

    Write-Output ($result | ConvertTo-Json -Compress)
} catch {
    Write-Output (@{ error = $_.Exception.Message } | ConvertTo-Json -Compress)
}
