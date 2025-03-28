import { TitleHeader } from "../component/TitleHeader";
import { StyleConstants } from "../constants/StyleConstants";
import { Playlist } from "../type/Adapter";
import { PushPathHelper } from "../util/PushPathHelper";
import { SourceAdapter } from "../adapter";
import { PlaylistGrid } from "../component/PlaylistGrid";
import { SlideDownControl } from "../util/SlideDownController";
import { MiniPlaybackControl } from "../component/MiniPlaybackControl";

@Builder
export function LibraryBuilder(){
  Library()
}

@Component
struct Library {
  @Consume('NavPathStack') pageStack: NavPathStack;
  @State currentIndex: number = -1;
  @StorageLink('user_playlist') playlists: Playlist[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @State isLoading: boolean = false;
  private scrollController: Scroller = new Scroller();

  onMenuIconClick(index: number) {
    if (index === 0) {
      this.pageStack.pop();
    } else if (index === 2) {
      // 触发刷新
      this.refreshData();
    }
  }

  async refreshData() {
    this.isLoading = true;

    try {
      this.playlists = await SourceAdapter.getUserPlaylist();
    } finally {
      this.isLoading = false;
    }
  }

  @Builder
  Title() {
    TitleHeader({
      title: $r('app.string.library'),
      backActive: this.currentIndex === 0,
    })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('暂无歌单')
        .fontSize(16)
        .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })

      Text('您还没有创建或收藏任何歌单')
        .fontSize(14)
        .fontColor($r('app.color.text_hint'))
        .margin({ bottom: 24 })

      Button() {
        Row() {
          Image($r('app.media.ic_plus'))
            .width(18)
            .height(18)
            .fillColor(Color.White)
            .margin({ right: 8 })

          Text('创建歌单')
            .fontSize(16)
            .fontColor(Color.White)
        }
      }
      .width(150)
      .height(44)
      .borderRadius(22)
      .backgroundColor('#6A5ACD')
      .onClick(() => {
        // 创建歌单的逻辑
      })
    }
    .width('100%')
    .height('70%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 标题
          this.Title()

          // 主内容
          List({ scroller: this.scrollController }) {
            ListItem() {
              Row() {
                if (this.currentIndex >= 1) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .opacity(this.currentIndex >= 1 ? 1 : 0)
                    .scale({ x: this.currentIndex >= 1 ? 1 : 0.5, y: this.currentIndex >= 1 ? 1 : 0.5 })
                    .animation({
                      duration: 250,
                      curve: Curve.FastOutSlowIn
                    })
                    .margin({ right: 8 })
                }

                Text(SlideDownControl.getLibraryActionText(this.currentIndex))
                  .fontColor($r('app.color.text_secondary'))
                  .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
                  .opacity(this.currentIndex >= 0 ? 1 : 0)
                  .translate({ y: this.currentIndex >= 0 ? 0 : -20 })
                  .animation({
                    duration: 250,
                    curve: Curve.FastOutSlowIn
                  })
              }
              .height(this.currentIndex >= 0 ? 40 : 0)
              .animation({
                duration: 250,
                curve: Curve.FastOutSlowIn
              })
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .width(StyleConstants.FULL_WIDTH)
              .padding({
                left: 16,
                right: 16
              })
            }

            // 如果没有歌单，显示空状态
            if (this.playlists.length === 0) {
              ListItem() {
                this.EmptyState()
              }
              .width('100%')
            } else {
              // 我的歌单部分
              ListItem() {
                PlaylistGrid({
                  playlists: this.playlists,
                  onPlaylistSelected: (item: Playlist) => {
                    PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                      const playlist = await SourceAdapter.getPlaylistDetail(item)
                      AppStorage.setOrCreate('current_playlist_data', playlist)
                    })
                  }
                })
                  .margin({ top: 8 })
              }
              .expandSafeArea()
              .width('100%')
            }
          }
          .backToTop(true)
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .width(StyleConstants.FULL_WIDTH)
          .height(StyleConstants.FULL_HEIGHT)
          .expandSafeArea()
          .onWillScroll((_scrollOffset: number, scrollState: ScrollState, _scrollSource: ScrollSource) => {
            if (scrollState === ScrollState.Scroll) {
              const positionY = this.scrollController.currentOffset().yOffset;
              if (positionY < 0) {
                const index = SlideDownControl.calculateCurrentIndex(this.scrollController.currentOffset().yOffset, 2);
                this.currentIndex = index;
              } else {
                this.currentIndex = -1;
              }
            }
          })
          .onScrollStop(() => {
            this.onMenuIconClick(this.currentIndex);
            this.currentIndex = -1;
          })
          .onReachEnd(() => {
            // 到达底部可以加载更多内容
            if (!this.isLoading) {
              // 加载更多逻辑
            }
          })
        }
        .width(StyleConstants.FULL_WIDTH)
        .height(StyleConstants.FULL_HEIGHT)
        .expandSafeArea()
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
      .expandSafeArea()

      Stack() {
        MiniPlaybackControl()
      }
      .alignContent(Alignment.Center)
      .position({ x: 0, y: '100%' })
      .translate({ y: -100 }) // 适当调整位置
      .width('100%')
    }
    .hideToolBar(true)
    .hideTitleBar(true)
    .backgroundColor($r('app.color.page_background'))
    .mode(NavDestinationMode.STANDARD)
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .expandSafeArea()
    .gesture(
      SwipeGesture({
        direction: SwipeDirection.Vertical,
      }).onAction((event) => {
        if (event.angle < 0) {
          // 向上滑
        } else {
          // 向下滑，返回上一页
          this.pageStack.pop();
        }
      })
    )
  }
}