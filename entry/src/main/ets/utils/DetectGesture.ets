import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalType } from '../models/globalType';
import { AppStorageV2 } from '@kit.ArkUI';

class DetectGestureManager {
  //共享数据
  typeData: GlobalType = AppStorageV2.connect(GlobalType, 'TYPE_KEY', () => new GlobalType())!

  callback:Callback<motion.HoldingHandStatus> = (data:motion.HoldingHandStatus) => {
    this.typeData.DetectGestureType = data; //赋值状态数据让所有页面都能共享
  };

  public startRead(){
    try {
      motion.on('holdingHandChanged', this.callback);
      console.info("on succeeded");
    } catch (err) {
      let error = err as BusinessError;
      console.error("Failed on and err code is " + error.code);
    }
  }

  public stopRead(){
    try {
      motion.off('holdingHandChanged');
      console.info("off succeeded");
    } catch (err) {
      let error = err as BusinessError;
      console.error("Failed off and err code is " + error.code);
    }
  }
}

export const detectGestureManager: DetectGestureManager = new DetectGestureManager()