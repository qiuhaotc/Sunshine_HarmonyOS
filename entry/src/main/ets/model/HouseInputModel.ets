/**
 * 房屋输入参数模型
 */
export class HouseInputModel {
  // 遮挡楼栋层数
  blockLevel: number = 18;
  // 遮挡楼栋每层高度(米)
  blockLevelHeight: number = 3.1;
  // 遮挡楼栋与目标楼栋的距离(米)
  distance: number = 60;
  // 纬度
  latitude: number = 31.684327;
  // 目标楼栋所在层数
  level: number = 12;
  // 目标楼栋每层高度(米)
  levelHeight: number = 3.1;
  // 经度
  longitude: number = 118.510117;
  // 时区
  timeZone: number = 8;
  // 年份
  year: number = new Date().getFullYear();
}
