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
        .margin({ bottom: 24 })

      // Official links section
      Row() {
        Column() {
          Button() {
            Row() {
              Text('开源仓库')
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .height(40)
          .backgroundColor($r('app.color.tag_background'))
          .borderRadius(20)
          .width('100%')
          .onClick(() => {
            WantUtil.toWebBrowser("https://github.com/Edge-Music")
              .catch((err: BusinessError) => {
                LogUtil.error("AboutPage", "拉起失败！", err.message);
                ToastUtil.showToast("跳转到GitHub失败！");
              });
          })
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          Button() {
            Row() {
              Text('官方网站')
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .height(40)
          .backgroundColor($r('app.color.tag_background'))
          .borderRadius(20)
          .width('100%')
          .onClick(() => {
            WantUtil.toWebBrowser("https://music.yby.zone/")
              .catch((err: BusinessError) => {
                LogUtil.error("AboutPage", "拉起失败！", err.message);
                ToastUtil.showToast("跳转到官网失败！");
              });
          })
        }
        .layoutWeight(1)
        .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  Contributors() {
    Column() {
      // Section Title
      Text('开发及贡献者')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 32, bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // Core Team Section
      Column() {
        Row() {
          Text('作者')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width(80)

          Text('襟江带海')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 })

        Row() {
          Text('核心开发')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width(80)

          Text('祭之时、可以')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 20 })

        // UI/Design Team Section
        Text('UI & Logo 设计')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 12 })
          .alignSelf(ItemAlign.Start)

        Flex({ justifyContent: FlexAlign.Start, wrap: FlexWrap.Wrap }) {
          Column() {
            Text('△皂')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .margin({ right: 24, bottom: 12 })
          }

          Column() {
            Text('科蓝kl')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 12 })
          }
        }

        // Community Acknowledgment
        Divider()
          .color($r('app.color.divider'))
          .opacity(0.6)
          .margin({ top: 4, bottom: 16 })

        Text('特别感谢')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 12 })
          .alignSelf(ItemAlign.Start)

        Text('全体云享社群友及使用者')
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 4 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.background_gray'))
      .borderRadius(12)
    }
    .padding({ left: 16, right: 16 })
    .width('100%')
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

      this.Contributors()

      Blank()
        .layoutWeight(1)

      this.ICPInfo()
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .expandSafeArea()
  }
}