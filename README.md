<p align="center">
  <a href="https://gitcode.com/gcw_rVSV2mp6/envSensor">
    <img src="./img/logo.png" alt="Logo" width="80" height="80" style="border: 1px solid #DCDCDC; border-radius: 20px;">
  </a>

  <h3 align="center">Environmental Monitoring System Host Application</h3>
  <p align="center">
   A HarmonyOS-based host application for Bluetooth environmental monitoring systems
    <br />
    <br />
    <a href="https://gitcode.com/gcw_rVSV2mp6/envSensor/issues">Report Bug</a>
    ·
    <a href="https://gitcode.com/gcw_rVSV2mp6/envSensor/issues">Request Feature</a>
  </p>

## Project Introduction (This document is AI-generated)

Environmental Monitoring System Host Application is a Bluetooth client application running on HarmonyOS, designed to connect to Bluetooth environmental sensor devices such as ESP32, receiving and displaying environmental data in real-time.

Data is transmitted via a custom binary protocol (`0xA5` frame header / `0x5A` frame trailer), supporting the following environmental parameters:

- **Temperature** (°C)
- **Humidity** (%RH)
- **Light Intensity** (LX)
- **Air Quality** (AQI)

## Features

| Feature | Description |
|---|---|
| Bluetooth Device Discovery | Scan for nearby Bluetooth devices, display device names, MAC addresses, and device type icons |
| Dual Protocol Support | Simultaneously supports Classic Bluetooth SPP (RFCOMM) and Low Energy Bluetooth BLE (GATT) with auto-detection |
| Environmental Data Monitoring | Real-time display of temperature, humidity, light, and air quality data panels |
| Heartbeat Keep-Alive | Configurable heartbeat packets and intervals to prevent Bluetooth disconnection |
| Background Operation | Supports long-running tasks, maintaining Bluetooth connections in the background |
| Dark/Light Mode | Supports three modes: follow system, force dark, and force light |
| Grip Gesture Detection | Automatically detects left/right hand grip to adapt UI layout |

## Technology Stack

| Technology | Details |
|---|---|
| Platform | HarmonyOS (NEXT) |
| SDK Version | API 5.1.0(18) |
| Language | ArkTS |
| UI Framework | ArkUI v2 (Declarative UI) |
| State Management | AppStorageV2 / PersistenceV2 |
| Bluetooth | @kit.ConnectivityKit (SPP + BLE) |
| Build System | Hvigor |
| Package Manager | OHPM |
| Testing Framework | @ohos/hypium |

## Communication Protocol

The application communicates with sensor devices using a custom binary frame protocol with the following frame structure:

| Field | Length (bytes) | Description |
|---|---|---|
| Frame Header | 1 | Fixed `0xA5` |
| Temperature | 1 | Integer, unit °C |
| Humidity | 1 | Integer, unit %RH |
| Light Intensity | 2 | Big-endian 16-bit unsigned integer, unit LX |
| Air Quality | 1 | Integer, unit AQI |
| Frame Trailer | 1 | Fixed `0x5A` |

**Example Frame**: `A5 1A 32 00 C8 4B 5A` represents Temperature 26°C, Humidity 50%, Light Intensity 200 LX, Air Quality 75.

> Protocol parsing logic can be found in the `parseEnvironmentData` method in `entry/src/main/ets/utils/SppClientManager.ets` and `GattClientManager.ets`.

## Project Structure

envSensorPro/
├── AppScope/                                 # Application-level configuration and resources
│   └── app.json5                             # Application manifest (bundleName, version, etc.)
├── entry/                                    # Main module
│   └── src/
│       └── main/
│           ├── ets/
│           │   ├── entryability/             # Application entry Ability
│           │   │   └── EntryAbility.ets
│           │   ├── entrybackupability/       # Backup and restore extension
│           │   ├── models/                   # Data models
│           │   │   ├── globalBlueTooth.ets   # Bluetooth device list state
│           │   │   ├── globalType.ets        # Global application state
│           │   │   ├── buttonData.ets        # Button configuration
│           │   │   ├── button.ets            # Button data interface
│           │   │   ├── chatData.ets          # Data records
│           │   │   └── chat.ets              # Data record interface
│           │   ├── pages/                    # Pages
│           │   │   ├── Index.ets             # Root page / Navigation container
│           │   │   ├── Layout.ets            # Main page Tab layout
│           │   │   ├── Connection.ets        # Bluetooth scanning and connection
│           │   │   └── ChatData.ets          # Sensor data panel
│           │   └── utils/                    # Utility classes
│           │       ├── BlueToothManager.ets  # Bluetooth core management
│           │       ├── SppClientManager.ets  # SPP/RFCOMM client
│           │       ├── GattClientManager.ets # BLE/GATT client
│           │       ├── NoticeManager.ets     # Notification permission management
│           │       ├── ColorModeManager.ets  # Dark/Light mode
│           │       └── DetectGesture.ets     # Grip gesture detection
│           ├── module.json5                  # Module manifest
│           └── resources/                    # Resource files
├── build-profile.json5                       # Build configuration
├── oh-package.json5                          # Dependency configuration
└── README.md                                 # Project documentation


## Requirements

- **DevEco Studio** (supports HarmonyOS SDK 5.1.0(18) and above)
- **HarmonyOS Device** (5.1.0(18) or compatible version)
- Valid signing certificate (configured in `build-profile.json5`)

## Quick Start

1. Clone the project

```bash
git clone https://gitcode.com/gcw_rVSV2mp6/envSensor.git
