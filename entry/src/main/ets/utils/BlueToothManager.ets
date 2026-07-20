import { access } from '@kit.ConnectivityKit';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common, wantAgent } from '@kit.AbilityKit';
import { connection } from '@kit.ConnectivityKit';
import { GlobalBlueTooth } from '../models/globalBlueTooth';
import { AppStorageV2 } from '@kit.ArkUI';
import { sppClientManager } from './SppClientManager';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import { gattClientManager } from './GattClientManager';


class BlueToothManager{

  //共享蓝牙设备数据
  blueToothData: GlobalBlueTooth = AppStorageV2.connect(GlobalBlueTooth, 'BLUETOOTH_KEY', () => new GlobalBlueTooth())!

  deviceAddress: string = ''
  async init() {
    try {
      await this.requestBlueToothPermission()
    } catch (err) {
      promptAction.showToast({
        message: 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message//弹窗内容
      });
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  //申请长时任务
  async startBackgroundTask() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: "cn.mxycn.envsensor",
          abilityName: "EntryAbility"
        }
      ],

      actionType: wantAgent.OperationType.START_ABILITY,

      requestCode: 0,

      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };

    const want = await wantAgent.getWantAgent(wantAgentInfo)

    await backgroundTaskManager.startBackgroundRunning(getContext(), backgroundTaskManager.BackgroundMode.BLUETOOTH_INTERACTION, want)
  }

  // 用户申请权限
  async reqPermissionsFromUser(): Promise<number[]> {
    let context = getContext() as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus = await atManager.requestPermissionsFromUser(context, ['ohos.permission.ACCESS_BLUETOOTH']);
    return grantStatus.authResults;
  }

  // 用户申请蓝牙权限
  async requestBlueToothPermission() {
    let grantStatus = await this.reqPermissionsFromUser();
    for (let i = 0; i < grantStatus.length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作
      }
    }
  }
  //开启蓝牙
  async blueToothOn()
  {
    try {
      await this.requestBlueToothPermission()
      await access.enableBluetooth();
    } catch (err) {
      promptAction.showToast({
        message: 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message//弹窗内容
      });
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  //关闭蓝牙
  async blueToothOff()
  {
    try {
      await this.requestBlueToothPermission()
      await access.disableBluetooth();
    } catch (err) {
      promptAction.showToast({
        message: 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message//弹窗内容
      });
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
  //检查扫描到的设备mac是否重复
  //重复则不添加到表中
  blueToothDeviceChecker(data: Array<string>)
  {
    for(let i = 0; i < this.blueToothData.blueList.length; i++)
    {
      if(this.blueToothData.blueList[i].mac == data[0])
      {
        //当检查到重复则跳出循环返回0
        return 0;
      }
    }
    //当循环结束还没有找到重复则返回1
    return 1;
  }

  //蓝牙搜索方法
  // 定义扫描结果上报回调函数
  onReceiveEvent = (data: Array<string>) => {
    let deviceName = connection.getRemoteDeviceName(data[0])
    let deviceClass = connection.getRemoteDeviceClass(data[0]) //获取对端设备类型
    let transportClass = connection.getRemoteDeviceTransport(data[0]) //获取对端设备传输协议
    console.log("SPORT:",transportClass.toString())
    console.info('bluetooth device: '+ JSON.stringify(data));
    if(this.blueToothDeviceChecker(data))
    {
      //当没有扫描到重复时添加数据
      if(deviceName == '')
      {
        console.info('bluetooth device name: 未知设备');
        this.blueToothData.blueList.push({
          mac: data[0],
          name: "未知设备",
          class: deviceClass.majorClass.toString(),
          transport: transportClass.toString(),
        }) //在共享的设备数据末位添加一条扫描到的设备数据
      }
      else
      {
        console.info('bluetooth device name: '+ deviceName);
        console.info('bluetooth device name2: '+ deviceClass.majorClass.toString());
        this.blueToothData.blueList.push({
          mac: data[0],
          name: deviceName,
          class: deviceClass.majorClass.toString(),
          transport: transportClass.toString(),
        })
      }
    }
  };

  public startDiscovery() {
    try {
      connection.on('bluetoothDeviceFind', this.onReceiveEvent);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    try {
      // 判断本机设备是否正在进行扫描
      let scan = connection.isBluetoothDiscovering();
      if (!scan) {
        // 若当前不处于扫描过程，则开始扫描设备
        connection.startBluetoothDiscovery();
      }
      return 200; //表示正常
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return Number((err as BusinessError).code);
    }
  }

  public stopDiscovery() {
    try {
      // 判断本机设备是否正在进行扫描
      let scan = connection.isBluetoothDiscovering();
      if (scan) {
        // 若当前处于扫描过程，则停止扫描设备
        connection.stopBluetoothDiscovery();
      }
      // 若不再需要使用扫描，可以取消订阅扫描上报结果
      connection.off('bluetoothDeviceFind', this.onReceiveEvent);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public setScanMode() {
    try {
      // 获取当前本机的扫描模式
      let scanMode: connection.ScanMode = connection.getBluetoothScanMode();
      console.info('scanMode: ' + scanMode);
      if (scanMode != connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE) {
        // 将本机设备的扫描模式设为可被发现和可被连接
        connection.setBluetoothScanMode(connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE, 0);
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public getPairedDevices() {
    try {
      // 获取已配对设备信息
      let devices = connection.getPairedDevices();
      console.info('pairedDevices: ' + JSON.stringify(devices));
      // 若已知道设备地址，可主动查询该设备是否是已配对的
      if (devices.length > 0) {
        let pairState = connection.getPairState(devices[0]);
        console.info('device: '+ devices[0] + ' pairState is ' + pairState);
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public checkState() {
    try {
      //获取蓝牙开启状态
      let stateCode = access.getState()
      if(stateCode == 0 || stateCode == 3)
      {
        return 1;
      }
      else
      {
        return 0;
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return -1;
    }
  }

  public connectDevice(device: string) {
    let pairState = connection.getPairState(device);
    let deviceType = connection.getRemoteDeviceTransport(device).toString();
    if(pairState == 2 || device != '0')
    {
      //设备已配对或低功耗蓝牙(不需要配对)
      let deviceName = connection.getRemoteDeviceName(device);
      if(deviceType == '0')
      {
        console.log("开始经典蓝牙配对")
        sppClientManager.startConnect(device, deviceName) //发起连接
      }
      else
      {
        console.log("开始低功耗蓝牙配对")
        gattClientManager.startConnect(device, deviceName)
      }
    }
    else
    {
      //设备没有配对
      try {
        // 发起配对
        connection.pairDevice(device).then(() => {
          console.info('pairDevice');
        }, (error: BusinessError) => {
          console.error('pairDevice: errCode:' + error.code + ',errMessage' + error.message);
        });
      } catch (err) {
        console.error('startPair: errCode:' + err.code + ',errMessage' + err.message);
        console.info('mac:' + device);
      }
    }
  }
}
export const toothManager: BlueToothManager = new BlueToothManager()