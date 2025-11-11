/**
 * 单元日照数据模型
 */
export class UnitSunshineData {
  buildingId: number = 0;
  floor: number = 1;
  unitIndex: number = 0;
  x: number = 0;
  y: number = 0;
  z: number = 0;
  
  // 日照时长数据(小时)
  totalSunshineHours: number = 0;
  winterSolsticeSunshine: number = 0;
  springEquinoxSunshine: number = 0;
  summerSolsticeSunshine: number = 0;
  autumnEquinoxSunshine: number = 0;
  greatColdSunshine: number = 0;
  averageDailySunshine: number = 0; // 年均每日日照时长(小时)
  
  /**
   * 获取热力图颜色(根据日照时长)
   */
  getHeatmapColor(): string {
    const hours = this.winterSolsticeSunshine; // 使用冬至日照作为主要指标
    
    if (hours >= 3) {
      return '#4CAF50'; // 绿色 - 充足
    } else if (hours >= 2) {
      return '#8BC34A'; // 浅绿 - 良好
    } else if (hours >= 1) {
      return '#FFC107'; // 黄色 - 一般
    } else if (hours >= 0.5) {
      return '#FF9800'; // 橙色 - 较差
    } else {
      return '#F44336'; // 红色 - 不足
    }
  }
  
  /**
   * 获取热力图透明度
   */
  getHeatmapOpacity(): number {
    const hours = this.winterSolsticeSunshine;
    return Math.min(0.8, 0.3 + (hours / 3) * 0.5);
  }
  
  /**
   * 是否符合规范(冬至日照>=2小时)
   */
  meetsStandard(): boolean {
    return this.winterSolsticeSunshine >= 2;
  }
}

/**
 * 3D视图配置
 */
export class View3DConfig {
  // 相机位置
  cameraDistance: number = 200;
  cameraAngleX: number = 45; // 俯仰角
  cameraAngleY: number = 45; // 旋转角
  
  // 视图尺寸
  viewWidth: number = 800;
  viewHeight: number = 600;
  
  // 是否显示热力图
  showHeatmap: boolean = true;
  
  // 是否显示网格
  showGrid: boolean = true;
  
  // 是否显示坐标轴
  showAxis: boolean = true;
}
