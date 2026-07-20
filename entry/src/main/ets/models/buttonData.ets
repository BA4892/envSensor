import { ButtonItemData } from "./button";
import { Type } from "@ohos.arkui.StateManagement";

@ObservedV2
export class ButtonData {
  @Type(ButtonData)
  @Trace buttonList: ButtonItemData[] = [ //所有按钮的数据
    {name: "按钮1", data: 0x00, data2: 0},
    {name: "按钮2", data: 0x01, data2: 0},
    {name: "按钮3", data: 0x00, data2: 0},
    {name: "按钮4", data: 0x00, data2: 0},
    {name: "按钮5", data: 0x00, data2: 0},
    {name: "按钮6", data: 0x00, data2: 0},
    {name: "按钮7", data: 0x00, data2: 0},
    {name: "按钮8", data: 0x00, data2: 0},
    {name: "按钮9", data: 0x00, data2: 0},
    {name: "UP", data: 0x00, data2: 0},
    {name: "LEFT", data: 0x00, data2: 0},
    {name: "OK", data: 0x00, data2: 0},
    {name: "RIGHT", data: 0x00, data2: 0},
    {name: "DOWN", data: 0x00, data2: 0},
  ]
  @Trace isEdit: boolean = false //是否开启编辑按钮模式
  @Trace isHex: boolean = false //是否为HEX接收模式
  @Trace isTen: boolean = true //是否为10进制模式，否为16进制,用于发送数据进制切换
  @Trace colorMode: number = 0 //深色模式 0为跟随系统 1为开启 2为关闭



  //重置数据方法
  rest()
  {
    this.buttonList = [ //所有按钮的数据
      {name: "按钮1", data: 0x00, data2: -1},
      {name: "按钮2", data: 0x01, data2: -1},
      {name: "按钮3", data: 0x00, data2: -1},
      {name: "按钮4", data: 0x00, data2: -1},
      {name: "按钮5", data: 0x00, data2: -1},
      {name: "按钮6", data: 0x00, data2: -1},
      {name: "按钮7", data: 0x00, data2: -1},
      {name: "按钮8", data: 0x00, data2: -1},
      {name: "按钮9", data: 0x00, data2: -1},
      {name: "UP", data: 0x00, data2: 0},
      {name: "LEFT", data: 0x00, data2: 0},
      {name: "OK", data: 0x00, data2: 0},
      {name: "RIGHT", data: 0x00, data2: 0},
      {name: "DOWN", data: 0x00, data2: 0},
    ]
  }
}