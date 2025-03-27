import { StyleConstants } from "../constants/StyleConstants";
import { avPlayerManager } from "../util/AVPlayerManager";
import { PreferencesCache } from "../util/PreferenceCache";

interface LyricsLine {
  time: number; // 时间点（毫秒）
  text: string; // 原文歌词
  translation?: string; // 翻译/音译
  showTranslation?: boolean; // 是否显示翻译
}

interface LyricStyle {
  fontWeight: FontWeight;
  fontColor: string | Color;
  background: string;
  opacity: number;
}

@Component
export struct LyricsView {
  @Watch("onTimeUpdate") @Prop currentTimeMs: number // 当前歌曲播放时间（毫秒）
  @Watch('onLyricsChanged') @Prop lyrics: string = '' // 标准的lrc歌词格式
  @Prop translationLyrics: string = '' // 翻译/音译歌词
  @State private parsedLyrics: Array<LyricsLine> = []
  @State private currentIndex: number = -1
  @State private isAnimating: boolean = false
  @State private showTranslation: boolean = PreferencesCache.showTranslationLyric()
  @State private hasTranslation: boolean = false // 是否有翻译歌词
  private scroller: Scroller = new Scroller()
  private readonly ANIMATION_DURATION: number = 300
  private readonly SCROLL_ANIMATION_DURATION: number = 400
  private readonly PRE_HIGHLIGHT_TIME: number = 500 // 提前高亮时间

  aboutToAppear() {
    this.parseLyrics()
  }

  // 解析LRC格式原文歌词
  private parseLyrics() {
    if (!this.lyrics) {
      this.parsedLyrics = []
      this.hasTranslation = false
      return
    }

    // 首先解析原始歌词
    const originalLines = this.parseLyricsText(this.lyrics)

    // 检查是否有翻译歌词
    if (this.translationLyrics && this.translationLyrics.trim() !== '') {
      this.hasTranslation = true
      const translationLines = this.parseLyricsText(this.translationLyrics)

      // 合并原始歌词和翻译歌词
      this.parsedLyrics = this.mergeLyrics(originalLines, translationLines)
    } else {
      this.hasTranslation = false
      this.parsedLyrics = originalLines
    }
  }

  // 解析单个LRC文本
  private parseLyricsText(lrcText: string): LyricsLine[] {
    const lines = lrcText.split('\n')
    const timeRegex = /\[(\d{2}):(\d{2})\.(\d{2,3})\]/
    const tempLyrics: LyricsLine[] = []

    lines.forEach(line => {
      const match = timeRegex.exec(line)
      if (match) {
        const minutes = parseInt(match[1])
        const seconds = parseInt(match[2])
        const ms = parseInt(match[3])
        // 统一转换为毫秒
        const time = minutes * 60 * 1000 + seconds * 1000 + (ms < 100 ? ms * 10 : ms)
        const text = line.replace(timeRegex, '').trim()

        if (text) {
          tempLyrics.push({
            time: time,
            text: text
          })
        }
      }
    })

    // 按时间排序
    return tempLyrics.sort((a, b) => a.time - b.time)
  }

  // 合并原始歌词和翻译歌词
  private mergeLyrics(originalLyrics: LyricsLine[], translationLyrics: LyricsLine[]): LyricsLine[] {
    // 创建结果数组，初始使用原始歌词
    const mergedLyrics: LyricsLine[] = JSON.parse(JSON.stringify(originalLyrics))

    // 为每一行原始歌词寻找最接近的翻译行
    mergedLyrics.forEach((line, _index) => {
      // 寻找时间最接近的翻译
      let closestTranslation: LyricsLine | null = null
      let minTimeDiff = Number.MAX_VALUE

      translationLyrics.forEach(transLine => {
        const timeDiff = Math.abs(transLine.time - line.time)
        // 如果找到时间差更小的翻译行
        if (timeDiff < minTimeDiff) {
          minTimeDiff = timeDiff
          closestTranslation = transLine
        }
      })

      // 如果找到匹配的翻译，且时间差在合理范围内（例如300毫秒）
      if (closestTranslation !== null && minTimeDiff <= 300) {
        line.translation = (closestTranslation as LyricsLine).text
      }
    })

    return mergedLyrics
  }

  // 监听当前播放时间更新
  onTimeUpdate() {
    this.updateCurrentLyric()
  }

  onLyricsChanged() {
    this.parseLyrics()
  }

  // 更新当前歌词索引并处理滚动
  private updateCurrentLyric() {
    // 添加预判时间提前高亮
    const adjustedTime = this.currentTimeMs + this.PRE_HIGHLIGHT_TIME

    // 查找当前应显示的歌词
    let newIndex = -1
    for (let i = 0; i < this.parsedLyrics.length; i++) {
      if (i === this.parsedLyrics.length - 1) {
        // 最后一句
        if (adjustedTime >= this.parsedLyrics[i].time) {
          newIndex = i
        }
      } else {
        // 非最后一句，检查是否在当前时间范围内
        if (adjustedTime >= this.parsedLyrics[i].time && adjustedTime < this.parsedLyrics[i + 1].time) {
          newIndex = i
          break
        }
      }
    }

    // 如果索引变化且不在动画中，则更新并滚动
    if (newIndex !== -1 && newIndex !== this.currentIndex && !this.isAnimating) {
      this.isAnimating = true
      this.currentIndex = newIndex
      this.scrollToLyric(newIndex)
    }
  }

  // 滚动到指定歌词位置
  private scrollToLyric(index: number) {
    if (index < 0) {
      return
    }

    // 保持在视图中间偏上的位置，很显然这是一个经验修正
    const targetIndex = Math.max(0, index - (5 * (this.showTranslation ? 0.6 : 1)))

    animateTo({
      duration: this.SCROLL_ANIMATION_DURATION,
      curve: Curve.EaseOut,
      onFinish: () => {
        this.isAnimating = false
      }
    }, () => {
      this.scroller.scrollToIndex(targetIndex)
    })
  }

  // 歌词点击处理
  private handleLyricClick(time: number, index: number) {
    // 更新UI状态
    this.isAnimating = true
    this.currentIndex = index

    // 滚动到目标位置
    this.scrollToLyric(index)

    // 跳转到指定时间
    avPlayerManager.seek(time)
  }

  // 切换翻译显示状态
  private toggleTranslation() {
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.showTranslation = !this.showTranslation
      PreferencesCache.showTranslationLyric(this.showTranslation)
    })
  }

  // 获取歌词显示样式
  private getLyricStyle(index: number) {
    const isCurrent = index === this.currentIndex

    return ({
      fontWeight: isCurrent ? StyleConstants.FONT_WEIGHT_SEVEN : StyleConstants.FONT_WEIGHT_FIVE,
      fontColor: isCurrent ? Color.White : 'rgba(255, 255, 255, 0.6)',
      background: isCurrent ? 'rgba(255, 255, 255, 0.1)' : 'transparent',
      opacity: isCurrent ? 1 : 0.7
    } as LyricStyle)
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        if (this.parsedLyrics.length === 0) {
          Text('暂无歌词')
            .fontSize(18)
            .fontColor('rgba(255, 255, 255, 0.5)')
            .margin(16)
        } else {
          List({ scroller: this.scroller }) {
            ForEach(this.parsedLyrics, (item: LyricsLine, index) => {
              ListItem() {
                Column() {
                  // 原文歌词
                  Text(item.text)
                    .fontSize(20)
                    .fontWeight(this.getLyricStyle(index).fontWeight)
                    .fontColor(this.getLyricStyle(index).fontColor)
                    .margin({ top: 4, bottom: this.showTranslation && item.translation ? 0 : 4 })
                    .padding({
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 8
                    })
                    .textAlign(TextAlign.Center)
                    .borderRadius(8)
                    .backgroundColor(this.getLyricStyle(index).background)
                    .opacity(this.getLyricStyle(index).opacity)
                    .animation({
                      duration: this.ANIMATION_DURATION,
                      curve: Curve.EaseInOut
                    })

                  // 翻译/音译歌词 (仅当启用显示翻译且该行有翻译时显示)
                  if (this.showTranslation && item.translation) {
                    Text(item.translation)
                      .fontSize(16)
                      .fontWeight(FontWeight.Normal)
                      .fontColor(this.getLyricStyle(index).fontColor)
                      .opacity(this.getLyricStyle(index).opacity * 0.9)
                      .margin({ bottom: 4 })
                      .padding({
                        left: 16,
                        right: 16,
                        top: 4,
                        bottom: 4
                      })
                      .textAlign(TextAlign.Center)
                      .borderRadius(8)
                      .backgroundColor('transparent')
                      .animation({
                        duration: this.ANIMATION_DURATION,
                        curve: Curve.EaseInOut
                      })
                  }
                }
                .width(StyleConstants.FULL_WIDTH)
                .onClick(() => {
                  this.handleLyricClick(item.time, index)
                })
              }
              .width(StyleConstants.FULL_WIDTH)
            })
          }
          .width(StyleConstants.FULL_WIDTH)
          .height(StyleConstants.FULL_HEIGHT)
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .expandSafeArea()
        }
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)

      if (this.hasTranslation) {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_translate'))
            .width(24)
            .height(24)
            .fillColor(this.showTranslation ? Color.White : 'rgba(255, 255, 255, 0.6)')
        }
        .width(48)
        .height(48)
        .backgroundColor(this.showTranslation ? 'rgba(255, 255, 255, 0.2)' : Color.Transparent)
        .margin({ bottom: 24, right: 24 })
        .position({ x: '100%', y: '100%' })
        .translate({ x: -72, y: -72 })
        .onClick(() => this.toggleTranslation())
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .expandSafeArea()
  }
}