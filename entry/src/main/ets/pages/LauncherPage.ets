import { preferences } from '@kit.ArkData';
import { CommonConstants } from '../common/constants/CommonConstants';
import { GlobalContext } from '../common/utils/GlobalContext';
import { Logger } from '../common/utils/Logger';
import { PrivacyDialogComponent } from '../view/PrivacyDialogComponent';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 应用启动页
 */
@Entry
@Component
struct LauncherPage {
  private timerId: number = -1;
  private isJumpToIndex: boolean = false;

  // 隐私协议弹窗控制器
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PrivacyDialogComponent({
      cancel: () => {
        this.onCancel();
      },
      confirm: () => {
        this.onConfirm();
      }
    }),
    autoCancel: false,
    customStyle: true
  });

  aboutToDisappear(): void {
    // 清除定时器
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  onPageShow(): void {
    // 重置跳转标志
    GlobalContext.getContext().setObject('isJumpPrivacy', false);

    // 获取首选项并检查隐私协议状态
    this.getDataPreferences().then((prefs: preferences.Preferences) => {
      prefs.get(CommonConstants.PREFERENCES_KEY_PRIVACY, true)
        .then((value: preferences.ValueType) => {
          Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'Privacy status: ' + value);

          if (value === true) {
            // 未同意隐私协议,显示弹窗
            let isJumpPrivacy: boolean =
              (GlobalContext.getContext().getObject('isJumpPrivacy') as boolean) ?? false;

            if (!isJumpPrivacy) {
              this.dialogController.open();
            }
          } else {
            // 已同意隐私协议,跳转到主页
            this.jumpToIndexPage();
          }
        })
        .catch((err: BusinessError) => {
          Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Get preferences value error: ' + err);
        });
    }).catch((err: BusinessError) => {
      Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Get preferences error: ' + err);
    });
  }

  /**
   * 获取数据首选项
   */
  getDataPreferences(): Promise<preferences.Preferences> {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return preferences.getPreferences(context, CommonConstants.PREFERENCES_FILE_NAME);
  }

  /**
   * 不同意按钮回调
   */
  onCancel(): void {
    Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'Privacy not agreed');
    // 退出应用
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.terminateSelf();
    } catch (err) {
      Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Terminate self error: ' + JSON.stringify(err));
    }
  }

  /**
   * 同意按钮回调
   */
  onConfirm(): void {
    Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'Privacy agreed');
    this.saveIsPrivacy();
    this.jumpToIndexPage();
  }

  /**
   * 保存隐私协议状态
   */
  saveIsPrivacy(): void {
    try {
      let preferencesPromise: Promise<preferences.Preferences> = this.getDataPreferences();
      preferencesPromise.then((prefs: preferences.Preferences) => {
        // 保存隐私协议状态为已同意(false表示不再显示)
        prefs.put(CommonConstants.PREFERENCES_KEY_PRIVACY, false).then(() => {
          prefs.flush();
          Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'Privacy status saved');
        }).catch((err: BusinessError) => {
          Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Save privacy status error: ' + err);
        });
      }).catch((err: BusinessError) => {
        Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Get preferences error: ' + err);
      });
    } catch (err) {
      Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Save privacy exception: ' + JSON.stringify(err));
    }
  }

  /**
   * 跳转到主页
   */
  jumpToIndexPage(): void {
    this.timerId = setTimeout(() => {
      this.isJumpToIndex = true;
      this.getUIContext().getRouter().replaceUrl({
        url: CommonConstants.INDEX_PAGE_URL
      }).catch((error: Error) => {
        Logger.error(CommonConstants.LAUNCHER_PAGE_TAG,
          'Jump to index error: ' + JSON.stringify(error));
      });
    }, CommonConstants.LAUNCHER_DELAY_TIME);
  }

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width(CommonConstants.FULL_WIDTH)
        .height(CommonConstants.FULL_HEIGHT)
        .linearGradient({
          angle: 135,
          colors: [
            ['#1976D2', 0.0],
            ['#64B5F6', 1.0]
          ]
        })

      Column() {
        // Logo图标
        Image($r('app.media.startIcon'))
          .width(120)
          .height(120)
          .margin({ top: 120 })

        // 应用名称
        Text('房屋光照助手')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ top: 24 })

        // 应用介绍
        Text('精准计算 · 科学选房')
          .fontSize(16)
          .fontColor('#E0F2FE')
          .margin({ top: 12 })
      }
      .width(CommonConstants.FULL_WIDTH)
      .height(CommonConstants.FULL_HEIGHT)
    }
    .width(CommonConstants.FULL_WIDTH)
    .height(CommonConstants.FULL_HEIGHT)
  }
}
