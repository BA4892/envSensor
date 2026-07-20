import { Type } from "@ohos.arkui.StateManagement";
import { ChatItemData } from "./chat";

@ObservedV2
export class ChatDataHistory {
  @Type(ChatDataHistory)
  @Trace chatDataList: ChatItemData[] = [ //所有按钮的数据

  ]
  @Trace isHex: boolean = false

  @Trace temperature: number = 0;    // 温度 (℃)
  @Trace humidity: number = 0;       // 湿度 (%RH)
  @Trace light: number = 0;          // 光照 (lx)
  @Trace airQuality: number = 0;     // 空气质量 (AQI)


  //重置数据方法
  rest()
  {
    this.chatDataList = [ //所有交互的数据
    ]
  }
}