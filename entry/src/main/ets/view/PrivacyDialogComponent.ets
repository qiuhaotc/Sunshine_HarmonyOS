import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/utils/Logger';
import { common } from '@kit.AbilityKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 隐私协议自定义弹窗
 */
@CustomDialog
export struct PrivacyDialogComponent {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  // 不同意按钮回调
  cancel: () => void = () => {};
  // 同意按钮回调
  confirm: () => void = () => {};

  build() {
    Column() {
      // 弹窗标题
      Text('隐私政策与用户协议')
        .width(CommonConstants.DIALOG_COMPONENT_WIDTH_PERCENT)
        .fontColor($r('app.color.text_primary'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .margin({ top: 24, bottom: 16 })

      // 弹窗内容
      Text('欢迎使用房屋房屋光照助手！在使用我们的服务前，请您认真阅读并同意以下协议：')
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .width(CommonConstants.DIALOG_COMPONENT_WIDTH_PERCENT)
        .margin({ bottom: 8 })

      // 协议链接
      Text('《隐私政策》')
        .width(CommonConstants.DIALOG_COMPONENT_WIDTH_PERCENT)
        .fontColor($r('app.color.link_color'))
        .fontSize(14)
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openPrivacyUrl();
        })

      // 隐私协议声明
      Text('我们将严格保护您的个人信息安全。点击同意即表示您已阅读并同意上述协议。')
        .width(CommonConstants.DIALOG_COMPONENT_WIDTH_PERCENT)
        .fontColor($r('app.color.text_secondary'))
        .fontSize(12)
        .margin({ bottom: 24 })

      // 按钮行
      Row() {
        // 不同意按钮
        Text('不同意')
          .dialogButtonStyle()
          .backgroundColor($r('app.color.input_background'))
          .fontColor($r('app.color.text_primary'))
          .onClick(() => {
            this.controller.close();
            this.cancel();
          })

        Blank()
          .width(12)

        // 同意按钮
        Text('同意')
          .dialogButtonStyle()
          .backgroundColor($r('app.color.link_color'))
          .fontColor(Color.White)
          .onClick(() => {
            this.controller.close();
            this.confirm();
          })
      }
      .width(CommonConstants.DIALOG_COMPONENT_WIDTH_PERCENT)
      .margin({ bottom: 16 })
    }
    .width('100%')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(24)
  }

  /**
   * 通过浏览器打开隐私政策URL
   */
  openPrivacyUrl(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: CommonConstants.PRIVACY_AGREEMENT_URL
      };

      context.startAbility(want)
        .then(() => {
          Logger.info(CommonConstants.CUSTOM_DIALOG_TAG, 'Open privacy URL success');
        })
        .catch((err: BusinessError) => {
          Logger.error(CommonConstants.CUSTOM_DIALOG_TAG,
            'Open privacy URL failed: ' + JSON.stringify(err));
        });
    } catch (err) {
      Logger.error(CommonConstants.CUSTOM_DIALOG_TAG,
        'Open privacy URL exception: ' + JSON.stringify(err));
    }
  }
}

/**
 * 按钮公共样式
 */
@Extend(Text)
function dialogButtonStyle() {
  .fontSize(16)
  .textAlign(TextAlign.Center)
  .fontWeight(FontWeight.Medium)
  .layoutWeight(CommonConstants.COMMON_LAYOUT_WEIGHT)
  .height(40)
  .borderRadius(20)
}
