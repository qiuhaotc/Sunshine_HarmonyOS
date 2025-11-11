/**
 * 通用常量类
 */
export class CommonConstants {
  /**
   * 首选项存储文件名
   */
  static readonly PREFERENCES_FILE_NAME: string = 'SunshinePreferences';

  /**
   * 隐私协议状态键名
   */
  static readonly PREFERENCES_KEY_PRIVACY: string = 'isPrivacyAgreed';

  /**
   * 隐私协议页面URL
   */
  static readonly PRIVACY_PAGE_URL: string = 'pages/PrivacyPage';

  /**
   * 华为官方隐私政策URL
   */
  static readonly PRIVACY_AGREEMENT_URL: string = 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1816908790834960960';

  /**
   * 启动页URL
   */
  static readonly LAUNCHER_PAGE_URL: string = 'pages/LauncherPage';

  /**
   * 主页URL
   */
  static readonly INDEX_PAGE_URL: string = 'pages/Index';

  /**
   * 启动页延迟时间(毫秒)
   */
  static readonly LAUNCHER_DELAY_TIME: number = 1000;

  /**
   * 全屏宽度百分比
   */
  static readonly FULL_WIDTH: string = '100%';

  /**
   * 全屏高度百分比
   */
  static readonly FULL_HEIGHT: string = '100%';

  /**
   * 对话框宽度百分比
   */
  static readonly DIALOG_COMPONENT_WIDTH_PERCENT: string = '93.3%';

  /**
   * 通用布局权重
   */
  static readonly COMMON_LAYOUT_WEIGHT: number = 1;

  /**
   * 对话框行下边距
   */
  static readonly DIALOG_ROW_MARGIN_BOTTOM: string = '16vp';

  /**
   * 日志标签 - 启动页
   */
  static readonly LAUNCHER_PAGE_TAG: string = 'LauncherPage';

  /**
   * 日志标签 - 自定义对话框
   */
  static readonly CUSTOM_DIALOG_TAG: string = 'CustomDialog';

  /**
   * 日志标签 - 隐私页面
   */
  static readonly PRIVACY_PAGE_TAG: string = 'PrivacyPage';
}
