import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from "@ohos/axios"
import { LogUtil } from "@pura/harmony-utils";
import { Album, Artist, Bitrate, ID, Playlist, SearchResult, Song, SourceConfig, User } from "../type/Adapter"
import { PreferencesCache } from "../util/PreferenceCache";
import { ResponseCacheUtil } from "../util/ResponseCacheUtil";
import { JSON } from "@kit.ArkTS";
import { EventHelper } from "../util/EventHelper";

const TAG = "SourceAdapter ";

interface BaseResponse<T> {
  code: number;
  message: string;
  data: T;
  timestamp: number;
}

interface UniKey {
  unikey: string;
}

interface QRCode {
  qrurl: string;
  qrimg: string;
}

interface QRCheck {
  status: number; // -1 过期，0 等待扫码，1 等待确认，2 授权登录成功，等待验证
  cookie: string;
}

interface ResponseInterceptors {
  handleResponse: (response: AxiosResponse) => AxiosResponse;
  handleError: (error: AxiosError) => Promise<AxiosError>;
}

const createCacheAdapter = () => {
  return async (config: InternalAxiosRequestConfig): Promise<AxiosResponse> => {
    if (!config.url) {
      return Promise.reject(new Error('url is required'))
    }

    // 删除适配器，避免循环调用
    config.adapter = undefined;

    // 判断是否需要缓存
    const cacheKey = config.baseURL + config.url
    const needCache = config.headers['X-Cache'] === 'true'
    if (needCache) {
      const cachedData: AxiosResponse | undefined = ResponseCacheUtil.get<AxiosResponse>(cacheKey)
      if (cachedData) {
        LogUtil.info(TAG, `Cache hit for ${cacheKey}`);
        // 设置使用缓存数据的时间
        AppStorage.setOrCreate('cache_data_create_time', ResponseCacheUtil.getCreatedTime(cacheKey))
        return cachedData
      }
    }

    // 如果没有缓存或者不需要缓存，直接请求
    LogUtil.info(TAG, `Requesting ${cacheKey}`);
    // 删除 X-Cache 头，避免传递给下一个请求
    config.headers['X-Cache'] = undefined
    const response: AxiosResponse = await axios.request(config)
    if (needCache) {
      ResponseCacheUtil.set(cacheKey, response)
    }
    // 如果没有缓存，设置缓存数据的时间为-1
    AppStorage.setOrCreate('cache_data_create_time', -1)
    return response;
  };
}

const responseInterceptors: ResponseInterceptors = {
  handleResponse: (response: AxiosResponse): AxiosResponse => {
    const responseStr = JSON.stringify(response);
    // 分段打印日志，避免日志过长
    const maxLength = 2000;
    for (let i = 0; i < responseStr.length; i += maxLength) {
      LogUtil.info(TAG, responseStr.slice(i, i + maxLength));
    }
    return response;
  },

  handleError: (error: AxiosError): Promise<AxiosError> => {
    LogUtil.error(TAG, error.message);
    return Promise.reject(error);
  }
};

const createRequest = (source: SourceConfig) => {
  const request = axios.create({
    baseURL: source.url,
    timeout: 30000,
    headers: {
      'Content-Type': 'application/json',
      'Token': source.auth?.token
    },
    adapter: createCacheAdapter()
  });
  // 添加通用拦截器
  request.interceptors.response.use(responseInterceptors.handleResponse, responseInterceptors.handleError);
  return request
}

interface LikeResponse {
  playlist: ID;
}

export class SourceAdapter {
  /**
   * 获取连接状态
   * @param source 数据源配置
   * @returns 返回连接后的数据源配置
   */
  static async getConnectionStatus(source: SourceConfig): Promise<SourceConfig> {
    if (source.auth?.token === undefined) {
      throw new Error('token is required')
    }
    const request = createRequest(source)
    const res = (await request.get('/connect/status')).data as BaseResponse<User>
    source.auth.user = res.data
    EventHelper.postInitData("")
    return source
  }

  /**
   * 获取二维码Unikey
   * @param source 数据源配置
   * @returns 返回二维码Unikey
   */
  static async getQRCodeKey(source: SourceConfig): Promise<string> {
    const request = createRequest(source)
    const res = (await request.get('/connect/qr/key')).data as BaseResponse<UniKey>
    return res.data.unikey
  }

  /**
   * 根据Unikey创建二维码
   * @param source 数据源配置
   * @param unikey 二维码Unikey
   * @returns 返回二维码信息
   */
  static async createQRCode(source: SourceConfig, unikey: string): Promise<QRCode> {
    const request = createRequest(source)
    const res = (await request.get(`/connect/qr/create?key=${unikey}`)).data as BaseResponse<QRCode>
    return res.data
  }

  /**
   * 检查二维码状态
   * @param source 数据源配置
   * @param unikey 二维码Unikey
   * @returns 返回二维码状态
   */
  static async checkQRCodeStatus(source: SourceConfig, unikey: string): Promise<QRCheck> {
    const request = createRequest(source)
    const res = (await request.get(`/connect/qr/check?key=${unikey}`)).data as BaseResponse<QRCheck>
    return res.data
  }

  /**
   * 获取推荐歌单
   * @param limit 数量
   * @param storageLink 是否存储链接
   * @returns 返回歌单列表
   */
  static async getRecommendList(limit = 10, storageLink = true): Promise<Playlist[]> {
    const sourceConfigGroup = PreferencesCache.getUserDataSource()

    const results = await Promise.all(
      sourceConfigGroup.map((source) =>
      createRequest(source)
        .get(`/playlist/recommend?limit=${limit}`)
        .then((res: AxiosResponse) => (res.data as BaseResponse<Playlist[]>).data.map(item => {
          item.source = source
          return item
        }))
      )
    )

    const uniqueItems = new Map<string, Playlist>()
    results.flat().forEach(item => {
      const key = `${item.id}-${item.name}`
      if (!uniqueItems.has(key)) {
        uniqueItems.set(key, item)
      }
    })

    const result = Array.from(uniqueItems.values())

    if (storageLink) {
      AppStorage.setOrCreate('index_recommend_playlist', result)
    }

    return result
  }

  /**
   * 获取推荐歌曲
   * @param limit 数量
   * @param storageLink 是否存储链接
   * @returns 返回歌曲列表
   */
  static async getRecommendSongs(limit = 10, storageLink = true): Promise<Song[]> {
    const sourceConfigGroup = PreferencesCache.getUserDataSource()

    const results = await Promise.all(
      sourceConfigGroup.map((source) =>
      createRequest(source)
        .get(`/song/recommend?limit=${limit}`)
        .then((res: AxiosResponse) => (res.data as BaseResponse<Song[]>).data.map(item => {
          item.source = source
          return item
        }))
      )
    )

    const uniqueItems = new Map<string, Song>()
    results.flat().forEach(item => {
      const key = `${item.id}-${item.name}`
      if (!uniqueItems.has(key)) {
        uniqueItems.set(key, item)
      }
    })

    const result = Array.from(uniqueItems.values())

    if (storageLink) {
      AppStorage.setOrCreate('index_recommend_songs', result)
    }

    return result
  }

  /**
   * 获取推荐歌手
   * @param limit 数量
   * @param storageLink 是否存储链接
   * @returns 返回歌手列表
   */
  static async getRecommendArtists(limit = 10, storageLink = true): Promise<Artist[]> {
    const sourceConfigGroup = PreferencesCache.getUserDataSource()

    const results = await Promise.all(
      sourceConfigGroup.map((source) =>
      createRequest(source)
        .get(`/artist/recommend?limit=${limit}`)
        .then((res: AxiosResponse) => (res.data as BaseResponse<Artist[]>).data.map(item => {
          item.source = source
          return item
        }))
      )
    )

    const uniqueItems = new Map<string, Artist>()
    results.flat().forEach(item => {
      const key = `${item.id}-${item.name}`
      if (!uniqueItems.has(key)) {
        uniqueItems.set(key, item)
      }
    })

    const result = Array.from(uniqueItems.values())

    if (storageLink) {
      AppStorage.setOrCreate('index_recommend_artists', result)
    }

    return result
  }

  /**
   * 获取排行榜
   * @param limit 数量
   * @param storageLink 是否存储链接
   * @returns 返回歌单列表
   */
  static async getTopList(limit = 10, storageLink = true): Promise<Playlist[]> {
    const sourceConfigGroup = PreferencesCache.getUserDataSource()

    const results = await Promise.all(
      sourceConfigGroup.map((source) =>
      createRequest(source)
        .get(`/playlist/toplist?limit=${limit}`)
        .then((res: AxiosResponse) => (res.data as BaseResponse<Playlist[]>).data.map(item => {
          item.source = source
          return item
        }))
      )
    )

    const uniqueItems = new Map<string, Playlist>()
    results.flat().forEach(item => {
      const key = `${item.id}-${item.name}`
      if (!uniqueItems.has(key)) {
        uniqueItems.set(key, item)
      }
    })

    const result = Array.from(uniqueItems.values())

    if (storageLink) {
      AppStorage.setOrCreate('index_recommend_toplist', result)
    }

    return result
  }

  /**
   * 获取用户歌单
   * @returns 返回歌单列表
   */
  static async getUserPlaylist(storageLink = true): Promise<Playlist[]> {
    const sourceConfigGroup = PreferencesCache.getUserDataSource()
    const results = await Promise.all(
      sourceConfigGroup.map(source =>
      createRequest(source)
        .get(`/playlist/list?uid=${source.auth?.user?.id}`)
        .then((res: AxiosResponse) => (res.data as BaseResponse<Playlist[]>).data.map(item => {
          item.source = source
          return item
        }))
      )
    )

    const uniqueItems = new Map<string, Playlist>()
    results.flat().forEach(item => {
      const key = `${item.id}-${item.name}`
      if (!uniqueItems.has(key)) {
        uniqueItems.set(key, item)
      }
    })

    const result = Array.from(uniqueItems.values())

    if (storageLink) {
      AppStorage.setOrCreate('user_playlist', result)
    }

    return result
  }

  static async getPlaylistDetail(playlist: Playlist): Promise<Playlist> {
    const source = playlist.source as SourceConfig
    const request = createRequest(source)
    const res = (await request.get(`/playlist/detail?id=${playlist.id}`, {
      headers: {
        // TODO:这种逻辑应该是服务端发送，后续要进行优化
        'X-Cache': playlist.id !== "daily_songs" ? 'true' : 'false'
      }
    })).data as BaseResponse<Playlist>
    playlist.songs = res.data.songs?.map(song => {
      song.source = source
      return song
    }) || []
    playlist.meta = res.data.meta
    return playlist
  }

  static async getAlbumDetail(album: Album): Promise<Playlist> {
    const source = album.source as SourceConfig
    const request = createRequest(source)
    const res = (await request.get(`/album/detail?id=${album.id}`, {
      headers: {
        'X-Cache': 'true',
      }
    })).data as BaseResponse<Playlist>
    // 根据album，创建一个playlist
    const playlist: Playlist = {
      id: album.id,
      name: album.name,
      size: album.size,
      description: album.description,
      cover: album.cover,
    }
    playlist.songs = res.data.songs?.map(song => {
      song.source = source
      return song
    }) || []
    playlist.meta = res.data.meta
    return playlist
  }

  static async getSongDetail(song: Song, br: Bitrate = PreferencesCache.playingLevel()): Promise<Song> {
    const source = song.source as SourceConfig
    const uid = song.source?.auth?.user?.id
    const request = createRequest(source)
    const bitRate = song.privilege.bitrates
    if (bitRate) {
      // 获取离当前码率最近的码率，避免因为码率不匹配导致无法播放
      br = bitRate.reduce((prev, curr) => Math.abs(curr - br) < Math.abs(prev - br) ? curr : prev)
    }
    let uri = `/song/detail?id=${song.id}&br=${br}`
    if (uid) {
      uri += `&uid=${uid}`
    }
    const res = (await request.get(uri, {
      // headers: {
      //   'X-Cache': 'true'
      // }
    })).data as BaseResponse<Song>
    song.meta = res.data.meta
    return song
  }

  static async getArtistDetail(artist: Artist): Promise<Playlist> {
    const source = artist.source as SourceConfig
    const request = createRequest(source)
    const res = (await request.get(`/artist/detail?id=${artist.id}`, {
      headers: {
        'X-Cache': 'true'
      }
    })).data as BaseResponse<Playlist>
    res.data.songs = res.data.songs?.map(song => {
      song.source = source
      return song
    }) || []
    return res.data
  }

  static async search(keywords: string, limit = 10): Promise<SearchResult> {
    const sourceConfigGroup = PreferencesCache.getUserDataSource()
    keywords = encodeURIComponent(keywords)
    const results = await Promise.all(
      sourceConfigGroup.map(source =>
      createRequest(source)
        .get(`/search?keywords=${keywords}&limit=${limit}`)
        .then((res: AxiosResponse) => {
          const data = res.data as BaseResponse<SearchResult>
          data.data.songs = data.data.songs?.map(song => {
            song.source = source
            return song
          }) || []
          data.data.playlists = data.data.playlists?.map(playlist => {
            playlist.source = source
            return playlist
          }) || []
          data.data.artists = data.data.artists?.map(artist => {
            artist.source = source
            return artist
          }) || []
          data.data.albums = data.data.albums?.map(album => {
            album.source = source
            return album
          }) || []
          return data.data
        })
      )
    )

    return results.reduce((prev, curr) => {
      prev.songs = [...(prev.songs || []), ...(curr.songs || [])]
      prev.playlists = [...(prev.playlists || []), ...(curr.playlists || [])]
      prev.artists = [...(prev.artists || []), ...(curr.artists || [])]
      prev.albums = [...(prev.albums || []), ...(curr.albums || [])]
      return prev
    }, {} as SearchResult)
  }

  static async likeSong(song: Song, like: boolean = true): Promise<void> {
    const source = song.source as SourceConfig
    const request = createRequest(source)
    const res = (await request.put(`/song/like?id=${song.id}&like=${like}`)).data as BaseResponse<LikeResponse>
    const playlistId = res.data.playlist
    const fullKey = source.url + `/playlist/detail?id=${playlistId}`
    // 删除缓存
    ResponseCacheUtil.remove(fullKey)
    // 更新用户歌单
    SourceAdapter.getUserPlaylist()
  }
}