/**
 * 主页面 - 房屋光照计算器
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  build() {
    Column() {
      // 标题
      Row() {
        Text('房屋光照计算器')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(60)
      .backgroundColor('#1976D2')
      .justifyContent(FlexAlign.Center)

      // 功能选择区域 - 添加滚动支持
      Scroll() {
        Column() {
          Text('选择功能模块')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 40, bottom: 30 })

        // 基础光照计算器按钮
        Button('基础光照计算器')
          .width('80%')
          .height(60)
          .fontSize(18)
          .margin({ bottom: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/SimpleCalculator'
            }).catch((err: Error) => {
              console.error('路由跳转失败:', err);
            });
          })

        // 高级光照计算器按钮
        Button('高级光照计算器')
          .width('80%')
          .height(60)
          .fontSize(18)
          .backgroundColor('#FF9800')
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/AdvancedCalculator'
            }).catch((err: Error) => {
              console.error('路由跳转失败:', err);
            });
          })

        // 关于按钮
        Button('关于')
          .width('80%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#4CAF50')
          .margin({ top: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/AboutPage'
            }).catch((err: Error) => {
              console.error('路由跳转失败:', err);
            });
          })

        // 功能说明
        Column() {
          Text('功能说明')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 50, bottom: 20 })

          Text('• 基础光照计算器：')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20, bottom: 5 })

          Text('  适用于简单场景,计算单栋建筑遮挡下的房屋光照情况')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20, bottom: 15 })

          Text('• 高级光照计算器:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20, bottom: 5 })

          Text('  支持多建筑物布局,提供2D图和详细的单元光照分析')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20 })
        }
        .width('80%')
        .margin(15)
        .padding(15)
        .backgroundColor($r('app.color.input_background'))
        .borderRadius(10)
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}