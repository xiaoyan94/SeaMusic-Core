import { BreakpointSystem } from '../component/BreakpointSystem'
import { Cover } from '../component/Cover'
import { MenuButton } from '../component/MenuButton'
import { StyleConstants } from '../constants/StyleConstants'
import { HomePageMenu } from '../model/HomePageMenu'
import { ComingSoon } from '../view/ComingSoon'
import { HomePageMenuData } from '../viewmodel/HomePageMenuData'
import { MenuIcon } from '../component/MenuIcon'
import { Setting } from '../view/Setting'
import { PreferencesCache } from '../util/PreferenceCache'
import { Artist, Playlist, Song, SourceConfig } from '../type/Adapter'
import { SourceAdapter } from '../adapter'
import { cover } from '../util/AdapterHelper'
import { Segment } from '../component/Segment'
import { PlayList } from '../view/Playlist'
import { ToastUtil } from '@pura/harmony-utils'
import { PushPathHelper } from '../util/PushPathHelper'
import { PlaylistManager } from '../util/PlaylistManager'
import { MiniPlaybackControl } from '../component/MiniPlaybackControl'
import { MultiSearch } from '../view/MultiSearch'
import { SlideDownControl } from '../util/SlideDownController'
import { LazyData } from '@pie/lazy-data'

// 缓存常用值以避免重复计算
const COLUMNS_TEMPLATE_LG = '1fr 1fr 1fr 1fr'
const COLUMNS_TEMPLATE_SM = '1fr 1fr'
const DEFAULT_COVER_SIZE = 256

@Entry
@Component
struct Index {
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  private breakpointSystem = new BreakpointSystem()
  private menuItems = HomePageMenuData
  private scrollController: Scroller = new Scroller()
  @State currentIndex: number = -1
  @StorageLink("user_data_source") adapters: SourceConfig[] = PreferencesCache.getUserDataSource()

  // 使用StorageLink保持数据同步
  @StorageLink("index_recommend_playlist") recommendPlaylist: Playlist[] = []
  @StorageLink("index_recommend_songs") recommendSongs: Song[] = []
  @StorageLink("index_recommend_artists") recommendArtists: Artist[] = []
  @StorageLink("index_recommend_toplist") topList: Playlist[] = []
  @State loading: boolean = true

  // 避让导航栏高度
  @StorageProp('bottomRect') bottomRect: number = 0

  // 预先计算并缓存必要的布局值
  private coverWidth: number = 120
  private segmentPadding: number = 4

  async aboutToAppear() {
    // 注册断点系统
    this.breakpointSystem.register()

    // 立即初始化数据
    this.initData()
  }

  async initData() {
    this.loading = true

    try {
      // 并行加载数据并捕获异常
      await Promise.all([
        SourceAdapter.getRecommendList(),
        SourceAdapter.getRecommendSongs(),
        SourceAdapter.getRecommendArtists(),
        SourceAdapter.getTopList(),
        SourceAdapter.getUserPlaylist()
      ])
    } catch (error) {
      console.error('Failed to load data', error)
    } finally {
      this.loading = false
    }
  }

  private generatePlaylistMenu(playlist: Playlist): Array<MenuElement> {
    return [
      {
        value: '播放此歌单',
        action: () => {
          PushPathHelper.loading("Playing", async () => {
            const playlistDetail = await SourceAdapter.getPlaylistDetail(playlist)
            const songs = playlistDetail?.songs?.filter(song => song.privilege.playable)
            if (!songs || songs.length === 0) {
              ToastUtil.showShort("此歌单无可播放歌曲")
              return
            }
            PlaylistManager.loadPlaylist(songs, songs[0])
          })
        }
      }
    ]
  }

  private generateSongMenu(song: Song): Array<MenuElement> {
    return [
      {
        value: '添加到下一首播放',
        action: () => {
          PlaylistManager.insertSongs([song])
        }
      }
    ]
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister()
  }

  @Builder
  Title() {
    Row() {
      Text($r("app.string.homepage"))
        .fontColor($r('app.color.text_title'))
        .fontWeight(StyleConstants.FONT_WEIGHT_SEVEN)
        .fontSize($r('app.float.title_font_size'))

      Row() {
        MenuIcon({
          icon: $r('app.media.ic_search'),
          active: this.currentIndex === 1
        })
          .onClick(() => {
            this.onMenuIconClick(1)
          })

        MenuIcon({
          icon: $r('app.media.ic_gearshape'),
          active: this.currentIndex === 0
        })
          .onClick(() => {
            this.onMenuIconClick(0)
          })
      }
      .height(StyleConstants.FULL_HEIGHT)
      .alignItems(VerticalAlign.Center)
    }
    .width(StyleConstants.FULL_WIDTH)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({
      left: 16,
      right: 16
    })
    .expandSafeArea()
  }

  onMenuIconClick(index: number) {
    if (index === 0) {
      this.pageStack.pushPath({ name: 'Setting' })
    } else if (index === 1) {
      this.pageStack.pushPath({ name: 'MultiSearch' })
    } else if (index === 2) {
      this.initData()
    }
  }

  @Builder
  PageMap(name: string) {
    if (name === 'ComingSoon') {
      ComingSoon()
    } else if (name === 'Setting') {
      Setting()
    } else if (name === 'Playlist') {
      PlayList()
    } else if (name === 'MultiSearch') {
      MultiSearch()
    }
  }

  // 优化滚动效果处理
  private handleScroll(_xOffset: number, _yOffset: number, scrollState: ScrollState, _scrollSource: ScrollSource) {
    // 优化滚动期间的计算频率
    if (scrollState === ScrollState.Scroll) {
      const positionY = this.scrollController.currentOffset().yOffset

      // 只有在下拉时才计算索引，减少计算量
      if (positionY < 0) {
        this.currentIndex = SlideDownControl.calculateCurrentIndex(positionY, 2)
      } else if (this.currentIndex !== -1) {
        this.currentIndex = -1
      }
    }
  }

  // 使用Builder模式优化各个部分的渲染
  @Builder
  MenuGrid() {
    Grid() {
      ForEach(this.menuItems, (item: HomePageMenu) => {
        GridItem() {
          MenuButton({
            title: item.title,
            onNavigate: () => {
              this.pageStack.pushPath({ name: item.path })
            }
          })
        }
        .padding(4)
      })
    }
    .columnsTemplate(this.currentBreakpoint === 'lg' ? COLUMNS_TEMPLATE_LG : COLUMNS_TEMPLATE_SM)
    .padding(12)
    .width(StyleConstants.FULL_WIDTH)
    .rowsGap(8)
    .columnsGap(8)
  }

  @Builder
  HeaderAnimation() {
    Row() {
      if(this.currentIndex >= 2){
        LoadingProgress()
          .width(24)
          .height(24)
          .opacity(this.currentIndex >= 1 ? 1 : 0)
          .scale({ x: this.currentIndex >= 1 ? 1 : 0.5, y: this.currentIndex >= 1 ? 1 : 0.5 })
          .animation({
            duration: 250,
            curve: Curve.FastOutSlowIn
          })
      }

      Text(SlideDownControl.getIndexActionText(this.currentIndex))
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

  @Builder
  RecommendedSongs() {
    Segment({
      title: "热门歌曲",
      actionText: "换一批",
      loading: this.loading,
      onActionClick: async () => {
        this.recommendSongs = await SourceAdapter.getRecommendSongs()
      },
    }) {
      List({ initialIndex: 0, space: 0 }) {
        LazyForEach(new LazyData(this.recommendSongs), (item: Song) => {
          ListItem() {
            Cover({
              src: cover(item.album.cover, DEFAULT_COVER_SIZE),
              title: item.name,
              subtitle: item.artists.map(artist => artist.name).join(' / '),
              menuItems: this.generateSongMenu(item)
            })
              .width(this.coverWidth)
              .padding(this.segmentPadding)
              .onClick(() => {
                PushPathHelper.loading("Playing", async () => {
                  PlaylistManager.insertSongs([item], -1, item)
                })
              })
          }
        })
      }
      .width('100%')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .cachedCount(3) // 缓存更多项以提高性能
    }
  }

  @Builder
  RecommendedPlaylists() {
    Segment({
      title: "推荐歌单",
      actionText: "换一批",
      loading: this.loading,
      onActionClick: async () => {
        this.recommendPlaylist = await SourceAdapter.getRecommendList()
      },
    }) {
      List({ initialIndex: 0, space: 0 }) {
        LazyForEach(new LazyData(this.recommendPlaylist), (item: Playlist) => {
          ListItem() {
            Cover({
              src: cover(item.cover, DEFAULT_COVER_SIZE),
              title: item.name,
              menuItems: this.generatePlaylistMenu(item)
            })
              .width(this.coverWidth)
              .padding(this.segmentPadding)
              .onClick(async () => {
                PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                  const playlist = await SourceAdapter.getPlaylistDetail(item)
                  AppStorage.setOrCreate('current_playlist_data', playlist)
                })
              })
          }
        })
      }
      .width('100%')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .cachedCount(3)
    }
  }

  @Builder
  RecommendedArtists() {
    Segment({
      title: "推荐艺人",
      actionText: "换一批",
      loading: this.loading,
      radius: "100%",
      onActionClick: async () => {
        this.recommendArtists = await SourceAdapter.getRecommendArtists()
      },
    }) {
      List({ initialIndex: 0, space: 0 }) {
        LazyForEach(new LazyData(this.recommendArtists), (item: Artist) => {
          ListItem() {
            Cover({
              src: cover(item.avatar, DEFAULT_COVER_SIZE),
              title: item.name,
              radius: "100%",
              titleAlign: HorizontalAlign.Center
            })
              .width(this.coverWidth)
              .padding(this.segmentPadding)
              .onClick(() => {
                PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                  // 歌手复用歌单UI
                  const playlist = await SourceAdapter.getArtistDetail(item)
                  AppStorage.setOrCreate('current_playlist_data', playlist)
                })
              })
          }
        })
      }
      .width('100%')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .cachedCount(3)
    }
  }

  @Builder
  TopLists() {
    Segment({
      title: "排行榜",
      loading: this.loading
    }) {
      List({ initialIndex: 0, space: 0 }) {
        LazyForEach(new LazyData(this.topList), (item: Playlist) => {
          ListItem() {
            Cover({
              src: cover(item.cover, DEFAULT_COVER_SIZE),
              title: item.name,
              subtitle: item.description,
              menuItems: this.generatePlaylistMenu(item)
            })
              .width(this.coverWidth)
              .padding(this.segmentPadding)
              .onClick(async () => {
                PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                  const playlist = await SourceAdapter.getPlaylistDetail(item)
                  AppStorage.setOrCreate('current_playlist_data', playlist)
                })
              })
          }
        })
      }
      .width('100%')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .cachedCount(3)
    }
  }

  @Builder
  EmptyDataSource() {
    Column() {
      Blank()
      Row() {
        Text("添加数据源开启云上漫游！")
          .fontWeight(StyleConstants.FONT_WEIGHT_SEVEN)
          .fontColor($r('app.color.text_hint'))
          .fontSize(16)
          .margin({ right: 8 })

        Text("点击添加")
          .fontWeight(StyleConstants.FONT_WEIGHT_SEVEN)
          .fontColor($r('app.color.text_click'))
          .fontSize(14)
          .onClick(() => {
            this.pageStack.pushPath({ name: 'Setting' })
          })
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(StyleConstants.FULL_WIDTH)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  build() {
    Column() {
      Navigation(this.pageStack) {
        Scroll(this.scrollController) {
          Column() {
            this.HeaderAnimation()
            this.MenuGrid()

            if (this.adapters.length > 0) {
              this.RecommendedSongs()
              this.RecommendedPlaylists()
              this.RecommendedArtists()
              this.TopLists()
            } else {
              this.EmptyDataSource()
            }

            // 底部填充高度 播控组件+底部导航栏避让高度
            Blank()
              .height(StyleConstants.PLAYER_CONTROL_HEIGHT + px2vp(this.bottomRect))
              .backgroundColor('transparent')
          }
          .alignItems(HorizontalAlign.Center)  // 确保内容居中对齐
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onWillScroll(this.handleScroll)
        .onScrollStop(() => {
          if (this.currentIndex >= 0) {
            this.onMenuIconClick(this.currentIndex)
            this.currentIndex = -1
          }
        })
        .expandSafeArea()
        .width('100%')  // 明确宽度

        // 底部迷你播控组件
        Stack() {
          MiniPlaybackControl()
        }
        .alignContent(Alignment.Center)
        .position({ x: 0, y: '100%' })
        .translate({ y: -100 })
        .width('100%')
      }
      .mode(NavigationMode.Stack)
      .navDestination(this.PageMap)
      .hideToolBar(true)
      .hideBackButton(true)
      .title({
        builder: this.Title(),
        height: 64,
      })
      .backgroundColor($r('app.color.page_background'))
      .height(StyleConstants.FULL_HEIGHT)
      .width(StyleConstants.FULL_WIDTH)
      .expandSafeArea()
    }
    .width('100%')
    .height('100%')
  }
}