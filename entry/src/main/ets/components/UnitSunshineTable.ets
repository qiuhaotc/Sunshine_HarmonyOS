import { UnitSunshineData } from '../model/UnitSunshineData';
import { SunshineRatingSystem, RatingResult } from '../utils/SunshineRatingSystem';
import { SunshineRatingCard } from './SunshineRatingCard';

/**
 * Select 组件选项接口
 */
interface SelectOption {
  value: string;
}

/**
 * 单元日照表组件
 */
@Component
export struct UnitSunshineTable {
  @Link sunshineData: UnitSunshineData[];
  @State selectedFloor: number = -1; // -1表示显示所有楼层
  @State selectedUnit: number = -1; // -1表示显示所有单元
  @State sortBy: 'floor' | 'sunshine' | 'rating' = 'floor';
  @State sortAscending: boolean = true;
  @State selectedRating: RatingResult | null = null;
  @State showRatingDialog: boolean = false;
  
  // 评分对话框控制器
  private ratingDialogController: CustomDialogController | null = null;

  build() {
    Column() {
      // 标题和筛选
      Row() {
        Text('单元日照表')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Row({ space: 15 }) {
          Row({ space: 5 }) {
            Text('楼层:')
              .fontSize(14)
            
            Select([
              { value: '全部' },
              ...this.getFloorOptions()
            ])
              .selected(this.getFloorSelectedIndex())
              .value(this.selectedFloor === -1 ? '全部' : `${this.selectedFloor}F`)
              .font({ size: 14 })
              .onSelect((index: number) => {
                if (index === 0) {
                  this.selectedFloor = -1;  // 全部楼层
                } else {
                  // 从选项中获取实际楼层号
                  const floors = Array.from(new Set(this.sunshineData.map(item => item.floor))).sort((a, b) => a - b);
                  this.selectedFloor = floors[index - 1];
                }
              })
          }

          Row({ space: 5 }) {
            Text('单元:')
              .fontSize(14)
            
            Select([
              { value: '全部' },
              ...this.getUnitOptions()
            ])
              .selected(this.getUnitSelectedIndex())
              .value(this.selectedUnit === -1 ? '全部' : `${this.selectedUnit + 1}`)
              .font({ size: 14 })
              .onSelect((index: number) => {
                if (index === 0) {
                  this.selectedUnit = -1;  // 全部单元
                } else {
                  // 从选项中获取实际单元索引
                  const units = Array.from(new Set(this.sunshineData.map(item => item.unitIndex))).sort((a, b) => a - b);
                  this.selectedUnit = units[index - 1];
                }
              })
          }
        }
      }
      .width('100%')
      .padding(15)
      .backgroundColor($r('app.color.card_background'))

      // 表格区域
      Column() {
        // 表格头部
        Row() {
          Text('楼层')
            .width('12%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .onClick(() => this.sort('floor'))

          Text('单元')
            .width('12%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)

          Text('冬至')
            .width('15%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .onClick(() => this.sort('sunshine'))

          Text('大寒')
            .width('15%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)

          Text('年均')
            .width('13%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)

          Text('评分')
            .width('18%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .onClick(() => this.sort('rating'))

          Text('状态')
            .width('15%')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(40)
        .backgroundColor($r('app.color.input_background'))
        .border({ width: { bottom: 1 }, color: $r('app.color.divider_color') })

        // 表格内容 - 使用List垂直滚动
        List() {
          ForEach(this.getFilteredAndSortedData(), (item: UnitSunshineData, index: number) => {
            ListItem() {
              this.buildTableRow(item, index)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: $r('app.color.divider_color') })
      }
      .width('100%')
      .layoutWeight(1)

      // 统计信息 - 固定在底部
      this.buildStatistics()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  buildTableRow(item: UnitSunshineData, index: number) {
    Row() {
      Text(`${item.floor}F`)
        .width('12%')
        .fontSize(12)
        .textAlign(TextAlign.Center)

      Text(`${item.unitIndex + 1}`)
        .width('12%')
        .fontSize(12)
        .textAlign(TextAlign.Center)

      Text(`${item.winterSolsticeSunshine.toFixed(1)}h`)
        .width('15%')
        .fontSize(12)
        .textAlign(TextAlign.Center)
        .fontColor(item.winterSolsticeSunshine >= 2 ? Color.Green : Color.Red)

      Text(`${item.greatColdSunshine.toFixed(1)}h`)
        .width('15%')
        .fontSize(12)
        .textAlign(TextAlign.Center)

      Text(`${item.averageDailySunshine.toFixed(1)}h`)
        .width('13%')
        .fontSize(12)
        .textAlign(TextAlign.Center)

      // 评分列 - 可点击查看详情
      Row() {
        Text(this.getRatingBadge(item))
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(this.getRatingColor(item))
          .borderRadius(3)
      }
      .width('18%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showUnitRatingDetail(item);
      })

      Text(item.meetsStandard() ? '✓' : '✗')
        .width('15%')
        .fontSize(14)
        .textAlign(TextAlign.Center)
        .fontColor(item.meetsStandard() ? Color.Green : Color.Red)
    }
    .width('100%')
    .height(45)
    .backgroundColor(index % 2 === 0 ? $r('app.color.card_background') : $r('app.color.input_background'))
  }

  @Builder
  buildStatistics() {
    Row() {
      Column() {
        Text(`${this.sunshineData.length}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.link_color'))
        Text('总单元数')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Column() {
        Text(`${this.getQualifiedCount()}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Green)
        Text('达标单元')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Column() {
        Text(`${this.getQualifiedRate()}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getQualifiedRate() >= 80 ? Color.Green : Color.Orange)
        Text('达标率')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Column() {
        Text(`${this.getAverageSunshine()}h`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('平均日照')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height(80)
    .padding({ left: 10, right: 10 })
    .backgroundColor($r('app.color.card_background'))
    .border({ width: { top: 1 }, color: $r('app.color.divider_color') })
  }

  /**
   * 获取楼层选项
   */
  private getFloorOptions(): SelectOption[] {
    const floors = new Set<number>();
    this.sunshineData.forEach(item => floors.add(item.floor));
    
    return Array.from(floors)
      .sort((a, b) => a - b)
      .map(floor => {
        const option: SelectOption = { value: `${floor}F` };
        return option;
      });
  }

  /**
   * 获取单元选项
   */
  private getUnitOptions(): SelectOption[] {
    const units = new Set<number>();
    this.sunshineData.forEach(item => units.add(item.unitIndex));
    
    return Array.from(units)
      .sort((a, b) => a - b)
      .map(unitIndex => {
        const option: SelectOption = { value: `${unitIndex + 1}` };
        return option;
      });
  }

  /**
   * 获取楼层选中的索引
   */
  private getFloorSelectedIndex(): number {
    if (this.selectedFloor === -1) {
      return 0;  // 全部楼层
    }
    
    // 找到selectedFloor在排序后的楼层数组中的位置
    const floors = Array.from(new Set(this.sunshineData.map(item => item.floor))).sort((a, b) => a - b);
    const index = floors.indexOf(this.selectedFloor);
    return index === -1 ? 0 : index + 1;  // +1 because index 0 is '全部'
  }

  /**
   * 获取单元选中的索引
   */
  private getUnitSelectedIndex(): number {
    if (this.selectedUnit === -1) {
      return 0;  // 全部单元
    }
    
    // 找到selectedUnit在排序后的单元数组中的位置
    const units = Array.from(new Set(this.sunshineData.map(item => item.unitIndex))).sort((a, b) => a - b);
    const index = units.indexOf(this.selectedUnit);
    return index === -1 ? 0 : index + 1;  // +1 because index 0 is '全部'
  }

  /**
   * 获取筛选和排序后的数据
   */
  private getFilteredAndSortedData(): UnitSunshineData[] {
    let data = [...this.sunshineData];

    // 筛选楼层
    if (this.selectedFloor !== -1) {
      data = data.filter(item => item.floor === this.selectedFloor);
    }

    // 筛选单元
    if (this.selectedUnit !== -1) {
      data = data.filter(item => item.unitIndex === this.selectedUnit);
    }

    // 排序
    data.sort((a, b) => {
      let compareValue = 0;
      
      if (this.sortBy === 'floor') {
        compareValue = a.floor - b.floor || a.unitIndex - b.unitIndex;
      } else if (this.sortBy === 'sunshine') {
        compareValue = a.winterSolsticeSunshine - b.winterSolsticeSunshine;
      } else if (this.sortBy === 'rating') {
        // 按评分排序
        const ratingA = this.calculateRating(a);
        const ratingB = this.calculateRating(b);
        compareValue = ratingA.score - ratingB.score;
      }

      return this.sortAscending ? compareValue : -compareValue;
    });

    return data;
  }

  /**
   * 排序
   */
  private sort(by: 'floor' | 'sunshine' | 'rating') {
    if (this.sortBy === by) {
      this.sortAscending = !this.sortAscending;
    } else {
      this.sortBy = by;
      this.sortAscending = true;
    }
  }

  /**
   * 获取达标单元数
   */
  private getQualifiedCount(): number {
    return this.sunshineData.filter(item => item.meetsStandard()).length;
  }

  /**
   * 获取达标率
   */
  private getQualifiedRate(): number {
    if (this.sunshineData.length === 0) return 0;
    return Math.round(this.getQualifiedCount() / this.sunshineData.length * 100);
  }

  /**
   * 获取平均日照时长（冬至）
   */
  private getAverageSunshine(): string {
    if (this.sunshineData.length === 0) return '0.0';
    
    const total = this.sunshineData.reduce((sum, item) => sum + item.winterSolsticeSunshine, 0);
    return (total / this.sunshineData.length).toFixed(1);
  }

  /**
   * 计算单元的评分
   */
  private calculateRating(item: UnitSunshineData): RatingResult {
    return SunshineRatingSystem.evaluateAdvanced(
      item.totalSunshineHours,
      {
        dahan: item.greatColdSunshine,
        dongzhi: item.winterSolsticeSunshine,
        chunfen: item.springEquinoxSunshine,
        xiazhi: item.summerSolsticeSunshine,
        qiufen: item.autumnEquinoxSunshine
      }
    );
  }

  /**
   * 获取评分徽章文本
   */
  private getRatingBadge(item: UnitSunshineData): string {
    const rating = this.calculateRating(item);
    return `${rating.score}分`;
  }

  /**
   * 获取评分颜色
   */
  private getRatingColor(item: UnitSunshineData): string {
    const rating = this.calculateRating(item);
    return rating.color;
  }

  /**
   * 显示单元评分详情
   */
  private showUnitRatingDetail(item: UnitSunshineData) {
    const rating = this.calculateRating(item);
    this.selectedRating = rating;
    
    // 创建并显示对话框
    this.ratingDialogController = new CustomDialogController({
      builder: UnitRatingDialog({
        unitData: item,
        ratingResult: rating,
        onClose: () => {
          this.ratingDialogController?.close();
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    
    this.ratingDialogController.open();
  }
}

/**
 * 单元评分详情对话框
 */
@CustomDialog
struct UnitRatingDialog {
  unitData: UnitSunshineData = new UnitSunshineData();
  ratingResult: RatingResult | null = null;
  onClose?: () => void;
  controller?: CustomDialogController;

  build() {
    Column() {
      // 标题
      Row() {
        Text(`${this.unitData.buildingId}号楼 ${this.unitData.floor}F-${this.unitData.unitIndex + 1}单元`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
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
      .margin({ bottom: 20 })

      // 评分卡片
      if (this.ratingResult) {
        SunshineRatingCard({ ratingResult: this.ratingResult })
      }

      // 详细数据
      Column() {
        Text('详细数据')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20, bottom: 10 })
          .alignSelf(ItemAlign.Start)

        Column() {
          this.buildDataRow('春分日照', `${this.unitData.springEquinoxSunshine.toFixed(2)}小时`)
          this.buildDataRow('夏至日照', `${this.unitData.summerSolsticeSunshine.toFixed(2)}小时`)
          this.buildDataRow('秋分日照', `${this.unitData.autumnEquinoxSunshine.toFixed(2)}小时`)
          this.buildDataRow('冬至日照', `${this.unitData.winterSolsticeSunshine.toFixed(2)}小时`)
          this.buildDataRow('大寒日照', `${this.unitData.greatColdSunshine.toFixed(2)}小时`)
          Divider().margin({ top: 8, bottom: 8 })
          this.buildDataRow('年均日照', `${this.unitData.averageDailySunshine.toFixed(2)}小时/天`, true)
          this.buildDataRow('全年总计', `${this.unitData.totalSunshineHours.toFixed(0)}小时`, true)
        }
        .width('100%')
        .padding(15)
        .backgroundColor($r('app.color.input_background'))
        .borderRadius(8)
      }
      .width('100%')
    }
    .width('90%')
    .constraintSize({ maxWidth: 500 })
    .padding(20)
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
  buildDataRow(label: string, value: string, highlight: boolean = false) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('50%')
      
      Text(value)
        .fontSize(14)
        .fontWeight(highlight ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(highlight ? '#FF6B00' : $r('app.color.text_primary'))
        .width('50%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ bottom: 5 })
  }
}
