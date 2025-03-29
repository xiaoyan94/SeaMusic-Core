import { VibrationControl } from './DeviceController'

const _promptString: string[] = ["", "释放→设置", "释放→搜索", "下拉→刷新", "释放→刷新", "释放→上一页"]
const promptString: string[] = ["", "设置←释放", "搜索←释放", "刷新←下拉", "刷新←释放", "上一页←释放"]

export class SlideDownControl {

  /**
   * 获取当前下拉索引
   * @param offset
   * @param maxIndex
   * @returns
   */
  public static calculateCurrentIndex(offset: number, maxIndex: number = 3): number {
    offset = Math.abs(offset)
    if (offset < 40) {
      return -1
    }
    const index = Math.floor(offset / 72)
    return Math.min(Math.max(index, 0), maxIndex)
  }

  /**
   * 获取主页操作文本提示
   * @param index
   * @returns
   */
  public static getIndexActionText(index: number) {
    switch (index) {
      case 0:
        VibrationControl.handlePresetVibration()
        return promptString[1];
      case 1:
        VibrationControl.handlePresetVibration()
        return promptString[2];
      case 2:
        VibrationControl.handlePresetVibration()
        return promptString[4];
      default:
        return promptString[0];
    }

  }
  /**
   * 获取歌单页操作文本提示
   * @param index
   * @returns
   */
  public static getLibraryActionText(index: number): string {
    switch (index) {
      case 0:
        VibrationControl.handlePresetVibration()
        return promptString[5];
      case 1:
        return promptString[3];
      case 2:
        VibrationControl.handlePresetVibration()
        return promptString[4];
      default:
        return '';
    }
  }

  /**
   * 获取返回上一页操作提示
   * @param index
   * @returns
   */
  public static getReturnActionText(index: number): string {
    switch (index) {
      case 0:
        VibrationControl.handlePresetVibration()
        return promptString[5];
      default:
        return '';
    }
  }
}