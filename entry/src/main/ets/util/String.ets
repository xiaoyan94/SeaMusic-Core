/**
 * 将过去的时间转换为友好的相对时间描述
 * @param pastTime 过去的时间（Date对象或时间戳）
 * @returns 友好的时间描述字符串
 */
export function formatRelativeTime(pastTime: Date | number): string {
  // 将输入转换为Date对象
  const pastDate = pastTime instanceof Date ? pastTime : new Date(pastTime);

  // 获取当前时间
  const now = new Date();

  // 计算时间差（毫秒）
  const diffMs = now.getTime() - pastDate.getTime();

  // 转换为秒、分钟、小时和天
  const diffSeconds = Math.floor(diffMs / 1000);
  const diffMinutes = Math.floor(diffSeconds / 60);
  const diffHours = Math.floor(diffMinutes / 60);
  const diffDays = Math.floor(diffHours / 24);

  // 根据时间差返回对应的描述
  if (diffMinutes < 5) {
    return '刚刚';
  } else if (diffMinutes < 60) {
    return `${diffMinutes}分钟前`;
  } else if (diffHours < 24) {
    return `${diffHours}小时前`;
  } else {
    return `${diffDays}天前`;
  }
}