import { socket } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalType } from '../models/globalType';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { ChatDataHistory } from '../models/chatData';
import { util } from '@kit.ArkTS';

// 【新增】添加日志TAG，和GATT保持一致
const TAG: string = 'SppClientManager';

class SppClientManager {
  // 定义客户端的socket id
  clientNumber: number = -1;

  //共享连接数据
  typeData: GlobalType = AppStorageV2.connect(GlobalType, 'TYPE_KEY', () => new GlobalType())!

  //共享对话历史数据
  chatData: ChatDataHistory = PersistenceV2.connect(ChatDataHistory, 'CHATDATA_KEY', () => new ChatDataHistory())!

  // ========== 【新增】超时粘包方案变量 (从GATT同步) ==========
  private binaryBuffer: number[] = [];
  private packetTimer: number = -1;
  private readonly PACKET_TIMEOUT_MS: number = 100;
  // ==========================================================

  public checkConnect(): boolean{
    let result = socket.isConnected(this.clientNumber)
    return result
  }

  // 发起连接
  public startConnect(peerDevice: string, deviceName: string): void {
    let option: socket.SppOptions = {
      uuid: '00001101-0000-1000-8000-00805F9B34FB',
      secure: false,
      type: socket.SppType.SPP_RFCOMM
    };
    console.info(TAG, 'startConnect ' + peerDevice);
    socket.sppConnect(peerDevice, option, (err, num: number) => {
      if (err) {
        console.error(TAG, 'startConnect errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      } else {
        this.typeData.connectType = 1;
        this.typeData.TransportType = 0; // SPP标志
        this.typeData.connectedDeviceName = deviceName;
        console.info(TAG, 'startConnect clientNumber: ' + num);
        this.clientNumber = num;

        //连接开始读取数据
        sppClientManager.readData();
      }
    });
    console.info(TAG, 'startConnect after ' + peerDevice);
  }

  // 发送数据
  public sendData(sendData: number) {
    let arrayBuffer = new ArrayBuffer(1);
    let data = new Uint8Array(arrayBuffer);
    data[0] = sendData;
    try {
      socket.sppWrite(this.clientNumber, arrayBuffer);
    } catch (err) {
      console.error(TAG, 'sppWrite errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return -1;
    }
    return 1;
  }

  public formatDate(date: Date) {
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    let hours = date.getHours();
    let minute = date.getMinutes();
    let second = date.getSeconds();
    return `${year}-${month < 10 ? '0' + month : month}-${day < 10 ? '0' + day : day} ${hours < 10 ? '0' + hours : hours}:${minute < 10 ? '0' + minute : minute}:${second < 10 ? '0' + second : second}`;
  }

  // 【新增】优化日志打印，直接输出HEX (从GATT同步)
  private logCharacteristic(data: Uint8Array) {
    let hexString = Array.from(data)
      .map(byte => byte.toString(16).toUpperCase().padStart(2, '0'))
      .join(' ');
    console.info(TAG, `收到原始数据 (HEX): ${hexString}`);
  }

  // 【新增】数据接收处理 (从GATT同步)
  private handleReceivedData(dataBuffer: ArrayBuffer) {
    const data = new Uint8Array(dataBuffer);

    // 打印日志
    this.logCharacteristic(data);

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

    // 3. 重置定时器
    if (this.packetTimer !== -1) {
      clearTimeout(this.packetTimer);
    }
    this.packetTimer = setTimeout(() => {
      this.processCompletePacket();
    }, this.PACKET_TIMEOUT_MS);
  }

  // 【新增】处理完整数据包 (从GATT同步)
  private processCompletePacket() {
    console.info(TAG, `超时判定包结束，处理 ${this.binaryBuffer.length} 字节数据`);
    if (this.binaryBuffer.length === 0) {
      return;
    }
    const currentDate = new Date();
    const uint8Data = new Uint8Array(this.binaryBuffer);

    // ====================== 解析环境数据 ======================
    this.parseEnvironmentData(uint8Data);
    // ==========================================================

    let decodeResult = '';
    if (!this.chatData.isHex) {
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
      decodeResult = Array.from(uint8Data)
        .filter(byte => byte !== 0)
        .map(byte => byte.toString(16).toUpperCase().padStart(2, '0'))
        .join(' ');
    }
    if (decodeResult) {
      this.chatData.chatDataList.push({
        time: this.formatDate(currentDate),
        data: decodeResult
      });
      PersistenceV2.save('CHATDATA_KEY');
      console.info(TAG, `存入数据: ${decodeResult}`);
    }
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


  // 【修改】定义接收数据的回调函数 (从GATT同步逻辑)
  read = (dataBuffer: ArrayBuffer) => {
    // 不再直接解码，而是交给带粘包处理的函数
    this.handleReceivedData(dataBuffer);
  };

  // 接收数据
  public readData() {
    try {
      socket.on('sppRead', this.clientNumber, this.read);
    } catch (err) {
      console.error(TAG, 'readData errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 断开连接
  public stopConnect() {
    console.info(TAG, 'closeSppClient ' + this.clientNumber);

    // 【新增】清理定时器和缓冲区 (从GATT同步)
    if (this.packetTimer !== -1) {
      clearTimeout(this.packetTimer);
      this.packetTimer = -1;
    }
    this.binaryBuffer = [];

    try {
      socket.off('sppRead', this.clientNumber, this.read);
    } catch (err) {
      console.error(TAG, 'off sppRead errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    try {
      socket.sppCloseClientSocket(this.clientNumber);
    } catch (err) {
      console.error(TAG, 'stopConnect errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}

export const sppClientManager: SppClientManager = new SppClientManager()