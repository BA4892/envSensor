import { toothManager as toothManager } from '../utils/BlueToothManager';
import { BlueToothItem, GlobalBlueTooth } from '../models/globalBlueTooth';
import { AppStorageV2, curves, PersistenceV2, PromptAction } from '@kit.ArkUI';
import { sppClientManager } from '../utils/SppClientManager';
import { GlobalType } from '../models/globalType';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import constant from '@ohos.bluetooth.constant';
import { detectGestureManager } from '../utils/DetectGesture';
import { gattClientManager } from '../utils/GattClientManager';

/**
 * 蓝牙设备连接核心组件
 * 功能说明：
 * 1. 蓝牙设备扫描（开始/停止）、设备列表展示与清空
 * 2. 蓝牙设备连接/断开，支持15秒连接超时检测
 * 3. 连接保活（心跳包定时发送）、后台任务保活
 * 4. 适配左手/右手/双手握持手势的UI布局
 * 5. 蓝牙权限校验、蓝牙状态检查与授权引导
 */
@ComponentV2
  // export为导出组件，方便其他组件调用
export struct Connection {
  // ===================== 全局/持久化状态 =====================
  // 蓝牙设备列表全局状态（AppStorage）
  blueToothData: GlobalBlueTooth = AppStorageV2.connect(GlobalBlueTooth, 'BLUETOOTH_KEY', () => new GlobalBlueTooth())!
  // 连接类型/状态全局状态（AppStorage）
  typeData: GlobalType = AppStorageV2.connect(GlobalType, 'TYPE_KEY', () => new GlobalType())!
  // 心跳包配置（PersistenceV2 本地持久化）
  heartData: GlobalType = PersistenceV2.connect(GlobalType, 'HEART_KEY', () => new GlobalType())!
  // 全局配置（PersistenceV2 本地持久化）
  globalData: GlobalType = PersistenceV2.connect(GlobalType, 'GLOBAL_KEY', () => new GlobalType())!

  // ===================== 工具实例 =====================
  // UI上下文：用于动画、弹窗、页面跳转等操作
  private uiContext: UIContext = this.getUIContext();
  // 弹窗提示工具：Toast/AlertDialog 展示
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  // ===================== 业务变量 =====================
  maxTimeFlag = 0 // 记录连接时长变量，超时时间为15秒

  // ===================== 动画相关参数 =====================
  @Local buttonOpacityValue: number = 0    // 按钮透明度，实现按钮入场渐显的动画
  @Local buttonTranslateY: number = -500  // 按钮y轴位移
  @Local buttonScaleValue: number = 0.1    // 按钮缩放
  @Local button1ScaleValue: number = 0.1   // 开始扫描按钮缩放
  @Local button2ScaleValue: number = 0.1   // 停止扫描按钮缩放
  @Local button3ScaleValue: number = 0.1   // 清空按钮缩放
  @Local deviceListTranslateX: number = -500 // 扫描的设备列表x轴位移

  // ===================== 生命周期方法 =====================
  /**
   * 组件即将显示时执行
   * 1. 若开启手势检测，启动手势读取
   * 2. 执行UI入场动画：按钮/设备列表归位、显隐/缩放动画
   */
  aboutToAppear(): void {
    // 开启手势检测时，启动手势读取
    if (this.globalData.gripTypeNum == 1) {
      detectGestureManager.startRead()
    }

    // 页面加载后执行UI入场动画（弹簧曲线）
    this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
      this.buttonOpacityValue = 1
      this.buttonTranslateY = 0
      this.button1ScaleValue = 1
      this.button2ScaleValue = 1
      this.button3ScaleValue = 1
      this.deviceListTranslateX = 0
    })
  }

  // ===================== UI构建方法 =====================
  build() {
    Stack() {
      // 区域1：顶部操作栏（开始扫描/停止扫描/清空列表）
      Row({ space: 5 }) {
        // 按钮1：开始扫描
        Button('开始扫描')
          .backgroundColor($r('app.color.button_color'))
          .scale({ x: this.button1ScaleValue, y: this.button1ScaleValue })
          .translate({ y: this.buttonTranslateY })
          .opacity(this.buttonOpacityValue)
          .onTouch((event: TouchEvent) => {
            // 按下事件：按钮缩小动画 + 申请蓝牙权限
            if (event.type == TouchType.Down) {
              // 按钮按下缩放动画
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.button1ScaleValue = 0.9
              })
              toothManager.init() // 向用户申请蓝牙权限
            }

            // 抬起事件：恢复按钮大小 + 执行扫描逻辑
            if (event.type === TouchType.Up) {
              // 按钮抬起恢复缩放动画
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.button1ScaleValue = 1
              })

              // 校验：设备已连接时禁止扫描
              if (this.typeData.connectType == 1) {
                try {
                  this.promptAction.showToast({
                    message: '请先断开设备后再开始扫描新的设备！',
                    duration: 2000
                  })
                } catch (error) {
                  let message = (error as BusinessError).message;
                  let code = (error as BusinessError).code;
                  console.error(`showToast args error code is ${code}, message is ${message}`);
                };
              } else {
                // 检查蓝牙当前状态
                let stateCode = toothManager.checkState()

                // 状态0：蓝牙已开启，执行扫描
                if (stateCode == 0) {
                  let code = toothManager.startDiscovery() // 开始扫描设备

                  // 扫描成功（状态码200）
                  if (code == 200) {
                    // 提示用户正在扫描
                    try {
                      this.promptAction.showToast({
                        message: '正在查找附近设备，请耐心等待',
                        duration: 2000
                      })
                    } catch (error) {
                      let message = (error as BusinessError).message;
                      let code = (error as BusinessError).code;
                      console.error(`showToast args error code is ${code}, message is ${message}`);
                    };
                    // 扫描前清空历史设备数据
                    this.blueToothData.blueList = []
                  }
                  // 状态码201：权限不足，引导用户授权
                  else if (code == 201) {
                    // 弹出权限授权引导弹窗
                    this.getUIContext().showAlertDialog({
                      title: '权限不足！',
                      message: '您未授权应用扫描蓝牙设备的权限，点击确定前往设置找到本应用，并开启"设备发现和连接"开关以完成授权。\n若无法打开授权页面请手动打开 设置->应用和元服务->找到本软件->打开设备发现和连接或重启软件，会有授权弹窗,请根据弹窗指引操作。',
                      autoCancel: true,
                      alignment: DialogAlignment.Center,
                      buttons: [
                        {
                          value: '取消',
                          action: () => {
                            console.info('Callback when the first button is clicked');
                          }
                        },
                        {
                          enabled: true,
                          defaultFocus: true,
                          style: DialogButtonStyle.HIGHLIGHT,
                          value: '确定',
                          action: () => {
                            let context = getContext(this) as common.UIAbilityContext;
                            context.startAbility({
                              bundleName: 'com.huawei.hmos.settings',
                              abilityName: 'com.huawei.hmos.settings.MainAbility',
                              uri: '', // uri为空的时候，拉起设置主页面
                              parameters: {
                                pushParams: {
                                  bundleName: 'cn.mxycn.envsensor', // 传要跳转的对应应用的包名
                                  permissionNames: ['ohos.permission.ACCESS_BLUETOOTH']
                                }
                              }
                            });
                          }
                        }
                      ],
                    });
                  }
                }
                // 状态1：蓝牙未开启，提示用户打开
                else if (stateCode == 1) {
                  toothManager.blueToothOn()
                  // 提示用户打开蓝牙
                  try {
                    this.promptAction.showToast({
                      message: '请打开蓝牙',
                      duration: 2000
                    })
                  } catch (error) {
                    let message = (error as BusinessError).message;
                    let code = (error as BusinessError).code;
                    console.error(`showToast args error code is ${code}, message is ${message}`);
                  };
                }
                // 其他状态：未知错误提示
                else {
                  try {
                    this.promptAction.showToast({
                      message: '未知错误，请重启软件或稍后再试',
                      duration: 2000
                    })
                  } catch (error) {
                    let message = (error as BusinessError).message;
                    let code = (error as BusinessError).code;
                    console.error(`showToast args error code is ${code}, message is ${message}`);
                  };
                }
              }
            }
          })

        // 按钮2：停止扫描
        Button('停止扫描')
          .backgroundColor($r('app.color.button_color'))
          .scale({ x: this.button2ScaleValue, y: this.button2ScaleValue })
          .translate({ y: this.buttonTranslateY })
          .opacity(this.buttonOpacityValue)
          .onTouch((event: TouchEvent) => {
            // 按下事件：按钮缩小动画
            if (event.type == TouchType.Down) {
              // 按钮按下缩放动画
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.button2ScaleValue = 0.9
              })
            }

            // 抬起事件：恢复按钮大小 + 停止扫描
            if (event.type === TouchType.Up) {
              // 按钮抬起恢复缩放动画
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.button2ScaleValue = 1
              })

              // 执行停止扫描操作
              toothManager.stopDiscovery()
              // 提示已停止扫描
              try {
                this.promptAction.showToast({
                  message: '已停止扫描',
                  duration: 2000
                })
              } catch (error) {
                let message = (error as BusinessError).message;
                let code = (error as BusinessError).code;
                console.error(`showToast args error code is ${code}, message is ${message}`);
              };
            }
          })

        // 按钮3：清空列表
        Button('清空列表')
          .backgroundColor($r('app.color.button_color'))
          .scale({ x: this.button3ScaleValue, y: this.button3ScaleValue })
          .translate({ y: this.buttonTranslateY })
          .opacity(this.buttonOpacityValue)
          .onTouch((event: TouchEvent) => {
            // 按下事件：按钮缩小动画
            if (event.type == TouchType.Down) {
              // 按钮按下缩放动画
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.button3ScaleValue = 0.9
              })
            }

            // 抬起事件：恢复按钮大小 + 执行清空逻辑
            if (event.type === TouchType.Up) {
              // 按钮抬起恢复缩放动画
              this.getUIContext()?.animateTo({ curve: curves.springMotion() }, () => {
                this.button3ScaleValue = 1
              })

              // 校验：列表为空时提示
              if (this.blueToothData.blueList.length == 0) {
                try {
                  this.promptAction.showToast({
                    message: '当前列表已经是空的了！',
                    duration: 1000
                  })
                } catch (error) {
                  let message = (error as BusinessError).message;
                  let code = (error as BusinessError).code;
                  console.error(`showToast args error code is ${code}, message is ${message}`);
                };
              } else {
                // 校验：设备已连接时禁止清空列表
                if (this.typeData.connectType == 1) {
                  try {
                    this.promptAction.showToast({
                      message: '请先断开设备后再清空列表！',
                      duration: 2000
                    })
                  } catch (error) {
                    let message = (error as BusinessError).message;
                    let code = (error as BusinessError).code;
                    console.error(`showToast args error code is ${code}, message is ${message}`);
                  };
                } else {
                  // 弹出清空确认弹窗
                  this.getUIContext().showAlertDialog({
                    title: '确定清空吗？',
                    message: '该操作会清空当前列表中的所有扫描的设备信息！',
                    autoCancel: true,
                    alignment: DialogAlignment.Center,
                    buttons: [
                      {
                        value: '取消',
                        fontColor: $r('app.color.button_color'),
                        action: () => {
                          console.info('Callback when the first button is clicked');
                        }
                      },
                      {
                        enabled: true,
                        defaultFocus: true,
                        style: DialogButtonStyle.HIGHLIGHT,
                        backgroundColor: $r('app.color.button_color'),
                        value: '确定',
                        action: () => {
                          console.info('Callback when the second button is clicked');
                          this.blueToothData.blueList = []
                        }
                      }
                    ],
                  });
                }
              }
            }
          })
      }
      .justifyContent(FlexAlign.Center)
      .translate({ y: this.buttonTranslateY })
      .opacity(this.buttonOpacityValue)
      .padding({
        top: 15,
        bottom: 15,
        left: "10%",
        right: "10%"
      })
      .backgroundColor($r('app.color.glass_color'))
      .backdropBlur(30)
      .width('100%')
      .zIndex(1)

      // 区域2：蓝牙设备列表
      List() {
        // 顶部占位项：避免设备列表被顶部操作栏遮挡
        ListItem() {
          Row() { }
          .width('100%')
          .height(70)
        }

        // 设备列表循环渲染
        ForEach(this.blueToothData.blueList, (item: BlueToothItem, index: number) => {
          ListItem() {
            // 布局分支1：左手握持
            if (this.typeData.DetectGestureType == 1) {
              Row({ space: 5 }) {
                // 连接/断开按钮逻辑
                if (this.typeData.connectType == 0) {
                  // 未连接状态：显示连接按钮
                  Button('连接')
                    .transition(
                      TransitionEffect.opacity(0).animation({ curve: Curve.Smooth }).combine(
                        TransitionEffect.scale({ x: 0.7, y: 0.7 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
                      )
                    )
                    .backgroundColor($r('app.color.button_color'))
                    .height(50)
                    .onClick(() => {
                      // 定时检查连接状态（1秒/次，15秒超时）
                      let clientChecker = setInterval(() => {
                        // 连接成功逻辑
                        if (this.typeData.connectType == 1) {
                          // 申请长时任务，防止应用切到后台断联设备
                          toothManager.startBackgroundTask()

                          // 连接成功提示
                          try {
                            this.promptAction.showToast({
                              message: '连接成功',
                              duration: 1000
                            })
                          } catch (error) {
                            let message = (error as BusinessError).message;
                            let code = (error as BusinessError).code;
                            console.error(`showToast args error code is ${code}, message is ${message}`);
                          };
                          clearInterval(clientChecker) // 连接成功后删除定时任务，防止重复弹出提示
                        }
                      }, 1000) // 每隔1秒检查一次连接状态

                      // 执行连接操作
                      toothManager.connectDevice(item.mac) // 发起设备连接
                      toothManager.stopDiscovery() // 点击连接时取消扫描，防止断开按钮出现bug
                      this.typeData.selectId = index // 设置选择索引为当前行
                      // 正在连接提示
                      try {
                        this.promptAction.showToast({
                          message: '正在连接',
                          duration: 2000
                        })
                      } catch (error) {
                        let message = (error as BusinessError).message;
                        let code = (error as BusinessError).code;
                        console.error(`showToast args error code is ${code}, message is ${message}`);
                      };
                    })
                } else if (this.typeData.connectType == 1 && this.typeData.selectId == index) {
                  // 已连接且是当前选中设备：显示断开按钮
                  Button('断开')
                    .transition(
                      TransitionEffect.opacity(0).animation({ curve: Curve.Smooth }).combine(
                        TransitionEffect.scale({ x: 0.7, y: 0.7 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
                      )
                    )
                    .backgroundColor('#F44336')
                    .height(50)
                    .onClick(() => {
                      sppClientManager.stopConnect() // 断开设备连接
                      this.typeData.selectId = -1      // 重置选中索引
                      this.typeData.connectType = 0   // 重置连接状态
                    })
                } else if (this.typeData.connectType == 1 && this.typeData.selectId != index) {
                  // 已连接但非当前选中设备：显示不可点击的连接按钮
                  Button('连接')
                    .transition(
                      TransitionEffect.opacity(0).animation({ curve: Curve.Smooth }).combine(
                        TransitionEffect.scale({ x: 0.7, y: 0.7 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
                      )
                    )
                    .backgroundColor($r('app.color.button_color'))
                    .height(50)
                }

                // 设备信息展示区域
                Row() {
                  // 根据设备类型显示对应图标
                  if (item.class == constant.MajorClass.MAJOR_COMPUTER.toString()) {
                    // 电脑蓝牙
                    Image($r('app.media.deviceClassComputer'))
                      .width(27)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else if (item.class == constant.MajorClass.MAJOR_PHONE.toString()) {
                    // 手机蓝牙
                    Image($r('app.media.deviceClassPhone'))
                      .width(30)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else if (item.class == constant.MajorClass.MAJOR_AUDIO_VIDEO.toString()) {
                    // 影音设备(耳机音箱等)蓝牙
                    Image($r('app.media.deviceClassAudio'))
                      .width(30)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else if (item.class == constant.MajorClass.MAJOR_WEARABLE.toString()) {
                    // 穿戴设备蓝牙
                    Image($r('app.media.deviceClassWear'))
                      .width(30)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else {
                    // 其他设备蓝牙
                    Image($r('app.media.bluetooth'))
                      .width(32)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  }

                  // 设备名称和MAC地址
                  Column() {
                    Text(item.name)
                      .width('100%')
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .maxLines(1)
                      .padding({ right: 30 })
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.mac)
                      .width('100%')
                      .fontSize(15)
                  }
                }
                .transition(
                  TransitionEffect.translate({ x: -70 }).animation({ duration: 600, curve: Curve.Smooth })
                  // TransitionEffect.opacity(0).animation({ delay: 200,duration: 600, curve: Curve.Smooth }).combine(
                  //   TransitionEffect.scale({x: 0.7, y: 0.7}).animation({ delay: 200,duration: 500, curve: Curve.Smooth })
                  // )
                )
                .layoutWeight(1)
                .height(50)
                .backgroundColor($r('app.color.panel_color'))
                .borderRadius(20)
                .padding({
                  left: 10,
                  right: 10,
                  top: 5,
                  bottom: 5
                })
              }
              .margin({ bottom: 15 })
            }
            // 布局分支2：右手/双手握持
            else {
              Row({ space: 5 }) {
                // 设备信息展示区域
                Row() {
                  // 根据设备类型显示对应图标
                  if (item.class == constant.MajorClass.MAJOR_COMPUTER.toString()) {
                    // 电脑蓝牙
                    Image($r('app.media.deviceClassComputer'))
                      .width(27)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else if (item.class == constant.MajorClass.MAJOR_PHONE.toString()) {
                    // 手机蓝牙
                    Image($r('app.media.deviceClassPhone'))
                      .width(30)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else if (item.class == constant.MajorClass.MAJOR_AUDIO_VIDEO.toString()) {
                    // 影音设备(耳机音箱等)蓝牙
                    Image($r('app.media.deviceClassAudio'))
                      .width(30)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else if (item.class == constant.MajorClass.MAJOR_WEARABLE.toString()) {
                    // 穿戴设备蓝牙
                    Image($r('app.media.deviceClassWear'))
                      .width(30)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  } else {
                    // 其他设备蓝牙
                    Image($r('app.media.bluetooth'))
                      .width(32)
                      .fillColor('#639ff8')
                      .margin({ right: 10 })
                  }

                  // 设备名称和MAC地址
                  Column() {
                    Text(item.name)
                      .width('100%')
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .maxLines(1)
                      .padding({ right: 30 })
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.mac)
                      .width('100%')
                      .fontSize(15)
                  }
                }
                .transition(
                  TransitionEffect.translate({ x: 70 }).animation({ duration: 600, curve: Curve.Smooth })
                )
                .layoutWeight(1)
                .height(50)
                .backgroundColor($r('app.color.panel_color'))
                .borderRadius(20)
                .padding({
                  left: 10,
                  right: 10,
                  top: 5,
                  bottom: 5
                })

                // 连接/断开按钮逻辑
                if (this.typeData.connectType == 0) {
                  // 未连接状态：显示连接按钮
                  Button('连接')
                    .transition(
                      TransitionEffect.opacity(0).animation({ curve: Curve.Smooth }).combine(
                        TransitionEffect.scale({ x: 0.7, y: 0.7 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
                      )
                    )
                    .backgroundColor($r('app.color.button_color'))
                    .height(50)
                    .onClick(() => {
                      // 定时检查连接状态（1秒/次，15秒超时）
                      let clientChecker = setInterval(() => {
                        // 连接成功逻辑
                        if (this.typeData.connectType == 1) {
                          // 申请长时任务，防止应用切到后台断联设备
                          toothManager.startBackgroundTask()

                          // 连接成功提示
                          try {
                            this.promptAction.showToast({
                              message: '连接成功',
                              duration: 1000
                            })
                          } catch (error) {
                            let message = (error as BusinessError).message;
                            let code = (error as BusinessError).code;
                            console.error(`showToast args error code is ${code}, message is ${message}`);
                          };
                          clearInterval(clientChecker) // 连接成功后删除定时任务，防止重复弹出提示

                          // 心跳包保活：定时发送数据防止断联，同时检测连接状态
                          if(this.heartData.heartType == 1)
                          {
                            let keepClientId = setInterval(() => {
                              if(this.heartData.heartType == 1)
                              {
                                //启用心跳功能
                                if(this.typeData.TransportType == 0)
                                {
                                  let connectState = sppClientManager.sendData(this.heartData.heartData)
                                  if (connectState == -1) {
                                    // 发现断联，重置连接状态
                                    this.typeData.connectType = 0
                                    clearInterval(keepClientId)
                                    console.log("重置连接状态")
                                  }
                                }
                                else
                                {
                                  gattClientManager.writeCharacteristicValue(this.heartData.heartData)
                                }
                              }
                              else
                              {
                                //不启用心跳功能
                                clearInterval(keepClientId)
                              }
                            }, (this.heartData.heartTime * 1000))
                          }
                          else
                          {
                            if(item.transport == '0')
                            {
                              let checkClientId = setInterval(() => {
                                //500毫秒检查一次
                                let connectState = sppClientManager.checkConnect()
                                if(connectState === false)
                                {
                                  //发现断连重置连接状态
                                  this.typeData.connectType = 0
                                  clearInterval(checkClientId)
                                }
                              }, (500))
                            }
                          }
                        }
                      }, 1000) // 每隔1秒检查一次连接状态

                      // 执行连接操作
                      toothManager.connectDevice(item.mac) // 发起设备连接
                      toothManager.stopDiscovery() // 点击连接时取消扫描，防止断开按钮出现bug
                      this.typeData.selectId = index // 设置选择索引为当前行
                      // 正在连接提示
                      try {
                        this.promptAction.showToast({
                          message: '正在连接',
                          duration: 2000
                        })
                      } catch (error) {
                        let message = (error as BusinessError).message;
                        let code = (error as BusinessError).code;
                        console.error(`showToast args error code is ${code}, message is ${message}`);
                      };
                    })
                } else if (this.typeData.connectType == 1 && this.typeData.selectId == index) {
                  // 已连接且是当前选中设备：显示断开按钮
                  Button('断开')
                    .transition(
                      TransitionEffect.opacity(0).animation({ curve: Curve.Smooth }).combine(
                        TransitionEffect.scale({ x: 0.7, y: 0.7 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
                      )
                    )
                    .backgroundColor('#F44336')
                    .height(50)
                    .onClick(() => {
                      if(this.typeData.TransportType == 0)
                      {
                        sppClientManager.stopConnect() // 断开设备连接
                      }
                      else
                      {
                        gattClientManager.stopConnect()
                      }
                      this.typeData.selectId = -1      // 重置选中索引
                      this.typeData.connectType = 0   // 重置连接状态
                    })
                } else if (this.typeData.connectType == 1 && this.typeData.selectId != index) {
                  // 已连接但非当前选中设备：显示不可点击的连接按钮
                  Button('连接')
                    .transition(
                      TransitionEffect.opacity(0).animation({ curve: Curve.Smooth }).combine(
                        TransitionEffect.scale({ x: 0.7, y: 0.7 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
                      )
                    )
                    .backgroundColor($r('app.color.button_color'))
                    .height(50)
                }
              }
              .margin({ bottom: 15 })
            }
          }
          .transition(
            TransitionEffect.opacity(0).animation({ delay: 200, duration: 600, curve: Curve.Smooth }).combine(
              TransitionEffect.scale({ x: 0.7, y: 0.7 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
            )
          )
        })

        // 底部占位项：防止最底部的设备信息被遮挡
        ListItem() {
          Row() { }
          .width('100%')
          .height(50)
        }
      }
      .padding({
        left: 20,
        right: 20
      })
      .margin({
        top: 5
      })
      .translate({ y: this.deviceListTranslateX })
      .scrollBar(BarState.Off) // 关闭滑块
    }
    .alignContent(Alignment.Top)
    .width('100%')
    .height('100%')
  }
}