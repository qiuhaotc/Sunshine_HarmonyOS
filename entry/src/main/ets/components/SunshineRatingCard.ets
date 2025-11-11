import { RatingResult, SunshineRatingSystem } from '../utils/SunshineRatingSystem';

/**
 * 日照评分显示组件
 * 用于展示日照等级、星级和建议
 */
@Component
export struct SunshineRatingCard {
  @Prop ratingResult: RatingResult;
  
  build() {
    Column() {
      // 评分标题
      Text('日照质量评估')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })
      
      // 评分等级和分数
      Row() {
        // 等级标签
        Text(this.ratingResult.rating)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.ratingResult.color)
          .margin({ right: 15 })
        
        // 分数圆环
        Column() {
          Text(`${this.ratingResult.score}`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.ratingResult.color)
          
          Text('分')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .justifyContent(FlexAlign.Center)
        .width(80)
        .height(80)
        .border({
          width: 4,
          color: this.ratingResult.color,
          radius: 40
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ bottom: 15 })
      
      // 星级显示
      Text(SunshineRatingSystem.getStarsDisplay(this.ratingResult.stars))
        .fontSize(24)
        .margin({ bottom: 10 })
      
      // 评分说明
      Text(SunshineRatingSystem.getScoreDescription(this.ratingResult.score))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 15 })
      
      // 分隔线
      Divider()
        .margin({ top: 10, bottom: 10 })
      
      // 简短总结
      Row() {
        Text('📋')
          .fontSize(16)
          .margin({ right: 8 })
        
        Text(this.ratingResult.summary)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .margin({ bottom: 15 })
      .alignItems(VerticalAlign.Top)
      
      // 国标符合性
      Row() {
        Text(this.ratingResult.meetsStandard ? '✅' : '❌')
          .fontSize(16)
          .margin({ right: 8 })
        
        Text(this.ratingResult.meetsStandard ? '符合国家日照标准' : '不符合国家日照标准')
          .fontSize(14)
          .fontColor(this.ratingResult.meetsStandard ? '#4CAF50' : '#F44336')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 15 })
      
      // 建议列表
      if (this.ratingResult.suggestions.length > 0) {
        Column() {
          Text('💡 专业建议')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
            .alignSelf(ItemAlign.Start)
          
          ForEach(this.ratingResult.suggestions, (suggestion: string, index: number) => {
            Row() {
              Text(`${index + 1}.`)
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: 5 })
              
              Text(suggestion)
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .margin({ bottom: 5 })
            .alignItems(VerticalAlign.Top)
          })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#00000015',
      offsetX: 0,
      offsetY: 2
    })
  }
}

/**
 * 简洁版评分显示组件(用于列表)
 */
@Component
export struct SunshineRatingBadge {
  @Prop ratingResult: RatingResult;
  
  build() {
    Row() {
      // 评级标签
      Text(this.ratingResult.rating)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(this.ratingResult.color)
        .borderRadius(4)
        .margin({ right: 8 })
      
      // 星级
      Text(SunshineRatingSystem.getStarsDisplay(this.ratingResult.stars))
        .fontSize(14)
        .margin({ right: 8 })
      
      // 分数
      Text(`${this.ratingResult.score}分`)
        .fontSize(14)
        .fontColor(this.ratingResult.color)
        .fontWeight(FontWeight.Medium)
    }
    .alignItems(VerticalAlign.Center)
  }
}
