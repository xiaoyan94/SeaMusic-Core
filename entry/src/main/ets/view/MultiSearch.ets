import { ToastUtil } from "@pura/harmony-utils";
import { SourceAdapter } from "../adapter";
import { Cover } from "../component/Cover";
import { MiniPlaybackControl } from "../component/MiniPlaybackControl";
import { Segment } from "../component/Segment";
import { TitleHeader } from "../component/TitleHeader";
import { StyleConstants } from "../constants/StyleConstants";
import {  Artist, Playlist, SearchResult, Song } from "../type/Adapter";
import { cover } from "../util/AdapterHelper";
import { PlaylistManager } from "../util/PlaylistManager";
import { PushPathHelper } from "../util/PushPathHelper";

@Component
export struct MultiSearch {
  @Consume('NavPathStack') pageStack: NavPathStack;
  @State keywords: string = '';
  @State result: SearchResult | null = null;
  @State loading: boolean = false;

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
      Column() {
        TitleHeader({
          title: $r('app.string.search'),
          backActive: true
        })
      }

      Column() {
        Search({ value: this.keywords, placeholder: '搜索你想要的...' })
          .searchButton('搜索')
          .onSubmit(async (value: string) => {
            this.keywords = value
            await this.search()
          })

        Scroll() {
          Column() {
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

            // if (this.result && this.result.albums) {
            //   Segment({
            //     title: "专辑",
            //     loading: this.loading,
            //   }) {
            //     ForEach(this.result.albums, (item: Album) => {
            //       Cover({
            //         src: cover(item.cover, 256),
            //         title: item.name,
            //         subtitle: item.artists?.map(artist => artist.name).join(' / '),
            //       })
            //         .width(120)
            //         .padding(4)
            //         .onClick(() => {
            //           PushPathHelper.pushPath(this.pageStack, "Album", async () => {
            //             const album = await SourceAdapter.getAlbumDetail(item)
            //             AppStorage.setOrCreate('current_playlist_data', album)
            //           })
            //         })
            //     })
            //   }
            // }
          }
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .expandSafeArea()
        .margin({ bottom: 100 })
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
      .padding(16)
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
        if (event.angle >= 0) {
          this.pageStack.pop()
        }
      })
    )
  }
}