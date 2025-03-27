import { StyleConstants } from "../constants/StyleConstants";

@Component
export struct TitleHeader {
  @Consume('NavPathStack') pageStack: NavPathStack;
  @Prop title: ResourceStr = $r("app.string.homepage")
  @BuilderParam rightContent: () => void;
  @State isFirstPage: boolean = true
  @Prop backActive: boolean = false

  aboutToAppear() {
    this.isFirstPage = false
  }

  @Builder
  BackButton() {
    if (!this.isFirstPage) {
      Row() {
        Image($r('app.media.ic_back'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_primary'))
          .scale({ x: this.backActive ? 0.9 : 1, y: this.backActive ? 0.9 : 1 })
          .translate({ x: this.backActive ? 4 : 0 })
          .animation({
            duration: 150,
            curve: Curve.FastOutSlowIn
          })
        Text($r('app.string.back'))
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 2 })
      }
      .height(28)
      .borderRadius(14)
      .padding({ left: 6, right: 10 })
      .backgroundColor($r('app.color.back_button_normal'))
      .onClick(() => {
        this.pageStack.pop()
      })
      .scale({ x: this.backActive ? 1.05 : 1, y: this.backActive ? 1.05 : 1 })
      .animation({
        duration: 150,
        curve: Curve.FastOutSlowIn
      })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      Row() {
        Column() {
          this.BackButton()
          Text(this.title)
            .fontColor($r('app.color.text_title'))
            .fontWeight(StyleConstants.FONT_WEIGHT_SEVEN)
            .fontSize($r('app.float.title_font_size'))
            .maxLines(1)
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        if (this.rightContent) {
          this.rightContent()
        }
      }
      .width(StyleConstants.FULL_WIDTH)
      .backgroundColor(Color.Transparent)
      .height(80)
      .padding(12)
    }
  }
}