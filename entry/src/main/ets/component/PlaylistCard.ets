import { ToastUtil } from '@pura/harmony-utils';
import { SourceAdapter } from '../adapter';
import { StyleConstants } from '../constants/StyleConstants';
import { Playlist } from '../type/Adapter';
import { cover } from '../util/AdapterHelper';
import { PlaylistManager } from '../util/PlaylistManager';
import { PushPathHelper } from '../util/PushPathHelper';
import { Cover } from './Cover';

@Component
export struct PlaylistCard {
  @Prop playlist: Playlist;
  onTap?: (playlist: Playlist) => void;
  @State isPressed: boolean = false;

  private generatePlaylistMenu(): MenuElement[] {
    return [
      {
        value: '播放此歌单',
        action: () => {
          PushPathHelper.loading("Playing", async () => {
            const playlistDetail = await SourceAdapter.getPlaylistDetail(this.playlist)
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

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Cover({
        src: cover(this.playlist?.cover || '', 256),
        radius: 12,
        menuItems: this.generatePlaylistMenu()
      })
        .width('100%')
        .height('100%')

      if (this.playlist?.size) {
        Text(`${this.playlist.size}首`)
          .fontSize(12)
          .fontColor(Color.White)
          .padding({
            left: 8,
            right: 8,
            top: 4,
            bottom: 4
          })
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .borderRadius(10)
          .position({ x: '8', y: '8' })
      }

      Column({ space: 4 }) {
        Text(this.playlist?.name || '未知歌单')
          .fontSize(14)
          .fontWeight(StyleConstants.FONT_WEIGHT_FIVE)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.playlist.creator) {
          Row() {
            Image(cover(this.playlist?.creator?.avatar || '', 50))
              .width(16)
              .height(16)
              .borderRadius(8)
              .margin({ right: 4 })

            Text(this.playlist?.creator?.name || '未知用户')
              .fontSize(12)
              .fontColor('rgba(255, 255, 255, 0.8)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({
        left: 8,
        right: 8,
        top: 8,
        bottom: 8
      })
      .backgroundColor('rgba(0, 0, 0, 0.6)')
      .backdropBlur(20)
    }
    .width('100%')
    .aspectRatio(1)
    .backgroundColor('rgba(243, 243, 243, 0.6)')
    .backdropBlur(30)
    .borderRadius(12)
    .shadow({
      color: 'rgba(0, 0, 0, 0.12)',
      radius: this.isPressed ? 15 : 30,
      offsetX: 1,
      offsetY: this.isPressed ? 0.5 : 1,
    })
    .scale({ x: this.isPressed ? 0.98 : 1.0, y: this.isPressed ? 0.98 : 1.0 })
    .animation({
      duration: 100,
      curve: Curve.EaseInOut
    })
    .clip(true)
    .onTouch((event) => {
      this.isPressed = event.type === TouchType.Down;
    })
    .onClick(() => {
      if (this.onTap) {
        this.onTap(this.playlist);
      }
    })
  }
}