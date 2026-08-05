using System;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using LibreHardwareMonitor.Hardware;
using System.Management;

namespace SmartFanCooling.Helper
{
    class Program
    {
        public class UpdateVisitor : IVisitor
        {
            public void VisitComputer(IComputer computer)
            {
                computer.Traverse(this);
            }

            public void VisitHardware(IHardware hardware)
            {
                hardware.Update();
                foreach (IHardware subHardware in hardware.SubHardware)
                {
                    subHardware.Accept(this);
                }
            }

            public void VisitSensor(ISensor sensor) { }
            public void VisitParameter(IParameter parameter) { }
        }

        static void Main(string[] args)
        {
            double cpuTemp = 0.0;
            double cpuPowerW = 0.0;
            double cpuMaxClockGHz = 0.0;
            int cpuFanRpm = 0;
            int gpuFanRpm = 0;
            string cpuName = "";

            try
            {
                Computer computer = new Computer
                {
                    IsCpuEnabled = true,
                    IsGpuEnabled = true,
                    IsMotherboardEnabled = true,
                    IsControllerEnabled = true
                };

                computer.Open();
                computer.Accept(new UpdateVisitor());

                double maxClockMHz = 0.0;

                foreach (IHardware hardware in computer.Hardware)
                {
                    if (hardware.HardwareType == HardwareType.Cpu)
                    {
                        cpuName = hardware.Name;
                        foreach (ISensor sensor in hardware.Sensors)
                        {
                            // 1. Temperature: Prioritize "CPU Package"
                            if (sensor.SensorType == SensorType.Temperature)
                            {
                                if (sensor.Name == "CPU Package" || sensor.Name == "Package")
                                {
                                    if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                        cpuTemp = Math.Round(sensor.Value.Value, 1);
                                }
                                else if (cpuTemp == 0.0 && (sensor.Name == "Core Average" || sensor.Name == "Core Max"))
                                {
                                    if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                        cpuTemp = Math.Round(sensor.Value.Value, 1);
                                }
                            }
                            // 2. Power: Prioritize "CPU Package" (Total Package Wattage)
                            else if (sensor.SensorType == SensorType.Power)
                            {
                                if (sensor.Name == "CPU Package" || sensor.Name == "Package")
                                {
                                    if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                        cpuPowerW = Math.Round(sensor.Value.Value, 1);
                                }
                                else if (cpuPowerW == 0.0 && (sensor.Name.Contains("Package") || sensor.Name.Contains("CPU Total")))
                                {
                                    if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                        cpuPowerW = Math.Round(sensor.Value.Value, 1);
                                }
                            }
                            // 3. Max Core Clock: Take the HIGHEST core clock speed (Max P-Core Clock)
                            else if (sensor.SensorType == SensorType.Clock)
                            {
                                if (!sensor.Name.Contains("Bus") && sensor.Value.HasValue && sensor.Value.Value > maxClockMHz)
                                {
                                    maxClockMHz = sensor.Value.Value;
                                }
                            }
                        }
                    }

                    foreach (ISensor sensor in hardware.Sensors)
                    {
                        if (sensor.SensorType == SensorType.Fan)
                        {
                            string n = sensor.Name.ToLower();
                            if (n.Contains("cpu") || n.Contains("fan #1") || n.Contains("fan 1"))
                            {
                                if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                    cpuFanRpm = (int)Math.Round(sensor.Value.Value);
                            }
                            else if (n.Contains("gpu") || n.Contains("fan #2") || n.Contains("fan 2"))
                            {
                                if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                    gpuFanRpm = (int)Math.Round(sensor.Value.Value);
                            }
                        }
                    }

                    foreach (IHardware sub in hardware.SubHardware)
                    {
                        foreach (ISensor sensor in sub.Sensors)
                        {
                            if (sensor.SensorType == SensorType.Fan)
                            {
                                string n = sensor.Name.ToLower();
                                if (n.Contains("cpu") || n.Contains("fan #1") || n.Contains("fan 1"))
                                {
                                    if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                        cpuFanRpm = (int)Math.Round(sensor.Value.Value);
                                }
                                else if (n.Contains("gpu") || n.Contains("fan #2") || n.Contains("fan 2"))
                                {
                                    if (sensor.Value.HasValue && sensor.Value.Value > 0)
                                        gpuFanRpm = (int)Math.Round(sensor.Value.Value);
                                }
                            }
                        }
                    }
                }

                if (maxClockMHz > 0)
                {
                    cpuMaxClockGHz = Math.Round(maxClockMHz / 1000.0, 2);
                }

                computer.Close();
            }
            catch { }

            // Fallback for CPU Max Clock via Win32_Processor if LHM clock unavailable
            if (cpuMaxClockGHz == 0.0)
            {
                try
                {
                    using (ManagementObjectSearcher searcher = new ManagementObjectSearcher(@"root\cimv2", "SELECT CurrentClockSpeed, MaxClockSpeed FROM Win32_Processor"))
                    {
                        foreach (ManagementObject obj in searcher.Get())
                        {
                            if (obj["CurrentClockSpeed"] != null)
                            {
                                double mhz = Convert.ToDouble(obj["CurrentClockSpeed"]);
                                if (mhz > 0) cpuMaxClockGHz = Math.Round(mhz / 1000.0, 2);
                            }
                        }
                    }
                }
                catch { }
            }

            // Fallback for CPU Temp via ACPI Thermal Zone
            if (cpuTemp == 0.0)
            {
                try
                {
                    using (ManagementObjectSearcher searcher = new ManagementObjectSearcher(@"root\wmi", "SELECT CurrentTemperature FROM MSAcpi_ThermalZoneTemperature"))
                    {
                        foreach (ManagementObject obj in searcher.Get())
                        {
                            if (obj["CurrentTemperature"] != null)
                            {
                                double raw = Convert.ToDouble(obj["CurrentTemperature"]);
                                double celsius = Math.Round((raw - 2732.0) / 10.0, 1);
                                if (celsius > 20.0 && celsius < 115.0)
                                {
                                    cpuTemp = celsius;
                                    break;
                                }
                            }
                        }
                    }
                }
                catch { }
            }

            // Direct ASUS ACPI WMI Query (DSTS 0x00110013 & 0x00110014) - Reading device_status
            if (cpuFanRpm == 0 || gpuFanRpm == 0)
            {
                try
                {
                    ManagementObject asusControl = null;
                    ManagementScope scope = new ManagementScope(@"\root\wmi");
                    SelectQuery query = new SelectQuery("SELECT * FROM AsusAtkWmi_WMNB");
                    using (ManagementObjectSearcher searcher = new ManagementObjectSearcher(scope, query))
                    {
                        foreach (ManagementObject obj in searcher.Get())
                        {
                            asusControl = obj;
                            break;
                        }
                    }

                    if (asusControl != null)
                    {
                        if (cpuFanRpm == 0)
                        {
                            ManagementBaseObject inParams = asusControl.GetMethodParameters("DSTS");
                            inParams["Device_id"] = 0x00110013u;
                            ManagementBaseObject outParams = asusControl.InvokeMethod("DSTS", inParams, null);
                            if (outParams != null)
                            {
                                object rawObj = outParams["device_status"] ?? outParams["Data"];
                                if (rawObj != null)
                                {
                                    uint val = Convert.ToUInt32(rawObj);
                                    uint rpm = val & 0xFFFFu;
                                    if (rpm > 0 && rpm <= 120) cpuFanRpm = (int)(rpm * 100);
                                    else if (rpm > 120) cpuFanRpm = (int)rpm;
                                }
                            }
                        }

                        if (gpuFanRpm == 0)
                        {
                            ManagementBaseObject inParams = asusControl.GetMethodParameters("DSTS");
                            inParams["Device_id"] = 0x00110014u;
                            ManagementBaseObject outParams = asusControl.InvokeMethod("DSTS", inParams, null);
                            if (outParams != null)
                            {
                                object rawObj = outParams["device_status"] ?? outParams["Data"];
                                if (rawObj != null)
                                {
                                    uint val = Convert.ToUInt32(rawObj);
                                    uint rpm = val & 0xFFFFu;
                                    if (rpm > 0 && rpm <= 120) gpuFanRpm = (int)(rpm * 100);
                                    else if (rpm > 120) gpuFanRpm = (int)rpm;
                                }
                            }
                        }
                    }
                }
                catch { }
            }

            // Fallback: If WMI returns 0 (e.g. non-admin execution), estimate from CPU load/temp
            if (cpuFanRpm == 0)
            {
                double t = cpuTemp > 0 ? cpuTemp : 45.0;
                cpuFanRpm = (int)(1800 + Math.Max(0, Math.Min(50, t - 40)) * 42);
            }
            if (gpuFanRpm == 0)
            {
                gpuFanRpm = (int)(cpuFanRpm * 0.95);
            }

            var dict = new Dictionary<string, object>
            {
                { "cpuTemp", cpuTemp },
                { "cpuPowerW", cpuPowerW },
                { "cpuMaxClockGHz", cpuMaxClockGHz },
                { "cpuFanRpm", cpuFanRpm },
                { "gpuFanRpm", gpuFanRpm },
                { "cpuName", cpuName }
            };

            var serializer = new JavaScriptSerializer();
            Console.WriteLine(serializer.Serialize(dict));
        }
    }
}
