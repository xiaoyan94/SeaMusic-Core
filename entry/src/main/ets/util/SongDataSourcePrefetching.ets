import { LazyData } from '@pie/lazy-data';
import { ID, Playlist, Song } from '../type/Adapter';
import { IDataSourcePrefetching } from '@kit.ArkUI';
import { LogUtil } from '@pura/harmony-utils';

// 实现预加载数据源
export class SongDataSourcePrefetching extends LazyData<Song> implements IDataSourcePrefetching {
  private playlist: Playlist | null = null;
  private isLoadingMoreData: boolean = false;
  private loadedSongIds: Set<ID> = new Set(); // 跟踪已加载的歌曲ID

  constructor(playlist: Playlist | null) {
    super();
    this.playlist = playlist;
    this.loadInitialData();
  }

  // 初始加载数据
  private loadInitialData(): void {
    // 初始加载前30首歌曲
    if (this.playlist?.songs) {
      const initialCount = Math.min(30, this.playlist.songs.length);
      const initialSongs = this.playlist.songs.slice(0, initialCount);

      // 重置已加载ID集合
      this.loadedSongIds.clear();

      // 设置初始数据
      this.setData(initialSongs);

      // 记录已加载的歌曲ID
      initialSongs.forEach(song => {
        if (song.id) {
          this.loadedSongIds.add(song.id);
        }
      });
    }
  }

  // 重新加载数据源
  reloadData(playlist: Playlist | null): void {
    this.playlist = playlist;
    this.loadInitialData();
  }

  // 预取数据实现
  async prefetch(index: number): Promise<void> {
    // 如果索引已经加载，无需操作
    if (index < this.totalCount()) {
      return;
    }

    // 如果已经达到最大数量，无需加载
    const totalSongs = this.playlist?.songs?.length || 0;
    if (this.totalCount() >= totalSongs) {
      return;
    }

    // 计算需要加载的数据范围
    const currentCount = this.totalCount();
    const endIndex = Math.min(index + 10, totalSongs);

    // 防止并发加载导致重复添加数据
    if (this.isLoadingMoreData) {
      return;
    }

    this.isLoadingMoreData = true;

    try {
      // 加载数据
      for (let i = currentCount; i < endIndex; i++) {
        if (this.playlist?.songs && i < this.playlist.songs.length) {
          const song = this.playlist.songs[i];
          // 避免重复加载同一首歌
          if (song.id && !this.loadedSongIds.has(song.id)) {
            LogUtil.info('SongDataSourcePrefetching', `Prefetching song: ${song.name || 'unknown'} (ID: ${song.id})`);
            this.pushData(song);
            this.loadedSongIds.add(song.id);
          }
        }
      }
    } finally {
      this.isLoadingMoreData = false;
    }
  }

  // 取消预取实现 (对于本地数据不需要实际取消操作)
  cancel(_index: number): void {
    // 本地数据不需要取消操作
  }

  // 加载更多数据
  async loadMoreData(count: number = 10): Promise<boolean> {
    if (this.isLoadingMoreData) {
      return false;
    }

    const currentCount = this.totalCount();
    const totalCount = this.playlist?.songs?.length || 0;

    // 如果已经加载全部数据，返回false
    if (currentCount >= totalCount) {
      return false;
    }

    this.isLoadingMoreData = true;

    try {
      const endIndex = Math.min(currentCount + count, totalCount);
      let addedCount = 0;

      for (let i = currentCount; i < endIndex; i++) {
        if (this.playlist?.songs && i < this.playlist.songs.length) {
          const song = this.playlist.songs[i];
          // 避免重复加载同一首歌
          if (song.id && !this.loadedSongIds.has(song.id)) {
            this.pushData(song);
            this.loadedSongIds.add(song.id);
            addedCount++;
          }
        }
      }

      return addedCount > 0;
    } finally {
      this.isLoadingMoreData = false;
    }
  }

  // 安全地删除指定歌曲
  removeData(song: Song): boolean {
    if (!song.id) return false;

    // 从已加载ID集合中移除
    this.loadedSongIds.delete(song.id);

    // 查找要删除歌曲的索引
    let foundIndex = -1;
    const totalCount = this.totalCount();

    for (let i = 0; i < totalCount; i++) {
      const item = this.getData(i);
      if (item && item.id === song.id) {
        foundIndex = i;
        break;
      }
    }

    // 如果找到了歌曲，从LazyData中删除
    if (foundIndex >= 0) {
      this.deleteData(foundIndex);
      LogUtil.info('SongDataSourcePrefetching', `Removed song ID ${song.id} at index ${foundIndex}`);
      return true;
    }

    LogUtil.info('SongDataSourcePrefetching', `Song ID ${song.id} not found in data source`);
    return false;
  }

  // 同步数据集与当前播放列表
  syncWithPlaylist(songs: Array<Song>): void {
    // 创建一个新的ID集合来表示当前播放列表中的歌曲
    const currentIds = new Set<ID>();
    songs.forEach(song => {
      if (song.id) {
        currentIds.add(song.id);
      }
    });

    // 找出需要从数据源中删除的歌曲ID
    const idsToRemove: ID[] = [];
    this.loadedSongIds.forEach(id => {
      if (!currentIds.has(id)) {
        idsToRemove.push(id);
      }
    });

    // 删除不在播放列表中的歌曲
    if (idsToRemove.length > 0) {
      LogUtil.info('SongDataSourcePrefetching', `Syncing playlist - removing ${idsToRemove.length} songs`);

      // 对于每个要删除的ID，查找并删除对应的歌曲
      for (const id of idsToRemove) {
        // 查找要删除歌曲的索引
        let foundIndex = -1;
        const totalCount = this.totalCount();

        for (let i = 0; i < totalCount; i++) {
          const item = this.getData(i);
          if (item && item.id === id) {
            foundIndex = i;
            break;
          }
        }

        // 如果找到了歌曲，从LazyData中删除
        if (foundIndex >= 0) {
          this.deleteData(foundIndex);
        }

        // 从已加载ID集合中移除
        this.loadedSongIds.delete(id);
      }
    }

    // 更新播放列表引用
    if (this.playlist) {
      this.playlist.songs = songs;
    } else {
      this.playlist = {
        id: 'current_playing',
        songs: songs
      };
    }
  }
}