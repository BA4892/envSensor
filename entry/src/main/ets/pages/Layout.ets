import { Connection } from "./Connection";
import { AppStorageV2, curves, PersistenceV2 } from "@kit.ArkUI";
import { GlobalType } from "../models/globalType";
import { ButtonData } from "../models/buttonData";
import { ChatData } from "./ChatData";

interface tabClass {
  text: string,
  icon: ResourceStr
}

// 跳转页面入口函数
@Builder
export function LayoutBuilder() {
  Layout();
}


@ComponentV2
struct Layout {

  @Local currentIndex: number = 0 //导航选择的索引
  @Local selectIndex: number = -1 //当前按下的按钮索引，默认为-1即不存在

  @Local iconWidth:number = 26 //导航图片宽度，方便实现动画
  @Local fontWidth:number = 15 //导航字体宽度，方便实现动画
  @Local tabBackGroundColor: string = '#ffffff' //导航背景颜色，方便实现动画



  pathStack: NavPathStack = new NavPathStack();

  typeData: GlobalType = AppStorageV2.connect(GlobalType, 'TYPE_KEY', () => new GlobalType())!
  buttonData: ButtonData = PersistenceV2.connect(ButtonData, 'BUTTON_KEY', () => new ButtonData())!

  //导航栏数据
  tabData: tabClass[] = [
    {text: '设备连接', icon: $r('app.media.connection')},
    {text: '监测数据', icon: $r('app.media.sensorData')},
  ]
  @Builder titleBuilder() {
    //页面上半部分标题
    Row(){
      //顶部设备名称行
      if(this.typeData.connectType == 0)
      {
        Text('未连接设备')
          .fontColor('#FFFFFF')
          .width('100%')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      else
      {
        Text(this.typeData.connectedDeviceName + " 已连接")
          .fontColor($r('app.color.text_color'))
          .width('100%')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.head_color'))
  }

  @Builder tabBuilder(item: tabClass, index: number) {
    //底部导航构造函数
    Column({space: 5}){
      Image(item.icon)
        .width(this.selectIndex == index ? this.iconWidth : this.currentIndex == index ? 25 : 24)
        .fillColor(this.currentIndex == index ? '#00897B' :  '#707070')
        .draggable(false) //禁止图片拖动，防止用户长按导航拖出图片
      Text(item.text)
        .fontSize(this.selectIndex == index ? this.fontWidth : this.currentIndex == index ? 13 : 12)
        .fontColor(this.currentIndex == index ? '#00897B' :  '#707070')
        .animation({duration: 400}) //设置动画过渡时间单位为毫秒
    }
    .layoutWeight(1)
    .padding({top: 5, bottom: 5, left: 10, right: 10})
    .borderRadius(5)
    .backgroundColor(Color.Transparent)
    //.backgroundColor(this.selectIndex == index ? '#ffc8c8c8' : $r('app.color.bottom_color'))
    .animation({duration: 400})
    .onTouch((event: TouchEvent) => {
      if(event.type == TouchType.Down)
      {
        //按下按钮，设置选择索引为当前按下按钮索引
        this.selectIndex = index
        this.iconWidth = 23
        this.fontWidth = 12
      }
      if (event.type === TouchType.Up) {
        //松开索引重置选择索引
        this.selectIndex = -1
        this.currentIndex = index //更新导航选择索引
      }
    })
  }

  shouldHideTitleBar(){
      //判断是否需要隐藏标题行(titleBar)
      if(this.currentIndex == 4 || this.currentIndex == 3)
      {
        //处在详情界面以及专业调试的时候隐藏标题行
        return true;
      }
      return false;
  }

  build() {
    NavDestination() {
      Tabs({barPosition: BarPosition.End}) {
        ForEach(this.tabData, (item: tabClass, index: number) => {
          TabContent() {
            if(this.currentIndex == 0)
            {
              //当索引为0的时候展示设备连接页面
              Connection()
            }
            else if(this.currentIndex == 1)
            {
              //当索引为1的时候展示数据页面
              ChatData()
            }
          }
          .tabBar(this.tabBuilder(item, index))
          .backgroundColor($r('app.color.background_color')) //内容页颜色
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
        })
      }
      .barOverlap(true)
      .barBackgroundBlurStyle(BlurStyle.Thin)
      .barBackgroundColor(Color.Transparent)
      .animationMode(2) //禁用点击tab时内容的滑动动画
      .scrollable(false) //禁止左右滑动
      .backgroundColor($r('app.color.bottom_color')) //底部导航颜色
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    }
    .title(this.titleBuilder)
    .hideTitleBar(this.shouldHideTitleBar(), true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}