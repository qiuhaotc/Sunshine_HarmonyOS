import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { CommonConstants } from '../common/constants/CommonConstants';

/**
 * 关于页面
 */
@Entry
@Component
struct AboutPage {
  /**
   * 打开浏览器访问URL
   */
  private openUrl(url: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url
      }).then(() => {
        console.info('Successfully opened URL: ' + url);
      }).catch((err: BusinessError) => {
        console.error('Failed to open URL: ' + JSON.stringify(err));
      });
    } catch (error) {
      console.error('Error opening URL: ' + JSON.stringify(error));
    }
  }
  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('←')
            .fontSize(24)
            .fontColor(Color.White)
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

        Text('关于')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 48 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#1976D2')
      .padding({ left: 8, right: 8 })

      // 内容区域 - 支持滚动
      Scroll() {
        Column() {
          // 应用图标和名称
          Column() {
            Image($r('app.media.startIcon'))
              .width(100)
              .height(100)
              .borderRadius(20)
              .margin({ top: 30, bottom: 20 })

            Text('房屋房屋光照助手')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })

            Text('Sunshine Calculator')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 30 })
          }

          // 功能描述
          Column() {
            Text('功能介绍')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })
              .alignSelf(ItemAlign.Start)

            Text('本应用提供房屋光照时长计算功能，帮助用户评估住宅在不同季节和时间的日照情况。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 15 })

            Text('• 基础光照计算器')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)

            Text('适用于简单场景，计算单栋建筑遮挡下的房屋光照情况。支持自定义经纬度、楼层高度、遮挡距离等参数。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 15 })

            Text('• 高级光照计算器')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)

            Text('支持多建筑物布局，提供2D视图和详细的单元光照分析。可以模拟复杂的建筑群布局，计算每个单元在不同节气的光照时长。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 20 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(12)
          .margin({ bottom: 15 })

          // 免责声明
          Column() {
            Row() {
              Text('⚠️')
                .fontSize(20)
                .margin({ right: 8 })

              Text('重要提示')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.warning_text'))
            }
            .margin({ bottom: 12 })
            .alignSelf(ItemAlign.Start)

            Text('本应用提供的光照计算结果仅供参考，计算结果可能存在误差。实际光照情况会受到多种因素影响：')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 10 })

            Text('• 天气条件（云层、雾霾等）\n' +
              '• 地形地貌（山丘、树木等）\n' +
              '• 建筑物反射和阴影\n' +
              '• 玻璃窗户的透光率\n' +
              '• 季节变化和大气折射')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 10 })

            Text('如需精确的光照评估，请咨询专业建筑设计机构或使用专业测量设备。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding(20)
          .backgroundColor($r('app.color.warning_background'))
          .borderRadius(12)
          .border({ width: 1, color: $r('app.color.warning_border') })
          .margin({ bottom: 15 })

          // 项目信息
          Column() {
            Text('项目信息')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 })
              .alignSelf(ItemAlign.Start)

            Row() {
              Text('开源地址')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width(80)

              Text('github.com/qiuhaotc/Sunshine_HarmonyOS')
                .fontSize(14)
                .fontColor('#1976D2')
                .decoration({ type: TextDecorationType.Underline })
                .layoutWeight(1)
                .onClick(() => {
                  this.openUrl('https://github.com/qiuhaotc/Sunshine_HarmonyOS');
                })
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('隐私政策')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width(80)

              Text('查看隐私政策')
                .fontSize(14)
                .fontColor('#1976D2')
                .decoration({ type: TextDecorationType.Underline })
                .layoutWeight(1)
                .onClick(() => {
                  this.openUrl(CommonConstants.PRIVACY_AGREEMENT_URL);
                })
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('版本')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width(80)

              Text('1.0.0')
                .fontSize(14)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('开发框架')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width(80)

              Text('HarmonyOS NEXT')
                .fontSize(14)
                .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(12)
          .margin({ bottom: 15 })

          // 版权信息
          Column() {
            Text('© 2025 Sunshine Calculator')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 5 })

            Text('MIT License')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ top: 20, bottom: 30 })
        }
        .width('90%')
        .padding({ top: 20 })
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
