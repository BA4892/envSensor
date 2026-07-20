<p align="center">
  <a href="https://github.com/mengxinyuan638/envSensor">
    <img src="./img/logo.png" alt="Logo" width="80" height="80" style="border: 1px solid #DCDCDC; border-radius: 20px;">
  </a>

  <h3 align="center">环境监测系统上位机</h3>
  <p align="center">
   一款基于 HarmonyOS 的蓝牙环境监测系统上位机应用
    <br />
    <br />
    <a href="https://github.com/mengxinyuan638/envSensor/issues">报告 Bug</a>
    ·
    <a href="https://github.com/mengxinyuan638/envSensor/issues">提出新特性</a>
  </p>
## 项目简介（该文档由AI生成）

环境监测系统上位机是一款运行在 HarmonyOS 上的蓝牙客户端应用，用于连接 ESP32 等蓝牙环境传感器设备，实时接收并展示环境数据。

数据通过自定义二进制协议（`0xA5` 帧头 / `0x5A` 帧尾）传输，支持以下环境参数监测：

- **温度** (°C)
- **湿度** (%RH)
- **光照强度** (LX)
- **空气质量** (AQI)

## 功能特性

| 功能 | 说明 |
|---|---|
| 蓝牙设备发现 | 扫描附近蓝牙设备，显示设备名称、MAC 地址及设备类型图标 |
| 双协议支持 | 同时支持经典蓝牙 SPP (RFCOMM) 和低功耗蓝牙 BLE (GATT)，自动识别 |
| 环境数据监测 | 实时展示温度、湿度、光照、空气质量数据面板 |
| 心跳保活 | 可配置心跳包及发送间隔，防止蓝牙连接断开 |
| 后台运行 | 支持长时任务，蓝牙连接可在后台保持 |
| 深色/浅色模式 | 支持跟随系统、强制深色、强制浅色三种模式 |
| 握持手势检测 | 自动检测左手/右手握持，适配 UI 布局 |

## 技术栈

| 技术 | 详情 |
|---|---|
| 平台 | HarmonyOS (NEXT) |
| SDK 版本 | API 5.1.0(18) |
| 开发语言 | ArkTS |
| UI 框架 | ArkUI v2 (声明式 UI) |
| 状态管理 | AppStorageV2 / PersistenceV2 |
| 蓝牙 | @kit.ConnectivityKit (SPP + BLE) |
| 构建系统 | Hvigor |
| 包管理器 | OHPM |
| 测试框架 | @ohos/hypium |

## 通信协议

应用与传感器设备之间采用自定义二进制帧协议通信，帧结构如下：

| 字段 | 长度 (字节) | 说明 |
|---|---|---|
| 帧头 | 1 | 固定 `0xA5` |
| 温度 | 1 | 整数，单位 °C |
| 湿度 | 1 | 整数，单位 %RH |
| 光照 | 2 | 大端 16 位无符号整数，单位 LX |
| 空气质量 | 1 | 整数，单位 AQI |
| 帧尾 | 1 | 固定 `0x5A` |

**示例帧**：`A5 1A 32 00 C8 4B 5A` 表示温度 26°C、湿度 50%、光照 200 LX、空气质量 75。

> 协议解析逻辑见 `entry/src/main/ets/utils/SppClientManager.ets` 与 `GattClientManager.ets` 中的 `parseEnvironmentData` 方法。

## 项目结构

```
envSensorPro/
├── AppScope/                        # 应用级配置与资源
│   └── app.json5                    # 应用清单 (bundleName, version 等)
├── entry/                           # 主模块
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/        # 应用入口 Ability
│       │   │   └── EntryAbility.ets
│       │   ├── entrybackupability/  # 备份恢复扩展
│       │   ├── models/              # 数据模型
│       │   │   ├── globalBlueTooth.ets   # 蓝牙设备列表状态
│       │   │   ├── globalType.ets        # 全局应用状态
│       │   │   ├── buttonData.ets        # 按钮配置
│       │   │   ├── button.ets            # 按钮数据接口
│       │   │   ├── chatData.ets          # 数据记录
│       │   │   └── chat.ets              # 数据记录接口
│       │   ├── pages/               # 页面
│       │   │   ├── Index.ets             # 根页面 / 导航容器
│       │   │   ├── Layout.ets            # 主页 Tab 布局
│       │   │   ├── Connection.ets        # 蓝牙扫描与连接
│       │   │   └── ChatData.ets          # 传感器数据面板
│       │   └── utils/               # 工具类
│       │       ├── BlueToothManager.ets  # 蓝牙核心管理
│       │       ├── SppClientManager.ets  # SPP/RFCOMM 客户端
│       │       ├── GattClientManager.ets # BLE/GATT 客户端
│       │       ├── NoticeManager.ets     # 通知权限管理
│       │       ├── ColorModeManager.ets  # 深色/浅色模式
│       │       └── DetectGesture.ets     # 握持手势检测
│       ├── module.json5             # 模块清单
│       └── resources/               # 资源文件
├── build-profile.json5              # 构建配置
├── oh-package.json5                 # 依赖配置
└── README.md
```

## 环境要求

- **DevEco Studio** (支持 HarmonyOS SDK 5.1.0(18) 及以上)
- **HarmonyOS 设备** (5.1.0(18) 或兼容版本)
- 有效的签名证书（在 `build-profile.json5` 中配置）

## 快速开始

1. 克隆项目

```bash
git clone https://github.com/mengxinyuan638/envSensor.git
```

2. 使用 DevEco Studio 打开项目根目录

3. 等待 OHPM 依赖自动安装完成

4. **配置签名证书**

   克隆后需在 DevEco Studio 中配置自己的签名：
   - 打开 `File > Project Structure > Project > Signing Configs`
   - 勾选 `Automatically generate signature`，或手动指定自己的 `.cer` / `.p7b` / `.p12` 文件

5. 连接 HarmonyOS 真机设备

6. 点击 **Run** 运行项目，或命令行执行：

```bash
hvigorw assembleHap
```

## 应用权限

| 权限 | 用途 |
|---|---|
| `ohos.permission.ACCESS_BLUETOOTH` | 蓝牙设备发现与连接 |
| `ohos.permission.INTERNET` | 网络访问 |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | 后台蓝牙保活 |
| `ohos.permission.DETECT_GESTURE` | 握持手势检测 |

## 如何参与开源项目

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

也欢迎直接提交 [Issue](https://github.com/mengxinyuan638/envSensor/issues) 反馈问题或建议。

## 版本控制

该项目使用 Git 进行版本管理。您可以在 [repository](https://github.com/mengxinyuan638/envSensor) 查看当前可用版本。

## 作者

**萌新源**

QQ 群：934541995

*您也可以在贡献者名单中参看所有参与该项目的开发者。*

## 版权说明

该项目签署了 MIT 授权许可，详情请参阅 [LICENSE](./LICENSE) 文件。

> 其中 `entry/src/main/ets/utils/ColorModeManager.ets` 来源于华为示例代码，采用 Apache-2.0 许可证。
