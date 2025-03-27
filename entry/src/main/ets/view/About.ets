import { AppUtil, LogUtil, ToastUtil, WantUtil } from "@pura/harmony-utils"
import { StyleConstants } from "../constants/StyleConstants"
import { BusinessError } from "@kit.BasicServicesKit"

@Component
export struct About {
  @Builder
  AppInfo() {
    Column() {
      Image($r('app.media.icon'))
        .width(80)
        .height(80)
        .borderRadius(16)
        .margin({ top: 32, bottom: 16 })

      Text($r("app.string.EntryAbility_label"))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_title'))
        .margin({ bottom: 8 })

      Text(`版本 ${AppUtil.getVersionName()}`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 4 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ICPInfo() {
    Column() {
      Text('苏ICP备2025154522号-2A')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 4 })
    }
    .margin({ bottom: 32 })
    .onClick(() => {
      WantUtil.toWebBrowser("https://beian.miit.gov.cn/")
        .catch((err: BusinessError) => {
          LogUtil.error("AboutPage", "拉起失败！", err.message);
          ToastUtil.showToast("跳转到浏览器失败！");
        });
    })
  }

  // 主构建方法
  build() {
    Column() {
      this.AppInfo()

      Blank()
        .layoutWeight(1)

      this.ICPInfo()
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .expandSafeArea()
  }
}