import { BuildingModel } from '../model/BuildingModel';
import { Point3D } from '../model/Point3D';
import { SunAngleHelper } from '../utils/SunAngleHelper';
import { SunPosition } from '../model/SunPosition';

/**
 * 高级光照计算器
 * 用于计算复杂场景下的房屋光照情况(考虑多个建筑物的遮挡)
 * 模仿JS实现: https://github.com/qiuhaotc/Sunshine/blob/main/Sunshine.Server/wwwroot/js/advancedCalculator.js
 */
export class AdvancedSunshineCalculator {
  private sunAngleHelper: SunAngleHelper;

  constructor() {
    this.sunAngleHelper = new SunAngleHelper();
  }

  /**
   * 计算特定单元的全年光照时间
   * @param buildings 所有建筑物
   * @param targetBuilding 目标建筑物
   * @param floorIndex 楼层索引(从1开始)
   * @param unitIndex 单元索引(从1开始,从右到左)
   * @param latitude 纬度
   * @param longitude 经度
   * @param scaleMetersPerCell 每格代表的米数
   * @param minutesStep 计算步长(分钟)
   * @returns 光照结果对象
   */
  calculateUnitSunshine(
    buildings: BuildingModel[],
    targetBuilding: BuildingModel,
    floorIndex: number,
    unitIndex: number,
    latitude: number,
    longitude: number,
    scaleMetersPerCell: number = 10,
    minutesStep: number = 5
  ): UnitSunshineResult {
    // 计算层中心高度
    const pointZ = (floorIndex - 0.5) * targetBuilding.floorHeight;
    
    // 计算单元中心点坐标
    const unitPoint = this.getUnitCenterPoint(targetBuilding, unitIndex);
    
    // 时区推断(简单按经度/15)
    const timeZone = Math.round(longitude / 15);
    
    // 特殊日期(日序)
    const springDay = this.getEquinoxDay('spring');    // 春分 ~79
    const summerDay = this.getSolsticeDay('summer');   // 夏至 ~172
    const autumnDay = this.getEquinoxDay('autumn');    // 秋分 ~266
    const winterDay = this.getSolsticeDay('winter');   // 冬至 ~355
    const greatColdDay = 20;                           // 大寒 1月20日
    
    const result: UnitSunshineResult = {
      buildingId: targetBuilding.id,
      floorIndex: floorIndex,
      unitIndex: unitIndex,
      springEquinox: 0,
      summerSolstice: 0,
      autumnalEquinox: 0,
      winterSolstice: 0,
      greatCold: 0,
      annualAverage: 0
    };
    
    // 计算特殊日期的日照时间(小时)
    result.springEquinox = this.computeDaySunshineMinutes(
      buildings,
      targetBuilding,
      unitPoint,
      pointZ,
      latitude,
      longitude,
      springDay,
      timeZone,
      minutesStep
    ) / 60;
    
    result.summerSolstice = this.computeDaySunshineMinutes(
      buildings,
      targetBuilding,
      unitPoint,
      pointZ,
      latitude,
      longitude,
      summerDay,
      timeZone,
      minutesStep
    ) / 60;
    
    result.autumnalEquinox = this.computeDaySunshineMinutes(
      buildings,
      targetBuilding,
      unitPoint,
      pointZ,
      latitude,
      longitude,
      autumnDay,
      timeZone,
      minutesStep
    ) / 60;
    
    result.winterSolstice = this.computeDaySunshineMinutes(
      buildings,
      targetBuilding,
      unitPoint,
      pointZ,
      latitude,
      longitude,
      winterDay,
      timeZone,
      minutesStep
    ) / 60;
    
    result.greatCold = this.computeDaySunshineMinutes(
      buildings,
      targetBuilding,
      unitPoint,
      pointZ,
      latitude,
      longitude,
      greatColdDay,
      timeZone,
      minutesStep
    ) / 60;
    
    // 年度平均:取每月中旬的12个样本
    const monthlySamples = [15, 46, 74, 105, 135, 166, 196, 227, 258, 288, 319, 349];
    let totalMinutes = 0;
    
    for (const dayOfYear of monthlySamples) {
      totalMinutes += this.computeDaySunshineMinutes(
        buildings,
        targetBuilding,
        unitPoint,
        pointZ,
        latitude,
        longitude,
        dayOfYear,
        timeZone,
        minutesStep
      );
    }
    
    result.annualAverage = totalMinutes / monthlySamples.length / 60;
    
    return result;
  }

  /**
   * 计算某一天的光照时间(分钟)
   */
  private computeDaySunshineMinutes(
    buildings: BuildingModel[],
    targetBuilding: BuildingModel,
    unitPoint: Point3D,
    pointZ: number,
    latitude: number,
    longitude: number,
    dayOfYear: number,
    timeZone: number,
    minutesStep: number
  ): number {
    // 计算日照长度(小时)
    const dayLengthHours = this.getDayLengthHours(latitude, dayOfYear);
    const midday = 12;
    const span = dayLengthHours / 2 + 1; // 额外1小时缓冲
    const startMinutes = Math.max(0, (midday - span) * 60);
    const endMinutes = Math.min(24 * 60, (midday + span) * 60);
    
    let litMinutes = 0;
    
    // 遍历一天中的每个时间步长
    for (let minutes = startMinutes; minutes <= endMinutes; minutes += minutesStep) {
      // 计算当前时刻的太阳位置
      const sunPosition = this.getSolarPosition(latitude, longitude, dayOfYear, minutes, timeZone);
      
      // 太阳在地平线以下,跳过
      if (sunPosition.altitude <= 0) {
        continue;
      }
      
      // 低高度剔除(可选,提高计算效率)
      if (sunPosition.altitude < 5) {
        continue;
      }
      
      // 检查是否被其他建筑物遮挡
      if (!this.isBlockedByBuildings(
        buildings,
        targetBuilding,
        unitPoint,
        pointZ,
        sunPosition
      )) {
        litMinutes += minutesStep;
      }
    }
    
    return litMinutes;
  }

  /**
   * 检查光线是否被建筑物遮挡
   */
  private isBlockedByBuildings(
    buildings: BuildingModel[],
    targetBuilding: BuildingModel,
    unitPoint: Point3D,
    pointZ: number,
    sunPosition: SunPosition
  ): boolean {
    const altitudeRad = sunPosition.altitude * Math.PI / 180;
    const azimuthRad = sunPosition.azimuth * Math.PI / 180;
    
    // 计算光线方向向量
    // 坐标系: x向右=东, y向下=南, z向上
    const dirX = Math.sin(azimuthRad) * Math.cos(altitudeRad);
    const dirY = -Math.cos(azimuthRad) * Math.cos(altitudeRad); // 北=负y
    const dirZ = Math.sin(altitudeRad);
    
    // 光线起点
    const origin = new Point3D(unitPoint.x, unitPoint.y, pointZ);
    
    // 检查每个建筑物(除了目标建筑本身)
    for (const building of buildings) {
      if (building.id === targetBuilding.id) {
        continue;
      }
      
      // 射线与建筑物包围盒相交测试
      if (this.rayHitBox(origin, dirX, dirY, dirZ, building)) {
        return true; // 被遮挡
      }
    }
    
    return false; // 未被遮挡
  }

  /**
   * 射线与建筑物包围盒相交测试
   */
  private rayHitBox(
    origin: Point3D,
    dirX: number,
    dirY: number,
    dirZ: number,
    building: BuildingModel
  ): boolean {
    // 转换到建筑物局部坐标系
    const angle = -building.rotationDeg * Math.PI / 180;
    const cosA = Math.cos(angle);
    const sinA = Math.sin(angle);
    
    // 将原点转换到局部坐标
    const dx = origin.x - building.x;
    const dy = origin.y - building.y;
    const localOriginX = dx * cosA - dy * sinA;
    const localOriginY = dx * sinA + dy * cosA;
    const localOriginZ = origin.z;
    
    // 将方向向量转换到局部坐标
    const localDirX = dirX * cosA - dirY * sinA;
    const localDirY = dirX * sinA + dirY * cosA;
    const localDirZ = dirZ;
    
    // 建筑物包围盒半尺寸
    const halfWidth = building.width / 2;
    const halfLength = building.length / 2;
    const height = building.height;
    
    // AABB射线相交测试
    const tx1 = (-halfWidth - localOriginX) / localDirX;
    const tx2 = (halfWidth - localOriginX) / localDirX;
    const ty1 = (-halfLength - localOriginY) / localDirY;
    const ty2 = (halfLength - localOriginY) / localDirY;
    
    let tmin = Math.max(Math.min(tx1, tx2), Math.min(ty1, ty2));
    let tmax = Math.min(Math.max(tx1, tx2), Math.max(ty1, ty2));
    
    if (tmax < 0 || tmin > tmax) {
      return false;
    }
    
    // Z轴测试
    const tz1 = (0 - localOriginZ) / localDirZ;
    const tz2 = (height - localOriginZ) / localDirZ;
    
    tmin = Math.max(tmin, Math.min(tz1, tz2));
    tmax = Math.min(tmax, Math.max(tz1, tz2));
    
    if (tmax < 0 || tmin > tmax) {
      return false;
    }
    
    return tmax > 0; // 有交点
  }

  /**
   * 获取单元中心点坐标
   */
  private getUnitCenterPoint(building: BuildingModel, unitIndex: number): Point3D {
    const units = Math.max(1, Math.round(building.units));
    
    // 右起编号: 1=最右, 转换为左起偏移
    const offset = units - unitIndex;
    const fracCenter = (offset + 0.5) / units; // 0..1 从左到右
    const localX = (fracCenter - 0.5) * building.width;
    const localY = 0;
    
    // 旋转到世界坐标
    const angle = building.rotationDeg * Math.PI / 180;
    const worldX = building.x + localX * Math.cos(angle) - localY * Math.sin(angle);
    const worldY = building.y + localX * Math.sin(angle) + localY * Math.cos(angle);
    
    return new Point3D(worldX, worldY, 0);
  }

  /**
   * 计算太阳位置
   */
  private getSolarPosition(
    latitude: number,
    longitude: number,
    dayOfYear: number,
    minutes: number,
    timeZone: number
  ): SunPosition {
    // 简化的太阳位置计算
    const localHour = minutes / 60; // 当地时间(小时)
    
    // 时间方程校正
    const eqTime = this.getEquationOfTime(dayOfYear);
    
    // 标准经线
    const lstm = timeZone * 15;
    
    // 时间校正(分钟)
    const tc = eqTime + 4 * (longitude - lstm);
    
    // 太阳时(小时)
    const solarTime = localHour + tc / 60;
    
    // 时角(度)
    const hourAngleDeg = (solarTime - 12) * 15;
    const hourAngleRad = hourAngleDeg * Math.PI / 180;
    
    // 太阳赤纬
    const declination = this.getSolarDeclination(dayOfYear);
    
    // 纬度转弧度
    const latRad = latitude * Math.PI / 180;
    
    // 天顶角余弦
    const cosZenith = Math.sin(latRad) * Math.sin(declination) +
                      Math.cos(latRad) * Math.cos(declination) * Math.cos(hourAngleRad);
    
    const zenith = Math.acos(Math.min(1, Math.max(-1, cosZenith)));
    const altitudeDeg = 90 - zenith * 180 / Math.PI;
    
    // 方位角(从北顺时针)
    let azimuthRad = Math.atan2(
      Math.sin(hourAngleRad),
      Math.cos(hourAngleRad) * Math.sin(latRad) - Math.tan(declination) * Math.cos(latRad)
    );
    
    let azimuthDeg = azimuthRad * 180 / Math.PI;
    azimuthDeg = (azimuthDeg + 180 + 360) % 360; // 转换为0-360度
    
    return new SunPosition(altitudeDeg, azimuthDeg);
  }

  /**
   * 计算太阳赤纬(弧度)
   */
  private getSolarDeclination(dayOfYear: number): number {
    return 0.409 * Math.sin(2 * Math.PI * (dayOfYear - 81) / 365);
  }

  /**
   * 计算时间方程(分钟)
   */
  private getEquationOfTime(dayOfYear: number): number {
    const B = 2 * Math.PI / 364 * (dayOfYear - 81);
    return 9.87 * Math.sin(2 * B) - 7.53 * Math.cos(B) - 1.5 * Math.sin(B);
  }

  /**
   * 计算日照长度(小时)
   */
  private getDayLengthHours(latitude: number, dayOfYear: number): number {
    const latRad = latitude * Math.PI / 180;
    const declination = this.getSolarDeclination(dayOfYear);
    
    const hourAngle = Math.acos(
      Math.min(1, Math.max(-1, -Math.tan(latRad) * Math.tan(declination)))
    );
    
    return 2 * hourAngle * 180 / Math.PI / 15;
  }

  /**
   * 获取春分/秋分日序
   */
  private getEquinoxDay(season: 'spring' | 'autumn'): number {
    return season === 'spring' ? 79 : 266;
  }

  /**
   * 获取夏至/冬至日序
   */
  private getSolsticeDay(season: 'summer' | 'winter'): number {
    return season === 'summer' ? 172 : 355;
  }
}

/**
 * 单元光照结果
 */
export interface UnitSunshineResult {
  buildingId: number;
  floorIndex: number;
  unitIndex: number;
  springEquinox: number;      // 春分日照时间(小时)
  summerSolstice: number;     // 夏至日照时间(小时)
  autumnalEquinox: number;    // 秋分日照时间(小时)
  winterSolstice: number;     // 冬至日照时间(小时)
  greatCold: number;          // 大寒日照时间(小时)
  annualAverage: number;      // 年度平均日照时间(小时/天)
}
