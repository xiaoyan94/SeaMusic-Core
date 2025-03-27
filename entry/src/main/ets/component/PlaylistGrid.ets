import { LazyData } from "@pie/lazy-data";
import { Playlist } from "../type/Adapter";
import { PlaylistCard } from "./PlaylistCard";

@Component
export struct PlaylistGrid {
  @Prop playlists: Playlist[] = [];
  onPlaylistSelected?: (playlist: Playlist) => void;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @State dataSource:LazyData<Playlist> = new LazyData<Playlist>(this.playlists);

  // 根据屏幕断点，确定每行展示的卡片数量
  private getGridColumns(): number {
    switch (this.currentBreakpoint) {
      case 'lg': return 5;
      case 'md': return 3;
      default: return 2;
    }
  }

  build() {
    Column() {
      if (this.playlists.length === 0) {
        // 空状态
        Column() {
          Text('暂无歌单')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        // 歌单栅格展示
        Grid() {
          LazyForEach(this.dataSource, (playlist: Playlist) => {
            GridItem() {
              PlaylistCard({
                playlist: playlist,
                onTap: (playlist: Playlist) => {
                  if (this.onPlaylistSelected) {
                    this.onPlaylistSelected(playlist);
                  }
                }
              })
            }
            .padding(8)
          })
        }
        .columnsTemplate(`repeat(${this.getGridColumns()}, 1fr)`)
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .padding(8)
      }
    }
    .width('100%')
    .expandSafeArea()
  }
}