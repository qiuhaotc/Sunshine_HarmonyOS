/**
 * 太阳位置模型
 */
export class SunPosition {
  // 高度角(度)
  altitude: number = 0;
  // 方位角(度，0度为北，顺时针)
  azimuth: number = 0;

  constructor(altitude: number = 0, azimuth: number = 0) {
    this.altitude = altitude;
    this.azimuth = azimuth;
  }
}
