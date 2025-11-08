/**
 * 建筑物模型
 */
export class BuildingModel {
  // 建筑物ID
  id: number = 0;
  // 宽度(逻辑单位，实际米数由比例尺决定)
  width: number = 5.4;
  // 长度(逻辑单位)
  length: number = 1;
  // 总高度(米)
  height: number = 60;
  // 层高(米)
  floorHeight: number = 3;
  // 单元数
  units: number = 4;
  // 旋转角度(度，顺时针，0度为北)
  rotationDeg: number = 0;
  // X坐标(逻辑单位)
  x: number = 0;
  // Y坐标(逻辑单位)
  y: number = 0;

  /**
   * 获取楼层数
   */
  getFloorCount(): number {
    return Math.max(1, Math.floor(this.height / this.floorHeight));
  }

  /**
   * 克隆建筑物
   */
  clone(): BuildingModel {
    const building = new BuildingModel();
    building.id = this.id;
    building.width = this.width;
    building.length = this.length;
    building.height = this.height;
    building.floorHeight = this.floorHeight;
    building.units = this.units;
    building.rotationDeg = this.rotationDeg;
    building.x = this.x;
    building.y = this.y;
    return building;
  }
}
