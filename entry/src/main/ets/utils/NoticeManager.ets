import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

class NoticeManager{
  init()
  {
    let context = getContext(this) as common.UIAbilityContext;
    notificationManager.isNotificationEnabled().then((data: boolean) => {
      console.info("isNotificationEnabled success");
      if(!data){
        notificationManager.requestEnableNotification(context).then(() => {
          console.info(`requestEnableNotification success`);
        }).catch((err : BusinessError) => {
          if(1600004 == err.code){
            console.error(`requestEnableNotification refused, code is ${err.code}, message is ${err.message}`);
          } else {
            console.error(`requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
          }
        });
      }
    }).catch((err : BusinessError) => {
      console.error(`isNotificationEnabled fail, code is ${err.code}, message is ${err.message}`);
    });
  }
}

export const messageManager: NoticeManager = new NoticeManager()