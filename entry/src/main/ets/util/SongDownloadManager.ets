import { fileUri, picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { Song } from '../type/Adapter';
import { LogUtil, PreferencesUtil } from '@pura/harmony-utils';
import { DownloadManager } from './DownloadUtils';

// 下载配置接口
interface DownloadConfig {
  prefix?: string;
  preferenceName?: string;
}

// 歌曲下载项
export interface SongDownloadItem {
  song: Song;
  path: string;
  downloadTime: number;
  lastPlayTime: number;
  size: number;
}

// 默认配置
const DEFAULT_CONFIG: DownloadConfig = {
  prefix: 'download_',
  preferenceName: 'song_downloads'
};

/**
 * 歌曲下载管理器 - 单例模式
 * 用于管理歌曲的下载和持久化存储
 */
class SongDownloadManagerClass {
  private static instance: SongDownloadManagerClass = new SongDownloadManagerClass();
  private config: DownloadConfig = DEFAULT_CONFIG;
  private initialized: boolean = false;
  private documentViewPicker: picker.DocumentViewPicker | null = null;
  private baseUri: string = '';

  private constructor() {
  }

  public static getInstance(): SongDownloadManagerClass {
    return SongDownloadManagerClass.instance;
  }

  // 初始化下载管理器
  public init(context: common.Context, config?: DownloadConfig): void {
    if (this.initialized) {
      LogUtil.warn('SongDownloadManager already initialized');
      return;
    }

    if (config) {
      this.config = this.mergeConfig(DEFAULT_CONFIG, config);
    }

    this.documentViewPicker = new picker.DocumentViewPicker(context);
    this.initialized = true;
  }

  // 手动实现配置合并
  private mergeConfig(defaultConfig: DownloadConfig, userConfig: DownloadConfig): DownloadConfig {
    const result: DownloadConfig = {
      prefix: userConfig.prefix !== undefined ? userConfig.prefix : defaultConfig.prefix,
      preferenceName: userConfig.preferenceName !== undefined ? userConfig.preferenceName : defaultConfig.preferenceName
    };
    return result;
  }

  private checkInitialized(): void {
    if (!this.initialized) {
      throw new Error('SongDownloadManager not initialized. Please call init() first.');
    }
  }

  /**
   * 初始化下载目录并获取基础URI
   * @returns Promise<string> 下载目录的URI
   */
  async initDownloadDirectory(): Promise<string> {
    this.checkInitialized();

    if (!this.documentViewPicker) {
      return '';
    }

    if (this.baseUri) {
      return this.baseUri;
    }

    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;

    try {
      const result = await this.documentViewPicker.save(documentSaveOptions);
      this.baseUri = result[0];
      return this.baseUri;
    } catch (err) {
      return '';
    }
  }

  private getFullKey(songId: string): string {
    return `${this.config.prefix}${songId}`;
  }

  /**
   * 下载并保存歌曲
   * @param songId 歌曲ID
   * @param url 歌曲下载URL
   * @param fileName 文件名（完整文件名，包括扩展名）
   * @param song 歌曲数据
   * @param onProgress 进度回调函数
   * @returns Promise<boolean> 是否下载成功
   */
  public async downloadSong(
    songId: string,
    url: string,
    fileName: string,
    song: Song,
    onProgress?: (progress: number) => void
  ): Promise<boolean> {
    this.checkInitialized();

    try {
      // 确保下载目录已初始化
      if (!this.baseUri) {
        await this.initDownloadDirectory();
        if (!this.baseUri) {
          return false;
        }
      }

      // 创建音乐目录
      const musicDir = await this.createDirectory('Music');
      if (!musicDir) {
        return false;
      }

      // 完整文件路径
      const filePath = musicDir + '/' + fileName;

      // 使用下载工具类下载文件
      const downloadedPath = await DownloadManager.downloadFile({
        url: url,
        fileName: filePath,
        onProgress: onProgress,
        onComplete: () => {
          // 下载完成回调可以留空，我们在Promise中处理
        },
        onError: () => {
          // 错误回调可以留空，我们在catch中处理
        }
      });

      if (!downloadedPath) {
        return false;
      }

      // 获取文件大小
      const filePathObj = new fileUri.FileUri(downloadedPath as string).path;
      const stat = fs.statSync(filePathObj);

      // 创建下载项
      const downloadItem: SongDownloadItem = {
        song,
        path: filePathObj,
        downloadTime: Date.now(),
        lastPlayTime: Date.now(),
        size: stat.size
      };

      // 保存到偏好设置
      await PreferencesUtil.put(
        this.getFullKey(songId),
        JSON.stringify(downloadItem),
        this.config.preferenceName
      );

      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 创建目录
   * @param dirName 目录名称
   * @returns Promise<string> 创建的目录URI
   */
  private async createDirectory(dirName: string): Promise<string> {
    try {
      if (!this.baseUri) {
        await this.initDownloadDirectory();
      }

      const dirPath = new fileUri.FileUri(this.baseUri + '/' + dirName).path;
      try {
        fs.mkdirSync(dirPath);
      } catch (err) {
        // 如果目录已存在，则忽略错误 (17是目录已存在的错误码)
        if (err.code !== 17) {
          return '';
        }
      }

      return this.baseUri + '/' + dirName;
    } catch (err) {
      return '';
    }
  }

  /**
   * 从下载目录获取歌曲
   * @param songId 歌曲ID
   * @returns SongDownloadItem | null 歌曲下载项或null
   */
  public getSong(songId: string): SongDownloadItem | null {
    this.checkInitialized();

    try {
      const fullKey = this.getFullKey(songId);
      const data = PreferencesUtil.getStringSync(fullKey, undefined, this.config.preferenceName);

      if (!data) {
        return null;
      }

      const downloadItem: SongDownloadItem = JSON.parse(data);

      // 检查文件是否存在
      try {
        fs.accessSync(downloadItem.path);
      } catch (err) {
        // 文件不存在，删除记录
        this.removeSong(songId);
        return null;
      }

      return downloadItem;
    } catch (error) {
      return null;
    }
  }

  /**
   * 更新歌曲的最后播放时间
   * @param songId 歌曲ID
   */
  public updateLastPlayTime(songId: string): void {
    this.checkInitialized();

    try {
      const fullKey = this.getFullKey(songId);
      const data = PreferencesUtil.getStringSync(fullKey, undefined, this.config.preferenceName);

      if (!data) {
        return;
      }

      const downloadItem: SongDownloadItem = JSON.parse(data);
      downloadItem.lastPlayTime = Date.now();

      PreferencesUtil.put(fullKey, JSON.stringify(downloadItem), this.config.preferenceName);
    } catch (error) {
      // 忽略错误
    }
  }

  /**
   * 检查歌曲是否已下载
   * @param songId 歌曲ID
   * @returns boolean 是否已下载
   */
  public hasSong(songId: string): boolean {
    this.checkInitialized();

    const fullKey = this.getFullKey(songId);
    if (!PreferencesUtil.hasSync(fullKey, this.config.preferenceName)) {
      return false;
    }

    // 进一步检查文件是否存在
    try {
      const data = PreferencesUtil.getStringSync(fullKey, undefined, this.config.preferenceName);
      if (!data) {
        return false;
      }

      const downloadItem: SongDownloadItem = JSON.parse(data);
      fs.accessSync(downloadItem.path);
      return true;
    } catch (error) {
      // 文件不存在，删除记录
      this.removeSong(songId);
      return false;
    }
  }

  /**
   * 删除下载的歌曲
   * @param songId 歌曲ID
   * @returns Promise<boolean> 是否删除成功
   */
  public async removeSong(songId: string): Promise<boolean> {
    this.checkInitialized();

    try {
      const fullKey = this.getFullKey(songId);
      // 获取下载项以便删除文件
      const data = PreferencesUtil.getStringSync(fullKey, undefined, this.config.preferenceName);
      if (data) {
        const downloadItem: SongDownloadItem = JSON.parse(data);
        // 删除文件
        try {
          await fs.unlink(downloadItem.path);
        } catch (e) {
          // 忽略删除文件错误
        }
      }

      // 删除偏好设置中的条目
      await PreferencesUtil.delete(fullKey, this.config.preferenceName);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取下载数量
   * @returns number 下载数量
   */
  public getDownloadCount(): number {
    this.checkInitialized();

    const allData = PreferencesUtil.getAllSync(this.config.preferenceName);
    if (!allData) {
      return 0;
    }

    return Object.keys(allData).filter(key =>
    key.startsWith(this.config.prefix || DEFAULT_CONFIG.prefix || '')
    ).length;
  }

  /**
   * 获取所有下载的歌曲
   * @returns SongDownloadItem[] 下载的歌曲列表
   */
  public getAllDownloads(): SongDownloadItem[] {
    this.checkInitialized();

    const result: SongDownloadItem[] = [];
    const allData = PreferencesUtil.getAllSync(this.config.preferenceName);
    if (!allData) {
      return result;
    }

    const keys = Object.keys(allData).filter(key =>
    key.startsWith(this.config.prefix || DEFAULT_CONFIG.prefix || '')
    );

    for (const key of keys) {
      try {
        const downloadItem: SongDownloadItem = JSON.parse(allData[key]);
        // 检查文件是否存在
        try {
          fs.accessSync(downloadItem.path);
          result.push(downloadItem);
        } catch (err) {
          // 文件不存在，删除记录
          const songId = key.replace(this.config.prefix || '', '');
          this.removeSong(songId);
        }
      } catch (error) {
        // 忽略解析错误
      }
    }

    return result;
  }

  /**
   * 计算所有下载的总大小
   * @returns number 下载的总大小（字节）
   */
  public getTotalSize(): number {
    this.checkInitialized();

    let totalSize = 0;
    const downloads = this.getAllDownloads();

    for (const item of downloads) {
      totalSize += item.size;
    }

    return totalSize;
  }

  /**
   * 清除所有下载
   * @returns Promise<boolean> 是否清除成功
   */
  public async clearAllDownloads(): Promise<boolean> {
    this.checkInitialized();

    try {
      const allData = PreferencesUtil.getAllSync(this.config.preferenceName);
      if (!allData) {
        return true;
      }

      const keys = Object.keys(allData).filter(key =>
      key.startsWith(this.config.prefix || DEFAULT_CONFIG.prefix || '')
      );

      for (const key of keys) {
        try {
          const downloadItem: SongDownloadItem = JSON.parse(allData[key]);
          // 删除文件
          await fs.unlink(downloadItem.path);
        } catch (error) {
          // 忽略删除文件错误
        }

        // 删除偏好设置中的条目
        await PreferencesUtil.delete(key, this.config.preferenceName);
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取当前下载目录URI
   * @returns string 下载目录URI
   */
  public getBaseUri(): string {
    return this.baseUri;
  }
}

// 导出单例实例
export const SongDownloadManager = SongDownloadManagerClass.getInstance();