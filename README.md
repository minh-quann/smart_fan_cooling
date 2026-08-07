# 🌀 Smart Fan Cooling System

> **Hệ thống điều khiển và giám sát quạt tản nhiệt thông minh cho Laptop / PC sử dụng ESP32-S3 & Flutter.**

---

## 📌 Giới Thiệu

**Smart Fan Cooling System** là một giải pháp toàn diện bao gồm **Phần cứng + Firmware ESP32-S3 + Ứng dụng điều khiển đa nền tảng (Flutter)** giúp quản lý nhiệt độ laptop/máy tính, tự động điều chỉnh tốc độ quạt (PWM), hiển thị trạng thái trên màn hình OLED kép, cùng các hiệu ứng LED RGB WS2812B mắt đẹp.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![ESP32-S3](https://img.shields.io/badge/ESP32--S3-E7352C?style=for-the-badge&logo=espressif&logoColor=white)
![PlatformIO](https://img.shields.io/badge/PlatformIO-272727?style=for-the-badge&logo=platformio&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![C++](https://img.shields.io/badge/C++-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)

---

## 🚀 Tính Năng Nổi Bật

- **⚙️ Điều tốc PWM 25kHz & Đọc RPM chính xác:**
  - Phát xung PWM tần số chuẩn 25kHz bằng ESP32-S3 qua module Dual MOSFET (HW-517).
  - Đọc xung đếm vòng quay TACH (RPM) thông qua module Opto cách ly PC817 an toàn tuyệt đối cho vi điều khiển.

- **🖥️ Giao diện Dual OLED (Dual Display):**
  - **Màn chính 1.3" I2C1:** Hiển thị nhiệt độ Laptop/CPU/GPU, tốc độ quạt (RPM & % PWM), Chế độ LED.
  - **Màn phụ 0.96" I2C2:** Hiển thị thông số phụ, trạng thái kết nối mạng & BLE.

- **🎛️ Thao tác vật lý bằng Con Lăn Encoder & Nút bấm:**
  - Xoay núm Encoder để chỉnh tốc độ quạt từ 0-100%.
  - Bật/Tắt nhanh quạt, chuyển đổi chế độ LED bằng các nút bấm tích hợp (`PSH`, `CON`, `BAK`).

- **🌈 Hiệu ứng LED RGB WS2812B:**
  - Tích hợp thư viện FastLED với nhiều hiệu ứng ánh sáng (Static, Breathing, Rainbow, Speed Pulse,...).

- **📡 Kết Nối Đa Dạng (Multi-Protocol):**
  - **BLE (Bluetooth Low Energy):** Kết nối không dây năng lượng thấp trực tiếp với điện thoại hoặc PC.
  - **Wi-Fi / WebSocket:** Gửi dữ liệu telemetry real-time và nhận lệnh từ xa.
  - **USB Serial Port:** Giao tiếp dây cáp với PC độ tin cậy cao.

- **📱 App Điều Khuển Đa Nền Tảng (Flutter):**
  - Hỗ trợ Windows, Android, Linux, macOS.
  - Tích hợp công cụ giám sát phần cứng **LibreHardwareMonitor (C# Helper / PowerShell)** để tự động truyền nhiệt độ CPU/GPU từ PC sang ESP32-S3 điều chỉnh quạt theo tải hệ thống.

---

## 🛠️ Danh Sách Linh Kiện Phần Cứng

1. **Board điều khiển:** YD-ESP32-S3 (N16R8) + Mạch đến mở rộng 44-Pin Terminal Adapter.
2. **Bộ nguồn:** Nguồn 12V / 3A Adapter Llano + Mạch hạ áp **XY3606** (12V → 5.2V / 5A).
3. **Mạch công suất & Cách ly:** Module Dual MOSFET (HW-517) + Opto PC817.
4. **Hiển thị & Thao tác:** Màn hình OLED 1.3" (I2C1), OLED 0.96" (I2C2), Con lăn Rotary Encoder, Dải LED RGB WS2812B.

👉 **Xem sơ đồ đấu nối 31 dây chi tiết tại:** [WIRING_GUIDE.md](file:///home/quan/Documents/smart_fan_cooling/WIRING_GUIDE.md)  
👉 **Sơ đồ tương tác HTML:** [wiring_diagram_dual_power.html](file:///home/quan/Documents/smart_fan_cooling/wiring_diagram_dual_power.html)

---

## 📁 Cấu Trúc Thư Mục Project

```text
smart_fan_cooling/
├── lib/                             # Mã nguồn ứng dụng Flutter (App)
│   ├── core/                        # Theme, Constants, Utils, Servcies
│   ├── features/                    # Các màn hình, BLoC state management
│   └── shared/                      # Các Widget dùng chung (AppText, Buttons,...)
├── firmware/                        # Mã nguồn Firmware ESP32-S3
│   └── smart_fan_firmware/
│       ├── platformio.ini           # Cấu hình PlatformIO
│       ├── smart_fan_firmware.ino   # Main Firmware Entry
│       ├── fan_controller.cpp/.h    # Điều khiển PWM & Đọc RPM
│       ├── ble_service.cpp/.h       # Dịch vụ BLE Bluetooth
│       ├── wifi_service.cpp/.h      # Dịch vụ Wi-Fi & WebSocket
│       ├── usb_serial_service.cpp/.h# Giao tiếp USB Serial
│       ├── oled_display.cpp/.h      # Hiển thị Dual OLED
│       ├── encoder_input.cpp/.h     # Đọc núm xoay Encoder & Buttons
│       └── led_effects.cpp/.h       # Điều khiển dải LED WS2812B
├── HardwareHelper.cs                # Công cụ C# đọc nhiệt độ LibreHardwareMonitor trên Windows
├── read_sensors.ps1                 # Script PowerShell đọc thông số phần cứng
├── WIRING_GUIDE.md                  # Hướng dẫn đấu nối phần cứng chi tiết 31 dây
└── README.md                        # Tài liệu hướng dẫn sử dụng dự án
```

---

## ⚡ Hướng Dẫn Cài Đặt & Sử Dụng

### 1. Nạp Firmware Cho ESP32-S3
1. Mở thư mục `firmware/smart_fan_firmware` bằng **VS Code + Extension PlatformIO** (hoặc Arduino IDE).
2. Kiểm tra khai báo chân cắm trong file `config.h`.
3. Nhấn **Build & Upload** để nạp firmware vào bo mạch YD-ESP32-S3 qua cổng USB Serial.

### 2. Chạy Ứng Dụng Flutter
 Cài đặt môi trường Flutter (SDK ^3.12.0) và chạy các lệnh:
```bash
# Lấy các thư viện phụ thuộc
flutter pub get

# Chạy ứng dụng trên thiết bị (Windows / Android / Linux)
flutter run
```

### 3. Đọc Nhiệt Độ Laptop (Trên Windows)
Để ứng dụng đọc được nhiệt độ CPU/GPU real-time từ Laptop và gửi đến ESP32-S3:
- Biên dịch và chạy `HardwareHelper.cs` (yêu cầu LibreHardwareMonitorLib.dll) hoặc chạy script PowerShell `read_sensors.ps1`.

---

## 📜 Giấy Phép & Đóng Góp

Dự án phát triển cho mục đích cá nhân & thử nghiệm giải pháp tản nhiệt thông minh. Mọi ý kiến đóng góp và Pull Request luôn được hoan nghênh!
