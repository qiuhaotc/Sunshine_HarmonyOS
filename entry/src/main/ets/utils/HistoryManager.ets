import preferences from '@ohos.data.preferences';

/**
 * 历史记录项 - 基础评估器
 */
export interface SimpleHistoryItem {
  id: string;
  timestamp: number;
  name: string; // 用户自定义名称
  cityName: string; // 城市名称
  blockLevel: number; // 遮挡楼栋层数
  blockLevelHeight: number; // 遮挡楼栋每层高度
  distance: number; // 遮挡楼栋与目标楼栋的距离
  latitude: number; // 纬度
  level: number; // 目标楼栋所在层数
  levelHeight: number; // 目标楼栋每层高度
  longitude: number; // 经度
  timeZone: number; // 时区
  year: number; // 年份
  totalSunshine: number; // 全年总日照(小时)
  winterSolsticeSunshine: number; // 冬至日照(小时)
  greatColdSunshine: number; // 大寒日照(小时)
  averageDailySunshine: number; // 年平均每日(小时)
  score: number; // 评分
}

/**
 * 建筑数据JSON格式 - 用于高级评估器历史记录
 */
export interface BuildingJSON {
  id: number;
  width: number;
  length: number;
  height: number;
  floorHeight: number;
  units: number;
  rotationDeg: number;
  x: number;
  y: number;
}

/**
 * 历史记录项 - 高级评估器
 */
export interface AdvancedHistoryItem {
  id: string;
  timestamp: number;
  name: string; // 用户自定义名称
  cityName: string; // 城市名称
  latitude: number; // 纬度
  longitude: number; // 经度
  scaleMetersPerCell: number; // 比例尺
  buildingCount: number; // 建筑数量
  buildings: BuildingJSON[]; // 建筑列表
  // 如果有计算结果也保存
  hasResult?: boolean;
  targetBuildingId?: number;
  targetFloor?: number;
  targetUnit?: number;
  totalSunshine?: number;
  winterSolsticeSunshine?: number;
  greatColdSunshine?: number;
  score?: number;
}

/**
 * 历史记录管理器
 */
export class HistoryManager {
  private static readonly SIMPLE_HISTORY_KEY = 'simple_calculator_history';
  private static readonly ADVANCED_HISTORY_KEY = 'advanced_calculator_history';
  private static readonly MAX_HISTORY_COUNT = 20; // 最多保存20条记录
  private static readonly PREFS_NAME = 'sunshine_history';

  /**
   * 获取 preferences 实例
   */
  private static async getPreferences(context: Context): Promise<preferences.Preferences> {
    return await preferences.getPreferences(context, HistoryManager.PREFS_NAME);
  }

  /**
   * 保存基础评估器历史记录
   */
  static async saveSimpleHistory(context: Context, item: SimpleHistoryItem): Promise<void> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      
      // 读取现有历史记录
      const historyStr = await prefs.get(HistoryManager.SIMPLE_HISTORY_KEY, '[]') as string;
      let history: SimpleHistoryItem[] = JSON.parse(historyStr);
      
      // 添加到列表开头
      history.unshift(item);
      
      // 限制数量
      if (history.length > HistoryManager.MAX_HISTORY_COUNT) {
        history = history.slice(0, HistoryManager.MAX_HISTORY_COUNT);
      }
      
      // 保存
      await prefs.put(HistoryManager.SIMPLE_HISTORY_KEY, JSON.stringify(history));
      await prefs.flush();
      
      console.info('历史记录已保存');
    } catch (error) {
      console.error('保存历史记录失败:', error);
    }
  }

  /**
   * 获取基础评估器历史记录列表
   */
  static async getSimpleHistory(context: Context): Promise<SimpleHistoryItem[]> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      const historyStr = await prefs.get(HistoryManager.SIMPLE_HISTORY_KEY, '[]') as string;
      return JSON.parse(historyStr);
    } catch (error) {
      console.error('读取历史记录失败:', error);
      return [];
    }
  }

  /**
   * 删除基础评估器历史记录
   */
  static async deleteSimpleHistory(context: Context, id: string): Promise<void> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      const historyStr = await prefs.get(HistoryManager.SIMPLE_HISTORY_KEY, '[]') as string;
      let history: SimpleHistoryItem[] = JSON.parse(historyStr);
      
      history = history.filter(item => item.id !== id);
      
      await prefs.put(HistoryManager.SIMPLE_HISTORY_KEY, JSON.stringify(history));
      await prefs.flush();
      
      console.info('历史记录已删除');
    } catch (error) {
      console.error('删除历史记录失败:', error);
    }
  }

  /**
   * 清空基础评估器历史记录
   */
  static async clearSimpleHistory(context: Context): Promise<void> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      await prefs.put(HistoryManager.SIMPLE_HISTORY_KEY, '[]');
      await prefs.flush();
      console.info('历史记录已清空');
    } catch (error) {
      console.error('清空历史记录失败:', error);
    }
  }

  /**
   * 保存高级评估器历史记录
   */
  static async saveAdvancedHistory(context: Context, item: AdvancedHistoryItem): Promise<void> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      
      // 读取现有历史记录
      const historyStr = await prefs.get(HistoryManager.ADVANCED_HISTORY_KEY, '[]') as string;
      let history: AdvancedHistoryItem[] = JSON.parse(historyStr);
      
      // 添加到列表开头
      history.unshift(item);
      
      // 限制数量
      if (history.length > HistoryManager.MAX_HISTORY_COUNT) {
        history = history.slice(0, HistoryManager.MAX_HISTORY_COUNT);
      }
      
      // 保存
      await prefs.put(HistoryManager.ADVANCED_HISTORY_KEY, JSON.stringify(history));
      await prefs.flush();
      
      console.info('高级评估器历史记录已保存');
    } catch (error) {
      console.error('保存高级评估器历史记录失败:', error);
    }
  }

  /**
   * 获取高级评估器历史记录列表
   */
  static async getAdvancedHistory(context: Context): Promise<AdvancedHistoryItem[]> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      const historyStr = await prefs.get(HistoryManager.ADVANCED_HISTORY_KEY, '[]') as string;
      return JSON.parse(historyStr);
    } catch (error) {
      console.error('读取高级评估器历史记录失败:', error);
      return [];
    }
  }

  /**
   * 删除高级评估器历史记录
   */
  static async deleteAdvancedHistory(context: Context, id: string): Promise<void> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      const historyStr = await prefs.get(HistoryManager.ADVANCED_HISTORY_KEY, '[]') as string;
      let history: AdvancedHistoryItem[] = JSON.parse(historyStr);
      
      history = history.filter(item => item.id !== id);
      
      await prefs.put(HistoryManager.ADVANCED_HISTORY_KEY, JSON.stringify(history));
      await prefs.flush();
      
      console.info('高级评估器历史记录已删除');
    } catch (error) {
      console.error('删除高级评估器历史记录失败:', error);
    }
  }

  /**
   * 清空高级评估器历史记录
   */
  static async clearAdvancedHistory(context: Context): Promise<void> {
    try {
      const prefs = await HistoryManager.getPreferences(context);
      await prefs.put(HistoryManager.ADVANCED_HISTORY_KEY, '[]');
      await prefs.flush();
      console.info('高级评估器历史记录已清空');
    } catch (error) {
      console.error('清空高级评估器历史记录失败:', error);
    }
  }
}
