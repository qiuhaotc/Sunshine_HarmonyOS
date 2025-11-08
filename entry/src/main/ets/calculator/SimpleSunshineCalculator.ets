import { HouseInputModel } from '../model/HouseInputModel';
import { HouseSunshineModel } from '../model/HouseSunshineModel';
import { SunAngleHelper } from '../utils/SunAngleHelper';

/**
 * 基础光照计算器
 * 用于计算简单场景下的房屋光照情况
 * 模仿C#实现: https://github.com/qiuhaotc/Sunshine/blob/main/Sunshine.Business/SunshineCalculater.cs
 */
export class SimpleSunshineCalculator {
  private sunAngleHelper: SunAngleHelper;
  private readonly MIN_MINUTES_STEP: number = 1;

  constructor() {
    this.sunAngleHelper = new SunAngleHelper();
  }

  /**
   * 计算房屋光照模型 - 模仿C#实现
   * @param houseInput 房屋输入参数
   * @param minutesStep 计算步长(分钟)，默认1分钟
   * @returns 房屋光照结果
   */
  calculateHouseSunshine(houseInput: HouseInputModel, minutesStep: number = 1): HouseSunshineModel {
    // 确保步长不小于最小值
    if (minutesStep < this.MIN_MINUTES_STEP) {
      minutesStep = this.MIN_MINUTES_STEP;
    }

    // 计算遮挡角度 (转换为度，因为sunPosition.altitude返回的是度)
    const tan = (houseInput.blockLevel * houseInput.blockLevelHeight - 
                 houseInput.level * houseInput.levelHeight) / houseInput.distance;
    const blockAngleRad = Math.atan(tan); // 先计算弧度
    const blockAngle = blockAngleRad * (180 / Math.PI); // 转换为度，与getSunAngle返回的单位一致

    // 初始化时间统计 (分钟)
    let totalSunshineTime = 0;
    let exactSunshineTime = 0;
    let springEquinox = 0;
    let summerSolstice = 0;
    let autumnalEquinox = 0;
    let winterSolstice = 0;
    let greatCold = 0;

    // 设置起始和结束时间(UTC) - 模仿C#实现
    const dateTimeUtc = new Date(Date.UTC(houseInput.year, 0, 1, 0, 0, 0));
    dateTimeUtc.setTime(dateTimeUtc.getTime() - houseInput.timeZone * 3600000);
    
    const dateTimeToUtc = new Date(Date.UTC(houseInput.year + 1, 0, 1, 0, 0, 0));
    dateTimeToUtc.setTime(dateTimeToUtc.getTime() - houseInput.timeZone * 3600000);

    // 按照C#代码逻辑，遍历整年的每一分钟
    let currentDateTimeUtc = new Date(dateTimeUtc.getTime());
    const stepMs = minutesStep * 60000;

    while (currentDateTimeUtc.getTime() < dateTimeToUtc.getTime()) {
      // 获取本地时间 (用于判断特殊日期)
      const currentLocalDate = new Date(currentDateTimeUtc.getTime() + houseInput.timeZone * 3600000);
      
      // 计算当前时刻的太阳高度角
      const sunPosition = this.sunAngleHelper.getSunAngle(
        houseInput.latitude,
        houseInput.longitude,
        currentDateTimeUtc
      );

      // 如果太阳在地平线以上 (altitude >= 0)
      if (sunPosition.altitude >= 0) {
        // 累加总日照时间
        totalSunshineTime += minutesStep;

        // 如果太阳高度角大于等于遮挡角度，说明有直射光
        if (sunPosition.altitude >= blockAngle) {
          exactSunshineTime += minutesStep;

          // 判断特殊日期并累加时间
          const month = currentLocalDate.getUTCMonth() + 1;
          const day = currentLocalDate.getUTCDate();

          switch (month) {
            case 1:
              if (day === 20) {
                greatCold += minutesStep;
              }
              break;
            case 3:
              if (day === 21) {
                springEquinox += minutesStep;
              }
              break;
            case 6:
              if (day === 22) {
                summerSolstice += minutesStep;
              }
              break;
            case 9:
              if (day === 23) {
                autumnalEquinox += minutesStep;
              }
              break;
            case 12:
              if (day === 22) {
                winterSolstice += minutesStep;
              }
              break;
          }
        }
      }

      // 增加时间步长
      currentDateTimeUtc = new Date(currentDateTimeUtc.getTime() + stepMs);
    }

    // 构建结果模型
    const result = new HouseSunshineModel();
    result.totalSunshineTime = totalSunshineTime;
    result.exactSunshineTime = exactSunshineTime;
    result.springEquinox = springEquinox;
    result.summerSolstice = summerSolstice;
    result.autumnalEquinox = autumnalEquinox;
    result.winterSolstice = winterSolstice;
    result.greatCold = greatCold;

    console.info(`计算完成 - 步长: ${minutesStep}分钟, 遮挡角度: ${blockAngle.toFixed(2)}度, ` +
                 `总日照: ${totalSunshineTime}分钟(${(totalSunshineTime/60).toFixed(3)}小时), ` +
                 `有效日照: ${exactSunshineTime}分钟(${(exactSunshineTime/60).toFixed(3)}小时)`);

    return result;
  }

  /**
   * 验证光照结果是否符合标准
   * @param result 光照结果
   * @returns 是否符合标准
   */
  validateSunshineResult(result: HouseSunshineModel): boolean {
    // 房屋日照时间在大寒大于2小时，冬至大于1小时
    return result.greatCold >= 120 && result.winterSolstice >= 60;
  }

  /**
   * 获取验证结果描述
   * @param result 光照结果
   * @returns 验证结果描述
   */
  getValidationDescription(result: HouseSunshineModel): string {
    if (this.validateSunshineResult(result)) {
      return '房屋日照时间在大寒大于两小时，冬至大于一小时';
    } else {
      return '房屋日照时间在大寒小于两小时或冬至小于一小时';
    }
  }
}
