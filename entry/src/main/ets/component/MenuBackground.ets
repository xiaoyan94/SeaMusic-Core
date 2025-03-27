import { AnimationConstants } from "../constants/AnimationConstants"

@Component
export struct MenuBackground {
  @Prop currentIndex: number
  @Prop isDragging: boolean

  build() {
    Circle()
      .fill($r("app.color.icon_highlight"))
      .width(36)
      .height(36)
      .opacity(this.isDragging ? 0.8 : 0)
      .position({ x: this.currentIndex >= 0 ? this.currentIndex * 44 + 4 : 0, y: 6 })
      .animation({
        duration: AnimationConstants.ANIMATION_DURATION,
        curve: Curve.EaseOut
      })
  }
}
