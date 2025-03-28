import { ToastUtil } from "@pura/harmony-utils";
import { AlbumCoversCarousel } from "../component/AlbumCoversCarousel";
import { SongInfo } from "../component/SongInfo";
import { TitleHeader } from "../component/TitleHeader";
import { StyleConstants } from "../constants/StyleConstants";
import { Playlist, Song } from "../type/Adapter";
import { BasicPrefetcher } from '@kit.ArkUI';
import { SongDataSourcePrefetching } from "../util/SongDataSourcePrefetching";
import { BreakpointConstants } from "../constants/BreakpointConstants";
import { cover } from "../util/AdapterHelper";
import { formatRelativeTime } from "../util/String";
import { PushPathHelper } from "../util/PushPathHelper";
import { PlaylistManager, PlayMode } from "../util/PlaylistManager";
import { MiniPlaybackControl } from "../component/MiniPlaybackControl";

@Component
export struct PlayList {
  @Consume('NavPathStack') pageStack: NavPathStack;
  @State currentIndex: number = -1
  @StorageLink("current_playlist_data") playlist: Playlist | null = null
  @Watch('onBreakpointChange') @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  private songDataSource: SongDataSourcePrefetching = new SongDataSourcePrefetching(null);
  private prefetcher: BasicPrefetcher | null = null;
  private sourceOk: boolean = false;
  private scrollController: Scroller = new Scroller();
  @State isLoading: boolean = false;
  // 点击跳转后的闪烁效果索引
  @State billingIndex: number = -1
  // 是否为宽屏模式
  @State isWideScreen: boolean = false
  @StorageLink("cache_data_create_time") cacheTime: number = -1
  @StorageLink("current_playing_song") song: Song | null = null

  @Builder
  Title() {
    TitleHeader({
      title: this.playlist?.name,
      backActive: this.currentIndex === 0,
    })
  }

  aboutToAppear(): void {
    // 初始化数据源
    this.songDataSource = new SongDataSourcePrefetching(this.playlist);
    // 创建预取器
    this.prefetcher = new BasicPrefetcher(this.songDataSource);
    // 设置屏幕模式
    this.isWideScreen = this.currentBreakpoint !== BreakpointConstants.BREAKPOINT_SM;

    this.sourceOk = true;
  }

  // 监听屏幕断点变化
  onBreakpointChange() {
    this.isWideScreen = this.currentBreakpoint !== BreakpointConstants.BREAKPOINT_SM;
  }

  aboutToDisappear(): void {
    // 清空
    this.playlist = null;
    this.prefetcher = null;
    this.sourceOk = false;
  }

  calculateCurrentIndex(offset: number) {
    offset = Math.abs(offset)
    if (offset < 40) {
      return -1
    }
    // const index = Math.floor(offset / 80)
    // return Math.min(Math.max(index, 0), 1)
    return 0
  }

  onMenuIconClick(index: number) {
    if (index === 0) {
      this.pageStack.pop()
    }
  }

  @Builder
  PlayListAction() {
    Row() {
      // 主要播放按钮（占据大部分空间）
      Row() {
        Image($r('app.media.ic_repeat'))
          .width(22)
          .height(22)
          .fillColor($r('app.color.text_primary'))
        Text('播放全部')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 8 })
      }
      .height(48)
      .layoutWeight(1)
      .borderRadius(12)
      .backgroundColor($r('app.color.button_background'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (this.playlist?.songs && this.playlist.songs.length > 0) {
          // 寻找第一个可以播放的歌曲
          const song = this.playlist.songs.find(song => song.privilege.playable)
          this.handlePlaylistPlayAll(song || this.playlist.songs[0])
          PlaylistManager.switchPlayMode(PlayMode.LOOP)
        }
      })

      // 间隔
      Blank()
        .width(8)

      // 更多选项按钮（正方形）
      Column() {
        Image($r('app.media.ic_more'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_primary'))
      }
      .width(48)
      .height(48)
      .borderRadius(12)
      .backgroundColor($r('app.color.button_background'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 显示更多选项的逻辑
        ToastUtil.showShort('即将支持更多操作')
      })
    }
    .width(StyleConstants.FULL_WIDTH)
    .padding({
      left: 16,
      right: 16,
      top: 16,
      bottom: 16
    })
  }

  // 歌曲列表逻辑
  @Builder
  SongListSection() {
    Row() {
      Column() {
        Text('歌曲列表')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_secondary'))
      }

      // 显示缓存提醒
      if (this.cacheTime !== -1) {
        Column() {
          Row() {
            Text('缓存于')
              .fontSize(14)
              .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
              .fontColor($r('app.color.text_hint'))
            Text(`${formatRelativeTime(this.cacheTime)}`)
              .fontSize(14)
              .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
              .fontColor($r('app.color.text_secondary'))
          }
        }
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width(StyleConstants.FULL_WIDTH)
    .padding({
      left: 24,
      right: 16,
    })

    List({ scroller: this.scrollController }) {
      ListItem() {
        Row() {
          Text(this.currentIndex >= 0 ? '释放返回上一页' : '')
            .fontColor($r('app.color.text_secondary'))
            .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
            .margin({ left: 8 })
            .opacity(this.currentIndex >= 0 ? 1 : 0)
            .translate({ y: this.currentIndex >= 0 ? 0 : -20 })
            .animation({
              duration: 250,
              curve: Curve.FastOutSlowIn
            })
        }
        .margin({ top: 16 })
        .height(this.currentIndex >= 0 ? 24 : 0)
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

      LazyForEach(this.songDataSource, (song: Song, index: number) => {
        ListItem() {
          SongInfo({
            song: song,
            index: index,
            active: this.song?.id === song.id,
            highlight: this.billingIndex === index,
            onTap: (song: Song) => {
              this.onSongTap(song, index);
            }
          })
        }
        .key(`${song.id}-${index}`)
        .margin({ bottom: 4 })
        .expandSafeArea()
      }, (song: Song, index: number) => `${song.id}-${index}`)
    }
    .margin({ bottom: 64 })
    .height(StyleConstants.FULL_HEIGHT)
    .width(StyleConstants.FULL_WIDTH)
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
    .listDirection(Axis.Vertical)
    .divider({ strokeWidth: 0 })
    .cachedCount(5)
    .onScrollIndex((firstIndex: number, lastIndex: number) => {
      if (this.prefetcher) {
        this.prefetcher.visibleAreaChanged(firstIndex, lastIndex);
      }
    })
    .onWillScroll((_scrollOffset: number, scrollState: ScrollState, _scrollSource: ScrollSource) => {
      if (scrollState === ScrollState.Scroll) {
        const positionY = this.scrollController.currentOffset().yOffset
        if (positionY < 0) {
          const index = this.calculateCurrentIndex(this.scrollController.currentOffset().yOffset)
          this.currentIndex = index
        } else {
          this.currentIndex = -1
        }
      }
    })
    .onScrollStop(() => {
      this.onMenuIconClick(this.currentIndex)
      this.currentIndex = -1
    })
    .onReachEnd(async () => {
      if (this.isLoading || !this.sourceOk) {
        return;
      }

      this.isLoading = true;
      try {
        const hasMoreData = await this.songDataSource.loadMoreData(10);
        if (!hasMoreData) {
          return
        }
      } finally {
        this.isLoading = false;
      }
    })
    .expandSafeArea()
  }

  // 处理封面点击，确保在任何屏幕模式下都能正确滚动和高亮
  private handleCoverClick(_song: Song, index: number) {
    // 确保数据被预取
    this.songDataSource.prefetch(index);

    // 触发滚动到对应位置
    this.scrollController.scrollToIndex(index, true);

    // 设置高亮效果
    this.billingIndex = index;

    // 延迟重置闪烁索引
    setTimeout(() => {
      this.billingIndex = -1;
    }, 1000);
  }

  @Builder
  AlbumCoversSection() {
    if (this.playlist?.songs && this.playlist.songs.length >= 50) {
      Column() {
        AlbumCoversCarousel({
          coverSize: 56,
          scrollSpeed: 60,
          rows: 3,
          songs: this.playlist?.songs.slice(0, 99) || [],
          onCoverClick: (song: Song, index: number) => {
            this.handleCoverClick(song, index);
          }
        })
      }
      .width(StyleConstants.FULL_WIDTH)
      .margin({ top: 8, bottom: 8 })
    }
  }

  handlePlaylistPlayAll(song: Song) {
    PushPathHelper.loading("Playing", async () => {
      PlaylistManager.loadPlaylist(this.playlist?.songs?.filter(song => song.privilege.playable) || [], song);
    })
  }

  onSongTap(song: Song, _index: number) {
    this.handlePlaylistPlayAll(song);
  }

  // 小屏幕布局
  @Builder
  MobileLayout() {
    Column() {
      // 1. 轮播图部分（如果符合条件）
      this.AlbumCoversSection()

      // 2. 播放操作栏
      this.PlayListAction()

      // 3. 歌曲列表组件
      this.SongListSection()
    }
    .width(StyleConstants.FULL_WIDTH)
  }

  // 左侧面板 - 宽屏模式（大卡片设计，歌曲数量在底部）
  @Builder
  LeftPanel() {
    Column() {
      if (this.playlist) {
        // 创建一个填满整个区域的大卡片
        Column() {
          // 歌单封面
          Column() {
            // 封面图
            Image(cover(this.playlist.cover || '', 300))
              .width(StyleConstants.FULL_WIDTH)
              .aspectRatio(1)// 保持正方形比例
              .borderRadius(16)
              .backgroundColor($r('app.color.setting_button_normal'))
          }
          .margin({ top: 20, bottom: 16 })
          .width('80%')

          // 歌单信息
          Column({ space: 12 }) {
            // 创作者信息（如果有）
            if (this.playlist.creator) {
              Row() {
                Text('创建者: ')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                Text(this.playlist.creator.name || '未知')
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Medium)
              }
              .justifyContent(FlexAlign.Center)
            }

            // 歌单描述（如果有）
            if (this.playlist.description) {
              Column({ space: 8 }) {
                Text('歌单简介')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ top: 8, bottom: 4 })

                Text(this.playlist.description.length > 50 ? `${this.playlist.description.slice(0, 50)}...` : this.playlist.description)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .width('90%')
                  .textAlign(TextAlign.Center)
              }
              .alignItems(HorizontalAlign.Center)
              .margin({ top: 8 })
              .width(StyleConstants.FULL_WIDTH)
            }
          }
          .width(StyleConstants.FULL_WIDTH)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 16, right: 16 })
          .layoutWeight(1) // 使中间部分可以自适应伸缩

          // 歌曲数量 - 放在底部
          Row() {
            Text('共')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.playlist.songs?.length || 0}`)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Bold)
            Text('首歌曲')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .justifyContent(FlexAlign.Center)
          .padding({ bottom: 24, top: 12 })
          .width(StyleConstants.FULL_WIDTH)
        }
        .width(StyleConstants.FULL_WIDTH)
        .height('calc(100% - 200px)')
        .backgroundColor($r('app.color.card_background'))
        .opacity(0.8)
        .borderRadius(24)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween) // 使用SpaceBetween将歌曲数量推到底部
      }
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .padding(16)
  }

  // 右侧面板 - 宽屏模式
  @Builder
  RightPanel() {
    Column() {
      // 1. 播放操作栏
      this.PlayListAction()

      // 2. 歌曲列表组件
      this.SongListSection()
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }

  // 宽屏布局
  @Builder
  WideScreenLayout() {
    Row() {
      // 左侧面板 (1份宽度)
      Column() {
        this.LeftPanel()
      }
      .width('33%') // 1/3 的宽度
      .height(StyleConstants.FULL_HEIGHT)
      .backgroundColor($r('app.color.page_background'))

      // 右侧面板 (2份宽度)
      Column() {
        this.RightPanel()
      }
      .width('67%') // 2/3 的宽度
      .height(StyleConstants.FULL_HEIGHT)
      .backgroundColor($r('app.color.page_background'))
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }

  build() {
    NavDestination() {
      Column() {
        // 标题区域
        this.Title()

        if (this.playlist && this.playlist.songs && this.playlist.songs.length > 0) {
          // 根据屏幕宽度选择布局
          if (this.isWideScreen) {
            // 宽屏布局
            this.WideScreenLayout()
          } else {
            // 标准移动端布局
            this.MobileLayout()
          }
        } else {
          // 显示空状态
          Column() {
            Text('暂无歌曲')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          .width(StyleConstants.FULL_WIDTH)
          .height('80%')
          .justifyContent(FlexAlign.Center)
        }
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
    .expandSafeArea()
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .gesture(
      SwipeGesture({
        direction: SwipeDirection.Vertical,
      }).onAction((event) => {
        if (event.angle < 0) {
          // 向上滑
        } else {
          // 向下滑，返回上一页
          this.pageStack.pop()
        }
      })
    )
  }
}