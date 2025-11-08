/**
 * 城市信息模型
 */
export class CityModel {
  city: string = '';
  country: string = '';
  province: string = '';
  lng: string = ''; // 经度(十进制)
  lat: string = ''; // 纬度(十进制)

  /**
   * 将十进制经纬度转换为度分秒格式
   * @param decimal 十进制度数
   * @returns 度-分-秒字符串
   */
  static decimalToDMS(decimal: number): string {
    const abs = Math.abs(decimal);
    const degrees = Math.floor(abs);
    const minutesDecimal = (abs - degrees) * 60;
    const minutes = Math.floor(minutesDecimal);
    const seconds = ((minutesDecimal - minutes) * 60).toFixed(2);
    
    return `${degrees}°${minutes}'${seconds}"`;
  }

  /**
   * 将度分秒格式转换为十进制
   * @param dms 度分秒字符串，格式如 "116°24'48.18"" 或 "116-24-48.18"
   * @returns 十进制度数
   */
  static dmsToDecimal(dms: string): number {
    // 支持多种分隔符：° ' " 或 - 或空格
    const parts = dms.replace(/[°'"]/g, '-').split('-').map(p => p.trim()).filter(p => p);
    
    if (parts.length < 1) {
      return 0;
    }

    const degrees = parseFloat(parts[0]) || 0;
    const minutes = parts.length > 1 ? parseFloat(parts[1]) || 0 : 0;
    const seconds = parts.length > 2 ? parseFloat(parts[2]) || 0 : 0;

    return degrees + minutes / 60 + seconds / 3600;
  }

  /**
   * 获取经度(十进制)
   */
  getLongitudeDecimal(): number {
    return parseFloat(this.lng);
  }

  /**
   * 获取纬度(十进制)
   */
  getLatitudeDecimal(): number {
    return parseFloat(this.lat);
  }

  /**
   * 获取经度(度分秒格式)
   */
  getLongitudeDMS(): string {
    return CityModel.decimalToDMS(this.getLongitudeDecimal());
  }

  /**
   * 获取纬度(度分秒格式)
   */
  getLatitudeDMS(): string {
    return CityModel.decimalToDMS(this.getLatitudeDecimal());
  }

  /**
   * 获取显示名称
   */
  getDisplayName(): string {
    return `${this.province} - ${this.city}`;
  }
}
