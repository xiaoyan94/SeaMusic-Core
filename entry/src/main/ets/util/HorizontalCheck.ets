import { display } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit'
/**
 * 检测当前设备是否处于横屏模式
 * @returns {boolean} 是否横屏模式
 */
export function isHorizontalMode(): boolean {
  // 检查设备是否支持折叠
  const isFoldable = display.isFoldable();
  let deviceTypeInfo: string = deviceInfo.deviceType;
  // 默认假设为横屏模式
  let isHorizontalMode = true;

  if (isFoldable) {
    // 获取折叠状态
    const foldStatus = display.getFoldStatus();
    if (foldStatus !== display.FoldStatus.FOLD_STATUS_FOLDED) {
      isHorizontalMode = false;
    }
  }
  if(deviceTypeInfo=='tablet'||deviceTypeInfo=='2in1') {
    isHorizontalMode = false;
  }
  return isHorizontalMode;
}