export interface BlueToothItem {
  mac: string,
  name: string,
  class: string,
  transport: string,
}

@ObservedV2
export class GlobalBlueTooth {
  @Trace blueList: BlueToothItem[] = [] //蓝牙设备数据列表

  //重置数据方法
  rest()
  {
    this.blueList = [] //蓝牙设备数据列表
  }
}