/**
 * 房屋光照结果模型
 */
export class HouseSunshineModel {
  // 总光照时间(分钟)
  totalSunshineTime: number = 0;
  // 精确光照时间(分钟)
  exactSunshineTime: number = 0;
  // 春分光照时间(分钟)
  springEquinox: number = 0;
  // 夏至光照时间(分钟)
  summerSolstice: number = 0;
  // 秋分光照时间(分钟)
  autumnalEquinox: number = 0;
  // 冬至光照时间(分钟)
  winterSolstice: number = 0;
  // 大寒光照时间(分钟)
  greatCold: number = 0;

  /**
   * 格式化时间为小时显示
   */
  formatMinutesToHours(minutes: number): string {
    return (minutes / 60).toFixed(3);
  }

  /**
   * 获取光照百分比
   */
  getSunshinePercent(): string {
    if (this.totalSunshineTime === 0) {
      return '100.000';
    }
    return ((this.exactSunshineTime / this.totalSunshineTime) * 100).toFixed(3);
  }
}
