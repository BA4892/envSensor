import { AppStorageV2, PersistenceV2 } from "@kit.ArkUI";
import { ButtonData } from "../models/buttonData";
import { common } from "@kit.AbilityKit";
import { setAutoColorMode, setDarkColorMode, setLightColorMode } from "../utils/ColorModeManager";
import { GlobalType } from "../models/globalType";

@Entry
@Component
struct Index {
  pathStack : NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!

  //持久化储存的UI数据
  buttonData: ButtonData = PersistenceV2.connect(ButtonData, 'BUTTON_KEY', () => new ButtonData())!
  //持久化储存的UI数据(获取全局数据)用于解决接收编码需要手动切换一次才生效的bug
  globalData: GlobalType = PersistenceV2.connect(GlobalType, 'GLOBAL_KEY', () => new GlobalType())!
  typeData: GlobalType = AppStorageV2.connect(GlobalType, 'TYPE_KEY', () => new GlobalType())!

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  build() {
    Navigation(this.pathStack){
    }.onAppear(() => {
      //更新一下接收编码
      this.typeData.stringCodeNum = this.globalData.stringCodeNum;
      //在切换到布局页面之前开启或关闭深色模式
      if(this.buttonData.colorMode == 0)
      {
        setAutoColorMode(this.context)
      }
      else if(this.buttonData.colorMode == 1)
      {
        setDarkColorMode(this.context)
      }
      else
      {
        setLightColorMode(this.context)
      }

      this.pathStack.pushPathByName("Layout", null, false); //软件一开始要跳转的页面
    })
    .hideNavBar(true) //不会把自己放到跳转对象里面 -> 点返回的时候不会回到该页面
  }
}