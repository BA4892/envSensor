import { ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { GlobalType } from '../models/globalType';
import { util } from '@kit.ArkTS';
import { ChatDataHistory } from '../models/chatData';

const TAG: string = 'GattClientManager';
let deviceName = ''

class GattClientManager{
  //共享连接数据
  typeData: GlobalType = AppStorageV2.connect(GlobalType, 'TYPE_KEY', () => new GlobalType())!

  //共享对话历史数据
  chatData: ChatDataHistory = PersistenceV2.connect(ChatDataHistory, 'CHATDATA_KEY', () => new ChatDataHistory())!

  // ========== 超时粘包方案变量 (增加超时时间) ==========
  private binaryBuffer: number[] = [];
  private packetTimer: number = -1;
  private readonly PACKET_TIMEOUT_MS: number = 100;
  // ===========================================

  device: string = '';
  gattClient: ble.GattClientDevice | undefined = undefined;
  connectState: ble.ProfileConnectionState = constant.ProfileConnectionState.STATE_DISCONNECTED;
  myServiceUuid: string = '0000FFE0-0000-1000-8000-00805F9B34FB';
  myCharacteristicUuid: string = '0000FFE1-0000-1000-8000-00805F9B34FB';
  // 标准协议描述符Client Characteristic Configuration，用于特征值变化通知或指示
  myFirstDescriptorUuid: string = '00002902-0000-1000-8000-00805F9B34FB';
  // 自定义描述符
  mySecondDescriptorUuid: string = '00008888-0000-1000-8000-00805F9B34FB';

  myService: ble.GattService | undefined = undefined;
  myCharacteristic: ble.BLECharacteristic | undefined = undefined;
  myFirstDescriptor:


  ble.BLEDescriptor | undefined = undefined;
  mySecondDescriptor: ble.BLEDescriptor | undefined = undefined;

  foundService: boolean = false;
  foundChar: boolean = false;
  foundFirstDes: boolean = false;
  foundSecondDes: boolean = false;

  // 构造BLEDescriptor
  private initDescriptor(des: string, value: ArrayBuffer): ble.BLEDescriptor {
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.myServiceUuid,
      characteristicUuid: this.myCharacteristicUuid,
      descriptorUuid: des,
      descriptorValue: value
    };
    return descriptor;
  }

  // 构造BLECharacteristic
  private initCharacteristic(isWrite: boolean): ble.BLECharacteristic {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let charBuffer = new ArrayBuffer(2);
    if (isWrite) {
      let charValue = new Uint8Array(charBuffer);
      charValue[0] = 21;
      charValue[1] = 22;
    }
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.myServiceUuid,
      characteristicUuid: this.myCharacteristicUuid,
      characteristicValue: charBuffer,
      descriptors: descriptors
    };
    return characteristic;
  }

  private logCharacteristic(char: ble.BLECharacteristic) {
    let message = 'logCharacteristic uuid:' + char.characteristicUuid + ', value: ';
    let value = new Uint8Array(char.characteristicValue);
    message += 'logCharacteristic value: ';
    for (let i = 0; i < char.characteristicValue.byteLength; i++) {
      message += value[i] + ' ';
    }
    console.info(TAG, message);
  }

  private logDescriptor(des: ble.BLEDescriptor) {
    let message = 'logDescriptor uuid:' + des.descriptorUuid + ', value: ';
    let value = new Uint8Array(des.descriptorValue);
    message += 'logDescriptor value: ';
    for (let i = 0; i < des.descriptorValue.byteLength; i++) {
      message += value[i] + ' ';
    }
    console.info(TAG, message);
  }

  private checkService(services: Array<ble.GattService>) {
    for (let i = 0; i < services.length; i++) {
      if (services[i].serviceUuid != this.myServiceUuid) {
        continue;
      }
      this.myService = services[i];
      this.foundService = true;
      for (let j = 0; j < services[i].characteristics.length; j++) {
        if (services[i].characteristics[j].characteristicUuid != this.myCharacteristicUuid) {
          continue;
        }
        this.logCharacteristic(services[i].characteristics[j]);
        this.myCharacteristic = services[i].characteristics[j];
        this.foundChar = true;
        for (let k = 0; k < services[i].characteristics[j].descriptors.length; k++) {
          if (services[i].characteristics[j].descriptors[k].descriptorUuid == this.myFirstDescriptorUuid) {
            this.myFirstDescriptor= services[i].characteristics[j].descriptors[k];
            this.foundFirstDes = true;
            continue;
          }
          if (services[i].characteristics[j].descriptors[k].descriptorUuid == this.mySecondDescriptorUuid) {
            this.mySecondDescriptor = services[i].characteristics[j].descriptors[k];
            this.foundSecondDes = true;
            continue;
          }
        }
      }
    }
    console.info(TAG, 'foundService: ' + this.foundService + ', foundChar: ' + this.foundChar +
      ', foundFirDes: ' + this.foundFirstDes + ', foundSecDes: ' + this.foundSecondDes);
  }

  // 1. 定义连接状态变化回调函数
  onGattClientStateChange = async (stateInfo: ble.BLEConnectionChangeState) => {
    let state = '';
    switch (stateInfo.state) {
      case 0:
        state = 'DISCONNECTED';
        break;
      case 1:
        state = 'CONNECTING';
        break;
      case 2:
        state = 'CONNECTED';
        break;
      case 3:
        state = 'DISCONNECTING';
        break;
      default:
        state = 'undefined';
        break;
    }
    console.info(TAG, 'onGattClientStateChange: device=' + stateInfo.deviceId + ', state=' + state);
    if (stateInfo.deviceId == this.device) {
      this.connectState = stateInfo.state;
      if(stateInfo.state == 2)
      {
        //连接成功
        this.typeData.connectType = 1; //修改显示的连接状态
        this.typeData.TransportType = 1; //修改目标设备协议标志为GATT
        this.typeData.connectedDeviceName = deviceName; //修改显示的连接设备名称
        await this.discoverServices(); // 调用服务发现，加await确保执行完成
        await this.Notify(true); // 新增：连接成功后自动开通知
        // 延迟100ms再启用Notify，确保特征值已赋值
        setTimeout(() => {
          this.Notify(true);
        }, 100);
      }
      else if(stateInfo.state == 0)
      {
        //断开连接
        this.typeData.connectType = 0; //修改显示的连接状态
        this.typeData.connectedDeviceName = '未连接设备'; //修改显示的连接设备名称
      }
    }
  };

  // 2. client端主动连接时调用
  public startConnect(peerDevice: string, deviceName2: string) { // 对端设备一般通过ble查找设备获取到
    if (this.connectState != constant.ProfileConnectionState.STATE_DISCONNECTED) {
      console.error(TAG, 'startConnect failed');
      return;
    }
    console.info(TAG, 'startConnect ' + peerDevice);
    this.device = peerDevice;
    deviceName = deviceName2; //传递给全局变量
    // 2.1 使用device构造gattClient，后续的交互都需要使用该实例
    this.gattClient = ble.createGattClientDevice(peerDevice);
    try {
      // 2.2 订阅连接状态
      this.gattClient.on('BLEConnectionStateChange', this.onGattClientStateChange);

      // 2.3 发起连接
      this.gattClient.connect();



    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 3. client端连接成功后，需要进行服务发现
  public async discoverServices() {
    if (!this.gattClient) {
      console.error(TAG, 'gattClient does not exist');
      return;
    }
    console.info(TAG, 'discoverServices');
    try {
      let serverService = await this.gattClient.getServices();
      // ========== 新增：打印所有服务/特征值UUID（关键！）==========
      console.info(TAG, `设备返回的所有服务总数：${serverService.length}`);
      serverService.forEach((service, idx) => {
        console.info(TAG, `【服务${idx+1}】UUID：${service.serviceUuid}`);
        service.characteristics.forEach((char, cIdx) => {
          console.info(TAG, `  【特征值${cIdx+1}】UUID：${char.characteristicUuid}`);
          char.descriptors.forEach((desc, dIdx) => {
            console.info(TAG, `    【描述符${dIdx+1}】UUID：${desc.descriptorUuid}`);
          });
        });
      });
      // ==========================================================
      this.checkService(serverService);
      if (typeof this.myService !== 'undefined') {
        console.info(TAG, 'Service: ' + JSON.stringify(this.myService));
      }
      if (typeof this.myCharacteristic !== 'undefined') {
        this.logCharacteristic(this.myCharacteristic);
      }
      if (typeof this.myFirstDescriptor !== 'undefined') {
        this.logDescriptor(this.myFirstDescriptor);
      }
      if (typeof this.mySecondDescriptor !== 'undefined') {
        this.logDescriptor(this.mySecondDescriptor);
      }
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public formatDate(date: Date) {
    let year = date.getFullYear();
    let month = date.getMonth() + 1; // 注意月份是从0开始的
    let day = date.getDate();
    let hours = date.getHours();
    let minute = date.getMinutes();
    let second = date.getSeconds();
    return `${year}-${month < 10 ? '0' + month : month}-${day < 10 ? '0' + day : day} ${hours < 10 ? '0' + hours : hours}:${minute < 10 ? '0' + minute : minute}:${second < 10 ? '0' + second : second}`;
  }

  // 类内修改：处理接收到的GATT数据
  private handleReceivedData(dataBuffer: ArrayBuffer) {
    const data = new Uint8Array(dataBuffer);

    // 1. 基础过滤：过滤全0无效数据
    const isAllZero = Array.from(data).every(byte => byte === 0);
    if (isAllZero) {
      console.info(TAG, '过滤无效全0数据');
      return;
    }

    // 2. 将新收到的数据追加到二进制缓冲区
    for (let i = 0; i < data.length; i++) {
      this.binaryBuffer.push(data[i]);
    }
    console.info(TAG, `缓冲区追加 ${data.length} 字节，当前总长: ${this.binaryBuffer.length}`);

    // 3. 关键逻辑：重置定时器
    // 如果之前有定时器，先取消它
    if (this.packetTimer !== -1) {
      clearTimeout(this.packetTimer);
    }
    // 开启新的定时器，PACKET_TIMEOUT_MS 毫秒后如果没新数据，就认为包结束
    this.packetTimer = setTimeout(() => {
      this.processCompletePacket();
    }, this.PACKET_TIMEOUT_MS);
  }

  // 新增：当超时判定为“一包完整数据”后，执行解码和存储
  // 新增：当超时判定为“一包完整数据”后，执行解码和存储
  private processCompletePacket() {
    console.info(TAG, `超时判定包结束，处理 ${this.binaryBuffer.length} 字节数据`);

    if (this.binaryBuffer.length === 0) {
      return;
    }

    const currentDate = new Date();
    const uint8Data = new Uint8Array(this.binaryBuffer);
    const finalBuffer = uint8Data.buffer;

    // ====================== 新增：环境数据协议解析 ======================
    this.parseEnvironmentData(uint8Data);
    // ===================================================================

    let decodeResult = '';

    if (!this.chatData.isHex) {
      // ====================== 文本模式 ======================
      let textDecoder = util.TextDecoder.create('gbk');
      if (this.typeData.stringCodeNum === 1) {
        textDecoder = util.TextDecoder.create('utf-8');
      }
      try {
        decodeResult = textDecoder.decodeToString(uint8Data).trim();
      } catch (e) {
        console.error(TAG, '文本解码失败');
        decodeResult = "[解码错误]";
      }
    } else {
      // ====================== HEX模式 ======================
      decodeResult = Array.from(uint8Data)
        .filter(byte => byte !== 0)
        .map(byte => byte.toString(16).toUpperCase().padStart(2, '0'))
        .join(' ');
    }

    // 最终存储
    if (decodeResult) {
      this.chatData.chatDataList.push({
        time: this.formatDate(currentDate),
        data: decodeResult
      });
      PersistenceV2.save('CHATDATA_KEY');
      console.info(TAG, `存入数据: ${decodeResult}`);
    }

    PersistenceV2.save('GLOBAL_KEY');

    this.binaryBuffer = [];
    this.packetTimer = -1;
  }

  // ====================== 协议适配 ======================
  private parseEnvironmentData(data: Uint8Array) {
    const headerIndex = data.indexOf(0xA5);
    const tailIndex = data.indexOf(0x5A);

    if (headerIndex === -1 || tailIndex === -1 || tailIndex <= headerIndex) {
      console.warn(TAG, '未找到有效帧头帧尾');
      return;
    }

    const packetLength = tailIndex - headerIndex - 1;
    console.info(TAG, `找到数据包，数据段长度: ${packetLength}`);

    if (packetLength < 5) {
      console.warn(TAG, `数据长度不足5，实际:${packetLength}`);
      return;
    }

    let offset = headerIndex + 1;

    // 字节0：温度
    this.chatData.temperature = data[offset];
    offset += 1;

    // 字节1：湿度
    this.chatData.humidity = data[offset];
    offset += 1;

    // 字节2-3：光照
    this.chatData.light = (data[offset] << 8) | data[offset + 1];
    offset += 2;

    // 字节4：空气质量
    this.chatData.airQuality = data[offset];
    offset += 1;

    console.info(TAG, `解析成功 -> 温:${this.chatData.temperature} 湿:${this.chatData.humidity} 光:${this.chatData.light} 空:${this.chatData.airQuality}`);

    // ====================== 【关键优化】强制触发UI更新 ======================
    // 1. 先持久化
    PersistenceV2.save('CHATDATA_KEY');

    // 2. 【重要】给其中一个字段重新赋值一次，强制触发 @Trace 刷新
    // （ArkTS 有时对“连续赋值”的触发不敏感，加这行立竿见影）
    this.chatData.temperature = this.chatData.temperature;

    console.info(TAG, '已强制触发UI刷新');
  }

  // 在确保拿到了server端的服务结果后，读取server端特定服务的特征值时调用
  public async readCharacteristicValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, '未连接，无法读取');
      return;
    }
    if (!this.foundChar || !this.myCharacteristic) {
      console.error(TAG, '特征值不存在，无法读取');
      return;
    }

    console.info(TAG, '主动读取特征值');
    try {
      // 关键修复：使用服务发现后的真实特征值，而非重新构造空对象
      const outData = await this.gattClient.readCharacteristicValue(this.myCharacteristic);
      this.myCharacteristic = outData;

      // 处理读取到的数据
      if (outData.characteristicValue) {
        this.handleReceivedData(outData.characteristicValue);
      }
    } catch (err) {
      console.error(TAG, `读取失败：${(err as BusinessError).code} - ${(err as BusinessError).message}`);
    }
  }

  // 在确保拿到了server端的服务结果后，写入server端特定服务的特征值时调用
  public writeCharacteristicValue(sendData: number) {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundChar) {
      console.error(TAG, 'server characteristic does not exist');
      return;
    }

    let arrayBuffer = new ArrayBuffer(1);
    let data = new Uint8Array(arrayBuffer);
    data[0] = sendData; // 传入你要发的字节

    // 用已找到的特征值，直接赋值发送，不重新瞎构造
    let characteristic = this.myCharacteristic!;
    characteristic.characteristicValue = arrayBuffer;

    console.info(TAG, 'writeCharacteristicValue sendData: ' + sendData);
    try {
      this.gattClient.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE, (err) => {
        if (err) {
          console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          return;
        }
        console.info(TAG, 'writeCharacteristicValue success');
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 在确保拿到了server端的服务结果后，读取server端特定服务的描述符时调用
  public readDescriptorValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundSecondDes) { // 要确保server端有对应的descriptor
      console.error(TAG, 'server descriptor does not exist');
      return;
    }

    let descBuffer = new ArrayBuffer(0);
    let descriptor = this.initDescriptor(this.mySecondDescriptorUuid, descBuffer);
    console.info(TAG, 'readDescriptorValue');
    try {
      this.gattClient.readDescriptorValue(descriptor).then((outData: ble.BLEDescriptor) => {
        this.logDescriptor(outData);
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 在确保拿到了server端的服务结果后，写入server端特定服务的描述符时调用
  public writeDescriptorValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundSecondDes) { // 要确保server端有对应的descriptor
      console.error(TAG, 'server descriptor does not exist');
      return;
    }

    let descBuffer = new ArrayBuffer(2);
    let descValue = new Uint8Array(descBuffer);
    descValue[0] = 41;
    descValue[1] = 42;
    let descriptor = this.initDescriptor(this.mySecondDescriptorUuid, descBuffer);
    console.info(TAG, 'writeDescriptorValue');
    try {
      this.gattClient.writeDescriptorValue(descriptor, (err) => {
        if (err) {
          console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          return;
        }
        console.info(TAG, 'writeDescriptorValue success');
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  onCharacteristicChange = (char: ble.BLECharacteristic) => {
    console.info(TAG, '蓝牙模块推送了数据');
    this.logCharacteristic(char);
    this.myCharacteristic = char;
    // 关键：调用数据处理函数，把数据存起来
    if (char.characteristicValue) {
      this.handleReceivedData(char.characteristicValue);
    }
  };

  // 使能或禁用接收服务端端特征值内容变更通知的能力时调用，一般通知或者指示，二选一
  public Notify(enable: boolean) {
    // 核心校验：连接状态 + 2902描述符存在
    if (!this.gattClient || this.connectState !== constant.ProfileConnectionState.STATE_CONNECTED || !this.foundFirstDes || !this.myCharacteristic) {
      console.error(TAG, 'Notify failed: 连接异常/特征值不存在');
      return;
    }

    try {
      // 订阅特征值变化回调（去重：先取消再订阅）
      this.gattClient.off('BLECharacteristicChange', this.onCharacteristicChange);
      this.gattClient.on('BLECharacteristicChange', this.onCharacteristicChange);

      // 写入2902描述符（通知开关核心：0x01启用/0x00禁用）
      const buf = new ArrayBuffer(2);
      new Uint8Array(buf)[0] = enable ? 0x01 : 0x00;
      this.gattClient.writeDescriptorValue(this.initDescriptor(this.myFirstDescriptorUuid, buf), (err) => {
        if (err) console.error(TAG, '2902描述符写入失败:', err.message);
      });

      // 启用/禁用通知
      this.gattClient.setCharacteristicChangeNotification(this.myCharacteristic, enable, (err) => {
        console.info(TAG, `Notify ${enable ? '启用' : '禁用'}${err ? '失败' : '成功'}`);
      });
    } catch (err) {
      console.error(TAG, 'Notify err:', (err as BusinessError).message);
    }
  }

  // 使能或禁用接收服务端端特征值内容变更指示的能力时调用，一般通知或者指示，二选一
  public Indicate(enable: boolean) {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }

    if (!this.foundFirstDes) { // 要确保server端有对应的client configuration descriptor
      console.error(TAG, 'server client configuration descriptor does not exist');
      return;
    }

    console.info(TAG, 'Indicate ' + this.device + ' enable: ' + enable);
    try {
      // 订阅特征值变化
      this.gattClient.on('BLECharacteristicChange', this.onCharacteristicChange);
      // 设置特征值变化指示能力，enable: true表示启用，false表示禁用
      this.gattClient.setCharacteristicChangeIndication(this.myCharacteristic, enable, (err: BusinessError) => {
        if (err) {
          console.error('setCharacteristicChangeIndication callback failed');
        } else {
          console.info('setCharacteristicChangeIndication callback successful');
        }
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // client端主动断开时调用
  public stopConnect() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }

    console.info(TAG, 'stopConnect ' + this.device);
    try {
      this.gattClient.disconnect(); // 断开连接
      this.gattClient.off('BLEConnectionStateChange', this.onGattClientStateChange); // 11.2 取消订阅连接状态
      this.gattClient.off('BLECharacteristicChange', this.onCharacteristicChange); // 11.3 取消订阅特征值变化
      this.gattClient.close() // 如果应用不再使用此gattClient，则需要close
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}

export const gattClientManager: GattClientManager = new GattClientManager()