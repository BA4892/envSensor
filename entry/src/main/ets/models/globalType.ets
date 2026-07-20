@ObservedV2
export class GlobalType {
  @Trace connectedDeviceName: string = ""  // 已连接设备名称
  @Trace connectType: number = 0  // 连接状态(1为连接0为没有连接)
  @Trace TransportType: number = 0 //目标设备协议(0: SPP, 1: GATT)
  @Trace selectId: number = -1  // 点击连接的id
  @Trace heartData: number = 100  // 心跳数据
  @Trace heartTime: number = 0.5  // 心跳时间，单位为s
  @Trace heartType: number = 0  // 心跳开关标志
  @Trace stringCode: string = "GBK" //文本编码格式如: UTF-8、GBK等,默认为GBK
  @Trace stringCodeNum: number = 0 //用于编码格式选择的记忆0为GBK, 1为UTF-8
  @Trace DetectGestureType: number = 0 //用于传递握姿状态1为左手 2为右手 3为双手
  @Trace gripTypeNum: number = 0 //用于智感握姿的记忆0为不启用, 1为启用
  @Trace selectProjectID: number = 0 //用于传递选择的工程ID


  //重置数据方法
  rest()
  {
    this.connectedDeviceName = "未连接设备"  // 已连接设备名称
    this.connectType = 0  // 连接状态
    this.selectId = -1 //连接的设备在列表中的索引id
  }
}