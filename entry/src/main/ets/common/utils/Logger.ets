import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 日志工具类
 */
export class Logger {
  private static domain: number = 0xFF00;
  private static prefix: string = '[Sunshine]';

  /**
   * 打印调试日志
   */
  static debug(tag: string, format: string, ...args: string[]): void {
    hilog.debug(Logger.domain, Logger.prefix, `[${tag}] ${format}`, args);
  }

  /**
   * 打印信息日志
   */
  static info(tag: string, format: string, ...args: string[]): void {
    hilog.info(Logger.domain, Logger.prefix, `[${tag}] ${format}`, args);
  }

  /**
   * 打印警告日志
   */
  static warn(tag: string, format: string, ...args: string[]): void {
    hilog.warn(Logger.domain, Logger.prefix, `[${tag}] ${format}`, args);
  }

  /**
   * 打印错误日志
   */
  static error(tag: string, format: string, ...args: string[]): void {
    hilog.error(Logger.domain, Logger.prefix, `[${tag}] ${format}`, args);
  }
}
