@Component
export struct AnimatedDots {
  @State scale1: number = 1
  @State scale2: number = 1
  @State scale3: number = 1
  private timerId: number = -1

  private startAnimation() {
    let frameCount = 0
    this.timerId = setInterval(() => {
      frameCount++
      // 使用正弦函数创建平滑的跳动效果
      this.scale1 = 1 + 0.5 * Math.abs(Math.sin(frameCount * 0.1))
      this.scale2 = 1 + 0.5 * Math.abs(Math.sin(frameCount * 0.1 + 1))
      this.scale3 = 1 + 0.5 * Math.abs(Math.sin(frameCount * 0.1 + 2))
    }, 16) // 约60fps
  }

  aboutToAppear() {
    this.startAnimation()
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
  }

  build() {
    Row() {
      Circle()
        .width(4)
        .height(4)
        .margin({ left: 2 })
        .fill(Color.White)
        .scale({ y: this.scale1 })
      Circle()
        .width(4)
        .height(4)
        .margin({ left: 2 })
        .fill(Color.White)
        .scale({ y: this.scale2 })
      Circle()
        .width(4)
        .height(4)
        .margin({ left: 2 })
        .fill(Color.White)
        .scale({ y: this.scale3 })
    }
  }
}