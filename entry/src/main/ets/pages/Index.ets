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
import { deviceInfo } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @StorageProp('deviceTypeInfo') deviceTypeInfo: string = 'phone'
  private breakpointSystem = new BreakpointSystem()
  private menuItems = HomePageMenuData
  private scrollController: Scroller = new Scroller()
  @State currentIndex: number = -1
  @StorageLink("user_data_source") adapters: SourceConfig[] = PreferencesCache.getUserDataSource()
  // Segment 数据
  @StorageLink("index_recommend_playlist") recommendPlaylist: Playlist[] = []
  @StorageLink("index_recommend_songs") recommendSongs: Song[] = []
  @StorageLink("index_recommend_artists") recommendArtists: Artist[] = []
  @StorageLink("index_recommend_toplist") topList: Playlist[] = []
  @State loading: boolean = true

  async aboutToAppear() {
    this.breakpointSystem.register()
    await this.initData()
    this.deviceTypeInfo=deviceInfo.deviceType
  }

  async initData() {
    this.loading = true
    await Promise.all([
      SourceAdapter.getRecommendList(),
      SourceAdapter.getRecommendSongs(),
      SourceAdapter.getRecommendArtists(),
      SourceAdapter.getTopList(),
      SourceAdapter.getUserPlaylist()
    ])
    this.loading = false
  }

  private generatePlaylistMenu(playlist: Playlist) {
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
      },
      // {
      //   value: '收藏此歌单',
      //   action: () => {
      //   }
      // }
    ] as MenuElement[]
  }

  private generateSongMenu(song: Song) {
    return [
      {
        value: '添加到下一首播放',
        action: () => {
          PlaylistManager.insertSongs([song])
        }
      },
      // {
      //   value: '收藏到歌单',
      //   action: () => {
      //   }
      // }
    ] as MenuElement[]
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister()
  }

  calculateCurrentIndex(offset: number) {
    offset = Math.abs(offset)
    if (offset < 40) {
      return -1
    }
    const index = Math.floor(offset / 72)
    return Math.min(Math.max(index, 0), 4)
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
    } else if (index === 3) {
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

  build() {
    Column() {
      Navigation(this.pageStack) {
        Scroll(this.scrollController) {
          Column() {
            Row() {
              LoadingProgress()
                .width(24)
                .height(24)
                .opacity(this.currentIndex >= 2 ? 1 : 0)
                .scale({ x: this.currentIndex >= 2 ? 1 : 0.5, y: this.currentIndex >= 2 ? 1 : 0.5 })
                .animation({
                  duration: 250,
                  curve: Curve.FastOutSlowIn
                })

              Text(this.currentIndex === 2 ? '继续下拉刷新...' : '释放以刷新...')
                .fontColor($r('app.color.text_secondary'))
                .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
                .margin({ left: 8 })
                .opacity(this.currentIndex >= 2 ? 1 : 0)
                .translate({ y: this.currentIndex >= 2 ? 0 : -20 })
                .animation({
                  duration: 250,
                  curve: Curve.FastOutSlowIn
                })
            }
            .height(this.currentIndex >= 2 ? 40 : 0)
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
            .columnsTemplate(this.currentBreakpoint === 'lg' ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
            .padding(12)
            .width(StyleConstants.FULL_WIDTH)
            .rowsGap(8)
            .columnsGap(8)

            if (this.adapters.length > 0) {
              Segment({
                title: "热门歌曲",
                actionText: "换一批",
                loading: this.loading,
                onActionClick: async () => {
                  this.recommendSongs = await SourceAdapter.getRecommendSongs()
                },
              }) {
                ForEach(this.recommendSongs, (item: Song) => {
                  Cover({
                    src: cover(item.album.cover, 256),
                    title: item.name,
                    subtitle: item.artists.map(artist => artist.name).join(' / '),
                    menuItems: this.generateSongMenu(item)
                  })
                    .width(120)
                    .padding(4)
                    .onClick(() => {
                      PushPathHelper.loading("Playing", async () => {
                        PlaylistManager.insertSongs([item], -1, item)
                      })
                    })
                })
              }

              Segment({
                title: "推荐歌单",
                actionText: "换一批",
                loading: this.loading,
                onActionClick: async () => {
                  this.recommendPlaylist = await SourceAdapter.getRecommendList()
                },
              }) {
                ForEach(this.recommendPlaylist, (item: Playlist) => {
                  Cover({
                    src: cover(item.cover, 256),
                    title: item.name,
                    menuItems: this.generatePlaylistMenu(item)
                  })
                    .width(120)
                    .padding(4)
                    .onClick(async () => {
                      PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                        const playlist = await SourceAdapter.getPlaylistDetail(item)
                        AppStorage.setOrCreate('current_playlist_data', playlist)
                      })
                    })
                })
              }

              Segment({
                title: "推荐艺人",
                actionText: "换一批",
                loading: this.loading,
                radius: "100%",
                onActionClick: async () => {
                  this.recommendArtists = await SourceAdapter.getRecommendArtists()
                },
              }) {
                ForEach(this.recommendArtists, (item: Artist) => {
                  Cover({
                    src: cover(item.avatar, 256),
                    title: item.name,
                    radius: "100%",
                    titleAlign: HorizontalAlign.Center
                  })
                    .width(120)
                    .padding(4)
                    .onClick(() => {
                      PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                        // 歌手复用歌单UI
                        const playlist = await SourceAdapter.getArtistDetail(item)
                        AppStorage.setOrCreate('current_playlist_data', playlist)
                      })
                    })
                })
              }

              Segment({
                title: "排行榜",
                loading: this.loading
              }) {
                ForEach(this.topList, (item: Playlist) => {
                  Cover({
                    src: cover(item.cover, 256),
                    title: item.name,
                    subtitle: item.description,
                    menuItems: this.generatePlaylistMenu(item)
                  })
                    .width(120)
                    .padding(4)
                    .onClick(async () => {
                      PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                        const playlist = await SourceAdapter.getPlaylistDetail(item)
                        AppStorage.setOrCreate('current_playlist_data', playlist)
                      })
                    })
                })
              }
            } else {
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
          }
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onWillScroll((_xOffset: number, _yOffset: number, scrollState: ScrollState, _scrollSource: ScrollSource) => {
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
        .expandSafeArea()


        Stack() {
          MiniPlaybackControl()
        }
        .alignContent(Alignment.Center)
        .position({ x: 0, y: '100%' })
        .translate({ y: -100 }) // 适当调整位置
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
  }
}