import { StyleConstants } from "../constants/StyleConstants"

@Component
export struct HorizontalScroll {
  @BuilderParam content: () => void


  build() {
    Scroll() {
      Row() {
        this.content()
      }
      .padding({ left: 6, right: 6 })
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.Start)
    }
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Horizontal)
    .edgeEffect(EdgeEffect.Spring)
    .width(StyleConstants.FULL_WIDTH)
  }
}