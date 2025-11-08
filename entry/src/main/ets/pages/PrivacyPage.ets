import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/utils/Logger';

/**
 * 隐私政策页面
 */
@Entry
@Component
struct PrivacyPage {
  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('sys.symbol.chevron_left'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text('隐私政策')
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位,保持标题居中
        Row().width(24)
      }
      .width(CommonConstants.FULL_WIDTH)
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#1976D2')

      // 内容区域
      Scroll() {
        Column() {
          Text('隐私政策')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 24, bottom: 16 })

          Text('更新日期: 2025年11月5日')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 24 })

          Text('一、信息收集')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 12 })

          Text(
            '我们承诺保护您的隐私。本应用是一款房屋光照计算工具,主要功能包括:\n' +
            '• 计算房屋在不同时间的光照情况\n' +
            '• 分析建筑物遮挡对光照的影响\n' +
            '• 提供光照数据可视化展示\n\n' +
            '本应用不会收集您的个人信息,所有计算均在本地设备上完成。'
          )
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
            .margin({ bottom: 24 })

          Text('二、信息使用')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 12 })

          Text(
            '本应用存储的数据包括:\n' +
            '• 您输入的建筑物参数(仅存储在本地设备)\n' +
            '• 应用使用偏好设置\n\n' +
            '这些数据仅用于改善您的使用体验,不会上传到任何服务器。'
          )
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
            .margin({ bottom: 24 })

          Text('三、权限说明')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 12 })

          Text(
            '本应用可能需要以下权限:\n' +
            '• 存储权限: 用于保存计算结果和配置信息\n' +
            '• 位置权限: 用于自动获取当前城市的经纬度(可选)\n\n' +
            '所有权限均为可选,拒绝授权不影响核心功能使用。'
          )
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
            .margin({ bottom: 24 })

          Text('四、数据安全')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 12 })

          Text(
            '我们采取以下措施保护您的数据安全:\n' +
            '• 所有数据仅存储在本地设备\n' +
            '• 不会收集或上传任何个人信息\n' +
            '• 不包含任何第三方追踪代码\n' +
            '• 不进行任何数据分析或统计'
          )
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
            .margin({ bottom: 24 })

          Text('五、联系我们')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 12 })

          Text(
            '如您对本隐私政策有任何疑问,请通过以下方式联系我们:\n' +
            '邮箱: support@sunshine-calculator.com'
          )
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
            .margin({ bottom: 40 })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width(CommonConstants.FULL_WIDTH)
    .height(CommonConstants.FULL_HEIGHT)
    .backgroundColor($r('app.color.page_background'))
  }
}
