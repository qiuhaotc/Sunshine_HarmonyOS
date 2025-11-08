import { BuildingModel } from '../model/BuildingModel';
import { UnitSunshineData } from '../model/UnitSunshineData';
import { SimpleSunshineCalculator } from './SimpleSunshineCalculator';
import { HouseInputModel } from '../model/HouseInputModel';

/**
 * 3D坐标点
 */
interface Point3D {
  x: number;
  y: number;
  z: number;
}

/**
 * 单元日照计算器
 */
export class UnitSunshineCalculator {
  private calculator: SimpleSunshineCalculator = new SimpleSunshineCalculator();

  /**
   * 计算所有单元的日照数据（优化版本）
   */
  calculateAllUnits(
    buildings: BuildingModel[],
    targetBuilding: BuildingModel,
    latitude: number,
    longitude: number,
    year: number = 2024,
    timeZone: number = 8
  ): UnitSunshineData[] {
    const results: UnitSunshineData[] = [];
    
    const floorCount = targetBuilding.getFloorCount();
    const unitsPerFloor = targetBuilding.units;
    
    // 找到最近的遮挡建筑（只需要计算一次）
    const blockingBuilding = this.findClosestBlockingBuilding(buildings, targetBuilding);
    
    // 如果没有遮挡，所有单元都是满日照
    if (!blockingBuilding) {
      for (let floor = 1; floor <= floorCount; floor++) {
        for (let unitIndex = 0; unitIndex < unitsPerFloor; unitIndex++) {
          const unitData = this.createFullSunshineData(targetBuilding.id, floor, unitIndex);
          results.push(unitData);
        }
      }
      return results;
    }
    
    // 计算与遮挡建筑的距离（只计算一次）
    const distance = this.calculateDistance(targetBuilding, blockingBuilding);
    
    // 遍历每一层和每个单元
    for (let floor = 1; floor <= floorCount; floor++) {
      for (let unitIndex = 0; unitIndex < unitsPerFloor; unitIndex++) {
        const unitData = this.calculateUnitSunshineOptimized(
          buildings,
          targetBuilding,
          blockingBuilding,
          distance,
          latitude,
          longitude,
          year,
          timeZone,
          floor,
          unitIndex
        );
        
        results.push(unitData);
      }
    }
    
    return results;
  }

  /**
   * 创建无遮挡的单元数据
   */
  createFullSunshineData(
    buildingId: number,
    floor: number,
    unitIndex: number
  ): UnitSunshineData {
    const unitData = new UnitSunshineData();
    unitData.buildingId = buildingId;
    unitData.floor = floor;
    unitData.unitIndex = unitIndex;
    
    // 无遮挡不需要精确位置
    unitData.x = 0;
    unitData.y = 0;
    unitData.z = floor * 3;
    
    // 无遮挡，设置最大日照
    unitData.totalSunshineHours = 2800;
    unitData.winterSolsticeSunshine = 9;   // 冬至约9小时
    unitData.springEquinoxSunshine = 12;   // 春分约12小时
    unitData.summerSolsticeSunshine = 14;  // 夏至约14小时
    unitData.autumnEquinoxSunshine = 12;   // 秋分约12小时
    unitData.greatColdSunshine = 9;        // 大寒约9小时

    return unitData;
  }

  /**
   * 优化的单元日照计算（使用预先计算的遮挡建筑和距离）
   */
  calculateUnitSunshineOptimized(
    buildings: BuildingModel[],
    targetBuilding: BuildingModel,
    blockingBuilding: BuildingModel,
    distance: number,
    latitude: number,
    longitude: number,
    year: number,
    timeZone: number,
    floor: number,
    unitIndex: number
  ): UnitSunshineData {
    const unitData = new UnitSunshineData();
    unitData.buildingId = targetBuilding.id;
    unitData.floor = floor;
    unitData.unitIndex = unitIndex;
    
    const position = this.calculateUnitPosition(targetBuilding, floor, unitIndex);
    unitData.x = position.x;
    unitData.y = position.y;
    unitData.z = position.z;
    
    // 使用简单计算器计算日照（使用更大的时间步长以提高速度）
    const inputModel = new HouseInputModel();
    inputModel.latitude = latitude;
    inputModel.longitude = longitude;
    inputModel.level = floor;
    inputModel.levelHeight = targetBuilding.floorHeight;
    inputModel.blockLevel = blockingBuilding.getFloorCount();
    inputModel.blockLevelHeight = blockingBuilding.floorHeight;
    inputModel.distance = Math.max(10, distance);
    inputModel.year = year;
    inputModel.timeZone = timeZone;
    
    // 使用30分钟步长以提高计算速度
    const result = this.calculator.calculateHouseSunshine(inputModel, 30);
    
    unitData.totalSunshineHours = result.exactSunshineTime / 60;
    unitData.winterSolsticeSunshine = result.winterSolstice / 60;
    unitData.springEquinoxSunshine = result.springEquinox / 60;
    unitData.summerSolsticeSunshine = result.summerSolstice / 60;
    unitData.autumnEquinoxSunshine = result.autumnalEquinox / 60;
    unitData.greatColdSunshine = result.greatCold / 60;
    
    return unitData;
  }



  /**
   * 计算单元的3D位置
   */
  private calculateUnitPosition(
    building: BuildingModel,
    floor: number,
    unitIndex: number
  ): Point3D {
    const unitWidth = building.width / building.units;
    
    const position: Point3D = {
      x: building.x + unitIndex * unitWidth + unitWidth / 2,
      y: building.y + building.length / 2,
      z: (floor - 0.5) * building.floorHeight
    };
    return position;
  }

  /**
   * 找到最近的遮挡建筑
   */
  findClosestBlockingBuilding(
    buildings: BuildingModel[],
    targetBuilding: BuildingModel
  ): BuildingModel | null {
    let closest: BuildingModel | null = null;
    let minDistance = Number.MAX_VALUE;
    
    for (const building of buildings) {
      if (building.id === targetBuilding.id) {
        continue;
      }
      
      // 简化:只考虑南侧的建筑物作为遮挡
      if (building.y < targetBuilding.y) {
        const distance = this.calculateDistance(targetBuilding, building);
        if (distance < minDistance) {
          minDistance = distance;
          closest = building;
        }
      }
    }
    
    return closest;
  }

  /**
   * 计算两个建筑物之间的距离
   */
  calculateDistance(building1: BuildingModel, building2: BuildingModel): number {
    const dx = building1.x - building2.x;
    const dy = building1.y - building2.y;
    return Math.sqrt(dx * dx + dy * dy);
  }
}
