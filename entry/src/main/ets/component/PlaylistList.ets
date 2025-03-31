import { LazyData } from "@pie/lazy-data";
import { Playlist } from "../type/Adapter";
import { ToastUtil } from '@pura/harmony-utils';
import { SourceAdapter } from '../adapter';
import { StyleConstants } from '../constants/StyleConstants';
import { cover } from '../util/AdapterHelper';
import { PlaylistManager } from '../util/PlaylistManager';
import { PushPathHelper } from '../util/PushPathHelper';

@Component
export struct PlaylistList {
  @Prop playlists: Playlist[] = [];
  onPlaylistSelected?: (playlist: Playlist) => void;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @State dataSource: LazyData<Playlist> = new LazyData<Playlist>(this.playlists);

  build() {
    Column() {
      if (this.playlists.length === 0) {
        // 空状态展示
        Column() {
          Text('暂无歌单')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        // 歌单列表展示
        List() {
          LazyForEach(this.dataSource, (playlist: Playlist) => {
            ListItem() {
              this.PlaylistItem(playlist)
            }
          })
        }
        .width('100%')
        .listDirection(Axis.Vertical)
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 16, endMargin: 16 })
        .backgroundColor($r('app.color.page_background'))
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.page_background'))
    .expandSafeArea()
  }

  @Builder
  PlaylistItem(playlist: Playlist) {
    Row() {
      // 封面图 - 现代直角设计
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(cover(playlist?.cover || '', 120))
          .width(58)
          .height(58)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
      }
      .margin({ right: 12 })

      // 歌单信息 - 层次分明的布局
      Column({ space: 12 }) {
        Text(playlist?.name || '未知歌单')
          .fontSize(15)
          .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 创建人信息
        if (playlist.creator) {
          Row({ space: 4 }) {
            Image(cover(playlist?.creator?.avatar || '', 40))
              .width(12)
              .height(12)
              .borderRadius(8)
              .backgroundColor($r('app.color.tag_background'))

            Text(playlist?.creator?.name || '未知用户')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (playlist?.size) {

              Text('·')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(`${playlist.size}首`)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 更多操作按钮
      Image($r('app.media.ic_more'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.icon_normal'))
        .opacity(0.9)
        .bindMenu(this.generatePlaylistMenu(playlist))
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, top: 0, bottom: 0 })
    .height(74)
    .backgroundColor($r('app.color.card_background'))
    .onClick(() => {
      if (this.onPlaylistSelected) {
        this.onPlaylistSelected(playlist);
      }
    })
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
      },
      {
        value: '添加到下一首播放',
        action: () => {
          PushPathHelper.loading("Playing", async () => {
            const playlistDetail = await SourceAdapter.getPlaylistDetail(playlist)
            const songs = playlistDetail?.songs?.filter(song => song.privilege.playable)
            if (!songs || songs.length === 0) {
              ToastUtil.showShort("此歌单无可播放歌曲")
              return
            }
            PlaylistManager.insertSongs(songs)
          })
        }
      }
    ]
  }
}