import { ToastUtil } from "@pura/harmony-utils";
import { SourceAdapter } from "../adapter";
import { Cover } from "../component/Cover";
import { MiniPlaybackControl } from "../component/MiniPlaybackControl";
import { Segment } from "../component/Segment";
import { TitleHeader } from "../component/TitleHeader";
import { StyleConstants } from "../constants/StyleConstants";
import { Album, Artist, Playlist, SearchResult, Song } from "../type/Adapter";
import { cover } from "../util/AdapterHelper";
import { PlaylistManager } from "../util/PlaylistManager";
import { PushPathHelper } from "../util/PushPathHelper";
import { SlideDownControl } from "../util/SlideDownController";

@Component
export struct MultiSearch {
  @Consume('NavPathStack') pageStack: NavPathStack;
  @State keywords: string = '';
  @State result: SearchResult | null = null;
  @State loading: boolean = false;
  @State currentIndex: number = -1;
  @StorageProp('bottomRect') bottomRect: number = 0
  private scrollController: Scroller = new Scroller();

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

  async search() {
    this.loading = true
    this.result = await SourceAdapter.search(this.keywords)
    this.loading = false
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }){
        Column(){
          this.Title()

          this.SearchComponent()

          Scroll(this.scrollController) {
            Column() {
              Row() {
                Text(SlideDownControl.getReturnActionText(this.currentIndex))
                  .fontColor($r('app.color.text_secondary'))
                  .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
                  .opacity(this.currentIndex >= 0 ? 1 : 0)
                  .translate({ y: this.currentIndex >= 0 ? 0 : -20 })
                  .animation({
                    duration: 250,
                    curve: Curve.FastOutSlowIn
                  })
              }
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

              if(this.result){
                if (this.result && this.result.songs) {
                  Segment({
                    title: "歌曲",
                    loading: this.loading,
                  }) {
                    ForEach(this.result.songs, (item: Song) => {
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
                }

                if (this.result && this.result.playlists) {
                  Segment({
                    title: "歌单",
                    loading: this.loading,
                  }) {
                    ForEach(this.result.playlists, (item: Playlist) => {
                      Cover({
                        src: cover(item.cover, 256),
                        title: item.name,
                        menuItems: this.generatePlaylistMenu(item)
                      })
                        .width(120)
                        .padding(4)
                        .onClick(() => {
                          PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                            const playlist = await SourceAdapter.getPlaylistDetail(item)
                            AppStorage.setOrCreate('current_playlist_data', playlist)
                          })
                        })
                    })
                  }
                }

                if (this.result && this.result.artists) {
                  Segment({
                    title: "歌手",
                    loading: this.loading,
                    radius: "100%",
                  }) {
                    ForEach(this.result.artists, (item: Artist) => {
                      Cover({
                        src: cover(item.avatar, 256),
                        title: item.name,
                        radius: "100%",
                      })
                        .width(120)
                        .padding(4)
                        .onClick(() => {
                          PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                            const artist = await SourceAdapter.getArtistDetail(item)
                            AppStorage.setOrCreate('current_playlist_data', artist)
                          })
                        })
                    })
                  }
                }

                if (this.result && this.result.albums) {
                  Segment({
                    title: "专辑",
                    loading: this.loading,
                  }) {
                    ForEach(this.result.albums, (item: Album) => {
                      Cover({
                        src: cover(item.cover, 256),
                        title: item.name,
                        subtitle: item.artists?.map(artist => artist.name).join(' / '),
                      })
                        .width(120)
                        .padding(4)
                        .onClick(() => {
                          PushPathHelper.pushPath(this.pageStack, "Playlist", async () => {
                            const album = await SourceAdapter.getAlbumDetail(item)
                            AppStorage.setOrCreate('current_playlist_data', album)
                          })
                        })
                    })
                  }
                }
              } else {
                // 占满剩余空间,以便在未搜索时可以滚动
                Blank().layoutWeight(1)
              }
            }
          }
          .expandSafeArea()
          .backToTop(true)
          .layoutWeight(1)
          .onWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState, scrollSource: ScrollSource) => {
            if (scrollState === ScrollState.Scroll) {
              const positionY = this.scrollController.currentOffset().yOffset;
              if (positionY < 0) {
                const index = SlideDownControl.calculateCurrentIndex(this.scrollController.currentOffset().yOffset, 0);
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
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          // 搜索页底部避让高度：播控组件高度(64) + 导航栏避让高度 + 播控组件下方margin值(16)
          .padding({ left: 16, right: 16, bottom: (StyleConstants.PLAYER_CONTROL_HEIGHT + 16) })
        }
        .width(StyleConstants.FULL_WIDTH)
        .height(StyleConstants.FULL_HEIGHT)

        MiniPlaybackControl()
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
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
        if (event.angle >= 0) {
          this.pageStack.pop()
        }
      })
    )
  }

  @Builder
  SearchComponent() {
    Search({ value: this.keywords, placeholder: '搜索你想要的...' })
      .searchButton('搜索')
      .onSubmit(async (value: string) => {
        this.keywords = value
        await this.search()
      })
      .margin(16)
  }

  @Builder
  Title() {
    TitleHeader({
      title: $r('app.string.search'),
      backActive: this.currentIndex === 0
    })
  }

  onMenuIconClick(index: number) {
    if (index === 0) {
      this.pageStack.pop();
    } else if (index === 1) {
      // 触发other
    }
  }
}