import { PersistenceV2} from "@kit.ArkUI"
import { ChatDataHistory } from "../models/chatData"

@ComponentV2
export struct ChatData {
  //共享对话历史数据
  chatData: ChatDataHistory = PersistenceV2.connect(ChatDataHistory, 'CHATDATA_KEY', () => new ChatDataHistory())!

  // 定义正常状态样式
  @Styles
  normalStyle() {
    .scale({x: 1, y: 1})
    .opacity(1.0)
  }

  // 定义按下状态样式
  @Styles
  pressedStyle() {
    .scale({x: 0.9, y: 0.9})
    .opacity(0.9)
  }

  build() {
    Column({space: 25}) {
      // 温度卡片
      Row({space: 10}) {
        Image($r('app.media.temp'))
          .fillColor("#757575")
          .width('30%')
        Column({space: 5}) {
          Text('温度')
            .fontSize(35)
            .fontWeight(FontWeight.Bold)
            // 绑定动态数据
            Text(`${this.chatData.temperature}℃`)
            .fontSize(30)
        }
        .width('60%')
      }
      .stateStyles({
        normal: this.normalStyle,
        pressed: this.pressedStyle
      }
      )
      .animation({
        duration: 150,
        curve: Curve.FastOutSlowIn,
      })
      .borderRadius(15)
      .height('20%')
      .width('100%')
      .backgroundColor($r('app.color.panel_color'))
      .transition(
        TransitionEffect.opacity(0).animation({ delay: 200, duration: 600, curve: Curve.Smooth }).combine(
          TransitionEffect.scale({ x: 0.3, y: 0.3 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
        )
      )

      // 湿度卡片
      Row({space: 10}) {
        Image($r('app.media.hum'))
          .fillColor("#757575")
          .width('28%')
        Column({space: 5}) {
          Text('湿度')
            .fontSize(35)
            .fontWeight(FontWeight.Bold)
            // 绑定动态数据
            Text(`${this.chatData.humidity}%RH`)
            .fontSize(30)
        }
        .width('60%')
      }
      .stateStyles({
        normal: this.normalStyle,
        pressed: this.pressedStyle
      }
      )
      .animation({
        duration: 150,
        curve: Curve.FastOutSlowIn,
      })
      .padding({left: 10})
      .borderRadius(15)
      .height('20%')
      .width('100%')
      .backgroundColor($r('app.color.panel_color'))
      .transition(
        TransitionEffect.opacity(0).animation({ delay: 200, duration: 600, curve: Curve.Smooth }).combine(
          TransitionEffect.scale({ x: 0.3, y: 0.3 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
        )
      )

      // 光照卡片
      Row({space: 10}) {
        Image($r('app.media.light'))
          .fillColor("#757575")
          .width('28%')
        Column({space: 5}) {
          Text('光照强度')
            .fontSize(35)
            .fontWeight(FontWeight.Bold)
            // 绑定动态数据
            Text(`${this.chatData.light} LX`)
            .fontSize(30)
        }
        .width('60%')
      }
      .stateStyles({
        normal: this.normalStyle,
        pressed: this.pressedStyle
      }
      )
      .animation({
        duration: 150,
        curve: Curve.FastOutSlowIn,
      })
      .padding({left: 5})
      .borderRadius(15)
      .height('20%')
      .width('100%')
      .backgroundColor($r('app.color.panel_color'))
      .transition(
        TransitionEffect.opacity(0).animation({ delay: 200, duration: 600, curve: Curve.Smooth }).combine(
          TransitionEffect.scale({ x: 0.3, y: 0.3 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
        )
      )

      // 空气质量卡片
      Row({space: 10}) {
        Image($r('app.media.air'))
          .fillColor("#757575")
          .width('25%')
        Column({space: 5}) {
          Text('空气质量')
            .fontSize(35)
            .fontWeight(FontWeight.Bold)
            // 绑定动态数据
            Text(`${this.chatData.airQuality} AQI`)
            .fontSize(30)
        }
        .width('60%')
      }
      .stateStyles({
        normal: this.normalStyle,
        pressed: this.pressedStyle
      }
      )
      .animation({
        duration: 150,
        curve: Curve.FastOutSlowIn,
      })
      .padding({left: 10})
      .borderRadius(15)
      .height('20%')
      .width('100%')
      .backgroundColor($r('app.color.panel_color'))
      .transition(
        TransitionEffect.opacity(0).animation({ delay: 200, duration: 600, curve: Curve.Smooth }).combine(
          TransitionEffect.scale({ x: 0.3, y: 0.3 }).animation({ delay: 200, duration: 500, curve: Curve.Smooth })
        )
      )
    }
    .padding(10)
    .width('100%')
    .height('100%')
  }
}