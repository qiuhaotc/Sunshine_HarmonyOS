/**
 * 日照评分系统
 * 根据日照时长和国家标准评估房屋采光质量
 */

/**
 * 日照等级枚举
 */
export enum SunshineRating {
  EXCELLENT = '优秀',
  GOOD = '良好',
  FAIR = '一般',
  POOR = '较差',
  VERY_POOR = '很差'
}

/**
 * 特殊日期数据
 */
export interface SpecialDays {
  dahan: number;
  dongzhi: number;
  chunfen: number;
  xiazhi: number;
  qiufen: number;
}

/**
 * 评分结果
 */
export interface RatingResult {
  rating: SunshineRating;
  score: number; // 0-100分
  color: string; // 显示颜色
  stars: number; // 星级 1-5
  summary: string; // 简短总结
  suggestions: string[]; // 建议
  meetsStandard: boolean; // 是否符合国标
}

/**
 * 日照评分系统
 */
export class SunshineRatingSystem {
  
  /**
   * 评估基础评估器结果
   * @param totalSunshineHours 全年总日照时长(小时)
   * @param dahanHours 大寒日照时长(小时)
   * @param dongzhiHours 冬至日照时长(小时)
   * @param averageDailyHours 年平均每日日照时长(小时)
   */
  static evaluateSimple(
    totalSunshineHours: number,
    dahanHours: number,
    dongzhiHours: number,
    averageDailyHours: number
  ): RatingResult {
    let score = 0;
    let suggestions: string[] = [];
    
    // 1. 国标符合性评估 (40分)
    const meetsDahan = dahanHours >= 2;
    const meetsDongzhi = dongzhiHours >= 1;
    
    if (meetsDahan && meetsDongzhi) {
      score += 40;
    } else if (meetsDahan || meetsDongzhi) {
      score += 25;
      suggestions.push('未完全符合国家日照标准,建议谨慎考虑');
    } else {
      score += 10;
      suggestions.push('不符合国家日照标准,采光较差');
    }
    
    // 2. 冬季日照评估 (30分) - 重点关注采光最差的季节
    if (dahanHours >= 4) {
      score += 30;
    } else if (dahanHours >= 3) {
      score += 25;
    } else if (dahanHours >= 2) {
      score += 20;
    } else if (dahanHours >= 1) {
      score += 10;
      suggestions.push('冬季日照时间偏短,冬天房间可能较暗');
    } else {
      score += 5;
      suggestions.push('冬季几乎无日照,不利于居住舒适度');
    }
    
    // 3. 年平均日照评估 (30分)
    if (averageDailyHours >= 6) {
      score += 30;
    } else if (averageDailyHours >= 4) {
      score += 25;
    } else if (averageDailyHours >= 3) {
      score += 20;
    } else if (averageDailyHours >= 2) {
      score += 15;
      suggestions.push('全年平均日照偏少,建议考虑更高楼层');
    } else {
      score += 5;
      suggestions.push('全年日照严重不足,强烈建议选择其他房源');
    }
    
    // 添加积极建议
    if (score >= 80) {
      suggestions.push('采光条件优秀,非常适合居住');
    } else if (score >= 60) {
      suggestions.push('采光条件尚可,建议实地查看');
    }
    
    // 根据分数确定等级
    return SunshineRatingSystem.generateRatingResult(score, suggestions, meetsDahan && meetsDongzhi);
  }
  
  /**
   * 评估高级评估器结果(单元日照)
   * @param totalSunshineHours 全年总日照时长(小时)
   * @param specialDays 特殊日期数据
   */
  static evaluateAdvanced(
    totalSunshineHours: number,
    specialDays: SpecialDays
  ): RatingResult {
    const averageDailyHours = totalSunshineHours / 365;
    return SunshineRatingSystem.evaluateSimple(
      totalSunshineHours,
      specialDays.dahan,
      specialDays.dongzhi,
      averageDailyHours
    );
  }
  
  /**
   * 生成评分结果
   */
  private static generateRatingResult(
    score: number,
    suggestions: string[],
    meetsStandard: boolean
  ): RatingResult {
    let rating: SunshineRating;
    let color: string;
    let stars: number;
    let summary: string;
    
    if (score >= 85) {
      rating = SunshineRating.EXCELLENT;
      color = '#4CAF50'; // 绿色
      stars = 5;
      summary = '采光极佳,日照充足,非常适合居住';
    } else if (score >= 70) {
      rating = SunshineRating.GOOD;
      color = '#8BC34A'; // 浅绿
      stars = 4;
      summary = '采光良好,日照时间较充足,适合居住';
    } else if (score >= 55) {
      rating = SunshineRating.FAIR;
      color = '#FFC107'; // 黄色
      stars = 3;
      summary = '采光一般,建议综合考虑其他因素';
    } else if (score >= 40) {
      rating = SunshineRating.POOR;
      color = '#FF9800'; // 橙色
      stars = 2;
      summary = '采光较差,日照时间不足,建议谨慎选择';
    } else {
      rating = SunshineRating.VERY_POOR;
      color = '#F44336'; // 红色
      stars = 1;
      summary = '采光很差,严重缺乏日照,不推荐';
    }
    
    return {
      rating,
      score: Math.round(score),
      color,
      stars,
      summary,
      suggestions,
      meetsStandard
    };
  }
  
  /**
   * 获取星级显示字符串
   */
  static getStarsDisplay(stars: number): string {
    return '⭐'.repeat(stars) + '☆'.repeat(5 - stars);
  }
  
  /**
   * 获取评分说明文本
   */
  static getScoreDescription(score: number): string {
    if (score >= 85) return '极优';
    if (score >= 70) return '优良';
    if (score >= 55) return '中等';
    if (score >= 40) return '偏低';
    return '很低';
  }
}
