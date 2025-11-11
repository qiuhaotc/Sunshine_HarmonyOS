import { SimpleHistoryItem, HistoryManager } from '../utils/HistoryManager';
import { HouseInputModel } from '../model/HouseInputModel';

/**
 * 基础评估器历史记录对话框
 */
@CustomDialog
export struct SimpleHistoryDialog {
  @State historyList: SimpleHistoryItem[] = [];
  @State loading: boolean = true;
  
  onLoad?: (item: SimpleHistoryItem) => void;
  onClose?: () => void;
  controller?: CustomDialogController;

  aboutToAppear() {
    this.loadHistory();
  }

  /**
   * 加载历史记录
   */
  async loadHistory() {
    this.loading = true;
    try {
      const context = getContext(this) as Context;
      this.historyList = await HistoryManager.getSimpleHistory(context);
    } catch (error) {
      console.error('加载历史记录失败:', error);
    } finally {
      this.loading = false;
    }
  }

  /**
   * 删除记录
   */
  async deleteHistory(id: string) {
    const context = getContext(this) as Context;
    await HistoryManager.deleteSimpleHistory(context, id);
    await this.loadHistory();
  }

  /**
   * 清空所有记录
   */
  async clearAll() {
    const context = getContext(this) as Context;
    await HistoryManager.clearSimpleHistory(context);
    await this.loadHistory();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('历史记录')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
        // 清空按钮
        if (this.historyList.length > 0) {
          Button('清空')
            .fontSize(14)
            .backgroundColor('#FF5252')
            .height(32)
            .margin({ right: 8 })
            .onClick(() => {
              AlertDialog.show({
                title: '确认清空',
                message: '确定要清空所有历史记录吗?',
                primaryButton: {
                  value: '取消',
                  action: () => {}
                },
                secondaryButton: {
                  value: '清空',
                  fontColor: '#FF5252',
                  action: () => {
                    this.clearAll();
                  }
                }
              });
            })
        }
        
        Button('✕')
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_secondary'))
          .onClick(() => {
            if (this.onClose) {
              this.onClose();
            }
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 15 })

      Divider()

      // 内容区域
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .margin({ top: 50 })
          
          Text('加载中...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 10 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else if (this.historyList.length === 0) {
        Column() {
          Text('📝')
            .fontSize(48)
            .margin({ bottom: 10 })
          
          Text('暂无历史记录')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.historyList, (item: SimpleHistoryItem) => {
            ListItem() {
              this.buildHistoryItem(item)
            }
          })
        }
        .width('100%')
        .height(400)
        .divider({ strokeWidth: 1, color: $r('app.color.divider_color') })
      }
    }
    .width('90%')
    .constraintSize({ maxWidth: 600, maxHeight: 550 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: 20,
      color: '#00000030',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  buildHistoryItem(item: SimpleHistoryItem) {
    Row() {
      Column() {
        // 名称和时间
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Row({ space: 8 }) {
          Text(item.cityName)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          
          Text('|')
            .fontSize(12)
            .fontColor($r('app.color.divider_color'))
          
          Text(this.formatTimestamp(item.timestamp))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .margin({ top: 4 })
        
        // 关键数据
        Row({ space: 12 }) {
          Text(`冬至: ${item.winterSolsticeSunshine.toFixed(1)}h`)
            .fontSize(12)
            .fontColor(item.winterSolsticeSunshine >= 2 ? '#4CAF50' : '#FF5252')
          
          Text(`大寒: ${item.greatColdSunshine.toFixed(1)}h`)
            .fontSize(12)
            .fontColor(item.greatColdSunshine >= 2 ? '#4CAF50' : '#FF5252')
          
          Text(`${item.score}分`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getScoreColor(item.score))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.getScoreColor(item.score) + '20')
            .borderRadius(3)
        }
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 15, top: 12, bottom: 12 })

      // 操作按钮
      Row({ space: 8 }) {
        Button('加载')
          .fontSize(13)
          .height(32)
          .backgroundColor('#1976D2')
          .onClick(() => {
            if (this.onLoad) {
              this.onLoad(item);
            }
          })
        
        Button('删除')
          .fontSize(13)
          .height(32)
          .backgroundColor(Color.Transparent)
          .fontColor('#FF5252')
          .border({ width: 1, color: '#FF5252' })
          .onClick(() => {
            AlertDialog.show({
              title: '确认删除',
              message: `确定要删除"${item.name}"吗?`,
              primaryButton: {
                value: '取消',
                action: () => {}
              },
              secondaryButton: {
                value: '删除',
                fontColor: '#FF5252',
                action: () => {
                  this.deleteHistory(item.id);
                }
              }
            });
          })
      }
      .padding({ right: 15 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .onClick(() => {
      // 点击整行也可以加载
      if (this.onLoad) {
        this.onLoad(item);
      }
    })
  }

  /**
   * 获取评分颜色
   */
  // 格式化时间戳
  private formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${month}-${day} ${hour}:${minute}`;
  }
  
  private getScoreColor(score: number): string {
    if (score >= 85) return '#4CAF50';
    if (score >= 70) return '#8BC34A';
    if (score >= 55) return '#FFC107';
    if (score >= 40) return '#FF9800';
    return '#F44336';
  }
}
