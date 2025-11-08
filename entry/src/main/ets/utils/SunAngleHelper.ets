import { SunPosition } from '../model/SunPosition';

/**
 * 太阳角度计算辅助类
 * 根据经纬度、时间计算太阳的高度角和方位角
 */
export class SunAngleHelper {
  private static readonly DEGREE_TO_RADIAN: number = Math.PI / 180;
  private static readonly RADIAN_TO_DEGREE: number = 180 / Math.PI;

  /**
   * 计算太阳位置
   * @param latitude 纬度
   * @param longitude 经度
   * @param dateTimeUtc UTC时间
   * @returns 太阳位置(高度角和方位角)
   */
  getSunAngle(latitude: number, longitude: number, dateTimeUtc: Date): SunPosition {
    const year = dateTimeUtc.getUTCFullYear();
    const month = dateTimeUtc.getUTCMonth() + 1;
    const day = dateTimeUtc.getUTCDate();
    const hour = dateTimeUtc.getUTCHours();
    const minute = dateTimeUtc.getUTCMinutes();
    const second = dateTimeUtc.getUTCSeconds();

    // 计算儒略日
    const jd = this.calculateJulianDay(year, month, day, hour, minute, second);
    
    // 计算儒略世纪数
    const t = (jd - 2451545.0) / 36525.0;

    // 计算太阳的几何平均黄经(度)
    let L0 = 280.46646 + t * (36000.76983 + t * 0.0003032);
    L0 = this.normalizeAngle(L0);

    // 计算太阳的几何平均近点角(度)
    let M = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    M = this.normalizeAngle(M);

    // 计算地球轨道离心率
    const e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

    // 计算太阳中心方程(度)
    const C = Math.sin(M * SunAngleHelper.DEGREE_TO_RADIAN) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
              Math.sin(2 * M * SunAngleHelper.DEGREE_TO_RADIAN) * (0.019993 - 0.000101 * t) +
              Math.sin(3 * M * SunAngleHelper.DEGREE_TO_RADIAN) * 0.000289;

    // 计算太阳真黄经(度)
    const sunTrueLong = L0 + C;

    // 计算太阳视黄经(度)
    const omega = 125.04 - 1934.136 * t;
    const lambda = sunTrueLong - 0.00569 - 0.00478 * Math.sin(omega * SunAngleHelper.DEGREE_TO_RADIAN);

    // 计算黄赤交角(度)
    const epsilon = 23.439291 - t * (0.0130042 + t * (0.00000016 - t * 0.000000504));

    // 计算太阳赤纬(度)
    const delta = Math.asin(Math.sin(epsilon * SunAngleHelper.DEGREE_TO_RADIAN) * 
                           Math.sin(lambda * SunAngleHelper.DEGREE_TO_RADIAN)) * 
                  SunAngleHelper.RADIAN_TO_DEGREE;

    // 计算时间方程(分钟)
    const y = Math.tan(epsilon / 2 * SunAngleHelper.DEGREE_TO_RADIAN) ** 2;
    const eqTime = 4 * SunAngleHelper.RADIAN_TO_DEGREE * (
      y * Math.sin(2 * L0 * SunAngleHelper.DEGREE_TO_RADIAN) -
      2 * e * Math.sin(M * SunAngleHelper.DEGREE_TO_RADIAN) +
      4 * e * y * Math.sin(M * SunAngleHelper.DEGREE_TO_RADIAN) * 
        Math.cos(2 * L0 * SunAngleHelper.DEGREE_TO_RADIAN) -
      0.5 * y * y * Math.sin(4 * L0 * SunAngleHelper.DEGREE_TO_RADIAN) -
      1.25 * e * e * Math.sin(2 * M * SunAngleHelper.DEGREE_TO_RADIAN)
    );

    // 计算真实太阳时(分钟)
    const trueSolarTime = ((hour * 60 + minute + second / 60) + eqTime + 4 * longitude) % 1440;

    // 计算时角(度)
    let hourAngle = trueSolarTime / 4 - 180;
    if (hourAngle < -180) {
      hourAngle += 360;
    }

    // 计算太阳高度角(度)
    const latRad = latitude * SunAngleHelper.DEGREE_TO_RADIAN;
    const deltaRad = delta * SunAngleHelper.DEGREE_TO_RADIAN;
    const hourAngleRad = hourAngle * SunAngleHelper.DEGREE_TO_RADIAN;

    const sinAltitude = Math.sin(latRad) * Math.sin(deltaRad) +
                        Math.cos(latRad) * Math.cos(deltaRad) * Math.cos(hourAngleRad);
    const altitude = Math.asin(sinAltitude) * SunAngleHelper.RADIAN_TO_DEGREE;

    // 计算太阳方位角(度，0度为北，顺时针)
    const cosAzimuth = (Math.sin(deltaRad) - Math.sin(latRad) * sinAltitude) /
                       (Math.cos(latRad) * Math.cos(Math.asin(sinAltitude)));
    let azimuth = Math.acos(Math.max(-1, Math.min(1, cosAzimuth))) * SunAngleHelper.RADIAN_TO_DEGREE;

    // 根据时角调整方位角
    if (hourAngle > 0) {
      azimuth = 360 - azimuth;
    }

    return new SunPosition(altitude, azimuth);
  }

  /**
   * 计算儒略日
   */
  private calculateJulianDay(year: number, month: number, day: number, 
                            hour: number, minute: number, second: number): number {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    const A = Math.floor(year / 100);
    const B = 2 - A + Math.floor(A / 4);

    const jd = Math.floor(365.25 * (year + 4716)) +
               Math.floor(30.6001 * (month + 1)) +
               day + B - 1524.5 +
               (hour + minute / 60 + second / 3600) / 24;

    return jd;
  }

  /**
   * 将角度规范化到0-360度范围内
   */
  private normalizeAngle(angle: number): number {
    let normalized = angle % 360;
    if (normalized < 0) {
      normalized += 360;
    }
    return normalized;
  }

  /**
   * 简化的太阳赤纬计算(用于快速估算)
   */
  static solarDeclination(dayOfYear: number): number {
    return 23.45 * Math.sin((360 / 365) * (dayOfYear + 284) * SunAngleHelper.DEGREE_TO_RADIAN);
  }

  /**
   * 简化的时间方程计算(分钟)
   */
  static equationOfTime(dayOfYear: number): number {
    const B = (360 / 365) * (dayOfYear - 81) * SunAngleHelper.DEGREE_TO_RADIAN;
    return 9.87 * Math.sin(2 * B) - 7.53 * Math.cos(B) - 1.5 * Math.sin(B);
  }

  /**
   * 计算一天的日照时长(小时)
   */
  static dayLengthHours(latitude: number, dayOfYear: number): number {
    const latRad = latitude * SunAngleHelper.DEGREE_TO_RADIAN;
    const declination = SunAngleHelper.solarDeclination(dayOfYear);
    const decRad = declination * SunAngleHelper.DEGREE_TO_RADIAN;
    
    const cosH = -Math.tan(latRad) * Math.tan(decRad);
    if (cosH > 1) return 0; // 极夜
    if (cosH < -1) return 24; // 极昼
    
    const H = Math.acos(cosH) * SunAngleHelper.RADIAN_TO_DEGREE;
    return 2 * H / 15; // 15度/小时
  }

  /**
   * 简化的太阳位置计算(用于高级计算器)
   * @param latitude 纬度
   * @param longitude 经度
   * @param dayOfYear 一年中的第几天(1-365)
   * @param minuteOfDay 一天中的第几分钟(0-1439)
   * @param timeZone 时区
   */
  static solarPosition(latitude: number, longitude: number, dayOfYear: number, 
                      minuteOfDay: number, timeZone: number): SunPosition {
    const declination = SunAngleHelper.solarDeclination(dayOfYear);
    const eqTime = SunAngleHelper.equationOfTime(dayOfYear);
    
    // 计算真实太阳时
    const trueSolarTime = minuteOfDay + eqTime + 4 * longitude - 60 * timeZone;
    const hourAngle = (trueSolarTime / 4) - 180;
    
    // 计算高度角
    const latRad = latitude * SunAngleHelper.DEGREE_TO_RADIAN;
    const decRad = declination * SunAngleHelper.DEGREE_TO_RADIAN;
    const haRad = hourAngle * SunAngleHelper.DEGREE_TO_RADIAN;
    
    const sinAlt = Math.sin(latRad) * Math.sin(decRad) + 
                   Math.cos(latRad) * Math.cos(decRad) * Math.cos(haRad);
    const altitude = Math.asin(sinAlt) * SunAngleHelper.RADIAN_TO_DEGREE;
    
    // 计算方位角
    const cosAz = (Math.sin(decRad) - Math.sin(latRad) * sinAlt) / 
                  (Math.cos(latRad) * Math.cos(Math.asin(sinAlt)));
    let azimuth = Math.acos(Math.max(-1, Math.min(1, cosAz))) * SunAngleHelper.RADIAN_TO_DEGREE;
    
    if (hourAngle > 0) {
      azimuth = 360 - azimuth;
    }
    
    return new SunPosition(altitude, azimuth);
  }
}
