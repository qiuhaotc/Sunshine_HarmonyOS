import { HouseInputModel } from '../model/HouseInputModel';
import { HouseSunshineModel } from '../model/HouseSunshineModel';
import { SimpleSunshineCalculator } from '../calculator/SimpleSunshineCalculator';
import { CityModel } from '../model/CityModel';
import { CityDataService } from '../utils/CityDataService';
import { SunshineRatingSystem, RatingResult } from '../utils/SunshineRatingSystem';
import { SunshineRatingCard } from '../components/SunshineRatingCard';
import { SimpleSunshineCharts } from '../components/SimpleSunshineCharts';
import { HistoryManager, SimpleHistoryItem } from '../utils/HistoryManager';
import { SimpleHistoryDialog } from '../components/SimpleHistoryDialog';
import { SaveHistoryDialog } from '../components/SaveHistoryDialog';
import router from '@ohos.router';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';

/**
 * 简单日照评估器页面
 */
@Entry
@Component
struct SimpleCalculatorPage {
  @State inputModel: HouseInputModel = new HouseInputModel();
  @State result: HouseSunshineModel = new HouseSunshineModel();
  @State calculating: boolean = false;
  @State showResult: boolean = false;
  @State selectedCity: string = '请选择城市';
  @State cities: CityModel[] = [];
  @State ratingResult: RatingResult | null = null;
  
  // 为每个输入字段维护显示字符串
  @State longitudeText: string = '';
  @State latitudeText: string = '';
  @State levelText: string = '';
  @State levelHeightText: string = '';
  @State blockLevelText: string = '';
  @State blockLevelHeightText: string = '';
  @State distanceText: string = '';
  @State timeZoneText: string = '';
  @State yearText: string = '';
  
  // 响应式布局相关
  @State screenWidth: number = 0;
  @State isTablet: boolean = false;
  
  private cityDialogController: CustomDialogController | null = null;
  private historyDialogController: CustomDialogController | null = null;
  private saveHistoryDialogController: CustomDialogController | null = null;
  private calculator: SimpleSunshineCalculator = new SimpleSunshineCalculator();
  private windowSizeChangeCallback: ((size: window.Size) => void) | null = null;

  aboutToAppear() {
    // 初始化城市数据
    this.cities = CityDataService.getAllCities();
    // 初始化显示文本
    this.updateDisplayTexts();
    // 获取窗口宽度并注册监听
    this.updateScreenWidth();
    this.registerWindowSizeListener();
  }
  
  aboutToDisappear() {
    // 取消窗口大小变化监听
    this.unregisterWindowSizeListener();
  }
  
  /**
   * 更新窗口宽度和判断是否为平板
   */
  private updateScreenWidth(): void {
    try {
      // 获取当前窗口
      let windowClass = window.getLastWindow(this.getUIContext().getHostContext());
      windowClass.then((win: window.Window) => {
        let properties = win.getWindowProperties();
        // 将px转换为vp
        this.screenWidth = px2vp(properties.windowRect.width);
        // 宽度大于600vp认为是平板或横屏
        this.isTablet = this.screenWidth > 600;
        console.info(`窗口宽度更新: ${this.screenWidth}vp, 平板模式: ${this.isTablet}`);
      }).catch((err: BusinessError) => {
        console.error('Failed to get window:', JSON.stringify(err));
        this.screenWidth = 360; // 默认手机宽度
        this.isTablet = false;
      });
    } catch (err) {
      console.error('Failed to get window width:', JSON.stringify(err));
      this.screenWidth = 360; // 默认手机宽度
      this.isTablet = false;
    }
  }
  
  /**
   * 注册窗口大小变化监听
   */
  private registerWindowSizeListener(): void {
    try {
      let windowClass = window.getLastWindow(this.getUIContext().getHostContext());
      windowClass.then((win: window.Window) => {
        // 创建窗口大小变化回调
        this.windowSizeChangeCallback = (size: window.Size) => {
          // 将px转换为vp
          const newWidth = px2vp(size.width);
          const newIsTablet = newWidth > 600;
          
          // 只在模式切换时更新,避免频繁触发
          if (this.isTablet !== newIsTablet || Math.abs(this.screenWidth - newWidth) > 10) {
            this.screenWidth = newWidth;
            this.isTablet = newIsTablet;
            console.info(`窗口大小变化: ${this.screenWidth}vp, 平板模式: ${this.isTablet}`);
          }
        };
        
        // 注册监听
        win.on('windowSizeChange', this.windowSizeChangeCallback);
        console.info('窗口大小变化监听已注册');
      }).catch((err: BusinessError) => {
        console.error('Failed to register window size listener:', JSON.stringify(err));
      });
    } catch (err) {
      console.error('Failed to register window size listener:', JSON.stringify(err));
    }
  }
  
  /**
   * 取消窗口大小变化监听
   */
  private unregisterWindowSizeListener(): void {
    try {
      if (this.windowSizeChangeCallback) {
        let windowClass = window.getLastWindow(this.getUIContext().getHostContext());
        windowClass.then((win: window.Window) => {
          win.off('windowSizeChange', this.windowSizeChangeCallback!);
          this.windowSizeChangeCallback = null;
          console.info('窗口大小变化监听已取消');
        }).catch((err: BusinessError) => {
          console.error('Failed to unregister window size listener:', JSON.stringify(err));
        });
      }
    } catch (err) {
      console.error('Failed to unregister window size listener:', JSON.stringify(err));
    }
  }
  
  /**
   * 更新所有显示文本
   */
  private updateDisplayTexts() {
    this.longitudeText = this.inputModel.longitude.toFixed(6);
    this.latitudeText = this.inputModel.latitude.toFixed(6);
    this.levelText = this.inputModel.level.toString();
    this.levelHeightText = this.inputModel.levelHeight.toFixed(2);
    this.blockLevelText = this.inputModel.blockLevel.toString();
    this.blockLevelHeightText = this.inputModel.blockLevelHeight.toFixed(2);
    this.distanceText = this.inputModel.distance.toString();
    this.timeZoneText = this.inputModel.timeZone.toString();
    this.yearText = this.inputModel.year.toString();
  }

  build() {
    Stack() {
      Column() {
        // 标题栏 - 添加返回按钮
        Row() {
          Button() {
            Text('←')
              .fontSize(24)
              .fontColor(Color.White)
          }
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
          .margin({ left: 8 })

          Text('基础日照评估器')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          
          // 历史记录按钮
          Button() {
            Text('📋')
              .fontSize(20)
          }
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .width(40)
          .height(40)
          .onClick(() => {
            this.showHistoryDialog();
          })
          .margin({ right: 8 })
        }
        .width('100%')
        .height(56)
        .backgroundColor('#1976D2')
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column() {
            // 根据设备宽度选择布局方式
            if (this.isTablet) {
              // 平板布局：左右分栏
              this.buildTabletLayout()
            } else {
              // 手机布局：垂直排列
              this.buildPhoneLayout()
            }
          }
          .width('100%')
          .padding(this.isTablet ? 40 : 20)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))

      // 加载遮罩层
      if (this.calculating) {
        this.buildLoadingMask()
      }
    }
    .width('100%')
    .height('100%')
  }
  
  /**
   * 加载遮罩层
   */
  @Builder
  buildLoadingMask() {
    Column() {
      Column() {
        LoadingProgress()
          .width(80)
          .height(80)
          .color($r('app.color.link_color'))
          .margin({ bottom: 20 })
        
        Text('正在计算日照时间...')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 10 })
        
        Text('请稍候,这可能需要几秒钟')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .width(280)
      .padding(30)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(16)
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.4)')
    .justifyContent(FlexAlign.Center)
  }
  
  /**
   * 手机布局：垂直排列
   */
  @Builder
  buildPhoneLayout() {
    Column() {
      // 输入参数区域
      this.buildInputSection()

      // 计算按钮
      Button('计算日照时间')
        .width('90%')
        .height(50)
        .margin({ top: 30 })
        .fontSize(18)
        .enabled(!this.calculating)
        .onClick(() => {
          this.calculateSunshine();
        })

      // 结果显示区域
      if (this.showResult) {
        this.buildResultSection()
      }
    }
    .width('100%')
  }
  
  /**
   * 平板布局：左右分栏
   */
  @Builder
  buildTabletLayout() {
    Row() {
      // 左侧：输入参数
      Column() {
        this.buildInputSection()
        
        // 计算按钮
        Button('计算日照时间')
          .width('80%')
          .height(50)
          .margin({ top: 30 })
          .fontSize(18)
          .enabled(!this.calculating)
          .onClick(() => {
            this.calculateSunshine();
          })
      }
      .width('45%')
      .padding(20)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(12)
      
      Blank().width(40)
      
      // 右侧：结果显示
      Column() {
        if (this.showResult) {
          this.buildResultSection()
        } else {
          // 占位提示
          Column() {
            Image($r('sys.symbol.sun_max'))
              .width(80)
              .height(80)
              .fillColor($r('app.color.text_secondary'))
              .margin({ bottom: 20 })
            
            Text('输入参数后点击计算')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
            
            Text('结果将显示在这里')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 10 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('45%')
      .padding(20)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(12)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildInputSection() {
    Column() {
      Text('参数设置')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      // 城市选择
      Row() {
        Text('选择城市')
          .fontSize(16)
          .width('40%')

        Button(this.selectedCity)
          .width('60%')
          .onClick(() => {
            this.showCityPickerDialog();
          })
      }
      .width('100%')
      .margin({ bottom: 10 })

      // 经纬度 (十进制格式)
      // 经度
      Row() {
        Text('经度')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.longitudeText })
          .width('60%')
          .type(InputType.NUMBER_DECIMAL)
          .onChange((text: string) => {
            this.longitudeText = text;
            const num = parseFloat(text);
            if (!isNaN(num) && num >= -180 && num <= 180) {
              this.inputModel.longitude = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 纬度
      Row() {
        Text('纬度')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.latitudeText })
          .width('60%')
          .type(InputType.NUMBER_DECIMAL)
          .onChange((text: string) => {
            this.latitudeText = text;
            const num = parseFloat(text);
            if (!isNaN(num) && num >= -90 && num <= 90) {
              this.inputModel.latitude = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 所在楼层
      Row() {
        Text('所在楼层')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.levelText })
          .width('60%')
          .type(InputType.Number)
          .onChange((text: string) => {
            this.levelText = text;
            const num = parseInt(text);
            if (!isNaN(num) && num >= 1 && num <= 100) {
              this.inputModel.level = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 层高
      Row() {
        Text('层高(米)')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.levelHeightText })
          .width('60%')
          .type(InputType.NUMBER_DECIMAL)
          .onChange((text: string) => {
            this.levelHeightText = text;
            const num = parseFloat(text);
            if (!isNaN(num) && num >= 2.5 && num <= 5) {
              this.inputModel.levelHeight = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 遮挡楼栋层数
      Row() {
        Text('遮挡楼栋层数')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.blockLevelText })
          .width('60%')
          .type(InputType.Number)
          .onChange((text: string) => {
            this.blockLevelText = text;
            const num = parseInt(text);
            if (!isNaN(num) && num >= 1 && num <= 100) {
              this.inputModel.blockLevel = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 遮挡楼栋层高
      Row() {
        Text('遮挡楼栋层高(米)')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.blockLevelHeightText })
          .width('60%')
          .type(InputType.NUMBER_DECIMAL)
          .onChange((text: string) => {
            this.blockLevelHeightText = text;
            const num = parseFloat(text);
            if (!isNaN(num) && num >= 2.5 && num <= 5) {
              this.inputModel.blockLevelHeight = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 距离遮挡楼栋
      Row() {
        Text('距离遮挡楼栋(米)')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.distanceText })
          .width('60%')
          .type(InputType.Number)
          .onChange((text: string) => {
            this.distanceText = text;
            const num = parseFloat(text);
            if (!isNaN(num) && num >= 10 && num <= 200) {
              this.inputModel.distance = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 时区
      Row() {
        Text('时区')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.timeZoneText })
          .width('60%')
          .type(InputType.Number)
          .onChange((text: string) => {
            this.timeZoneText = text;
            const num = parseInt(text);
            if (!isNaN(num) && num >= -12 && num <= 12) {
              this.inputModel.timeZone = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)

      // 年份
      Row() {
        Text('年份')
          .fontSize(16)
          .width('40%')

        TextInput({ text: this.yearText })
          .width('60%')
          .type(InputType.Number)
          .onChange((text: string) => {
            this.yearText = text;
            const num = parseInt(text);
            if (!isNaN(num) && num >= 2020 && num <= 2030) {
              this.inputModel.year = num;
            }
          })
      }
      .width('100%')
      .margin({ bottom: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
  }

  @Builder
  buildResultSection() {
    Column() {
      Text('计算结果')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 30, bottom: 15 })
        .alignSelf(ItemAlign.Start)

      // 评分卡片
      if (this.ratingResult) {
        SunshineRatingCard({ ratingResult: this.ratingResult })
          .margin({ bottom: 20 })
      }

      Column() {
        this.buildResultRow('全年总日照时间', this.result.formatMinutesToHours(this.result.totalSunshineTime) + ' 小时')
        this.buildResultRow('全年有效日照时间', this.result.formatMinutesToHours(this.result.exactSunshineTime) + ' 小时')
        this.buildResultRow('春分日照时间', this.result.formatMinutesToHours(this.result.springEquinox) + ' 小时')
        this.buildResultRow('夏至日照时间', this.result.formatMinutesToHours(this.result.summerSolstice) + ' 小时')
        this.buildResultRow('秋分日照时间', this.result.formatMinutesToHours(this.result.autumnalEquinox) + ' 小时')
        this.buildResultRow('冬至日照时间', this.result.formatMinutesToHours(this.result.winterSolstice) + ' 小时')
        this.buildResultRow('大寒日照时间', this.result.formatMinutesToHours(this.result.greatCold) + ' 小时')
        this.buildResultRow('日照时间百分比', this.result.getSunshinePercent() + ' %')
      }
      .width('100%')
      .padding(15)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(10)

      // 日照时间可视化图表
      SimpleSunshineCharts({ result: this.result })

      // 验证结果
      Row() {
        Text(this.calculator.getValidationDescription(this.result))
          .fontSize(16)
          .fontColor(this.calculator.validateSunshineResult(this.result) ? Color.Green : Color.Red)
          .padding(15)
      }
      .width('100%')
      .margin({ top: 15 })
      .backgroundColor(this.calculator.validateSunshineResult(this.result) ? 
        $r('app.color.success_background') : $r('app.color.error_background'))
      .borderRadius(10)
      
      // 保存历史记录按钮
      Button('保存到历史记录')
        .width('100%')
        .margin({ top: 20 })
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => {
          this.showSaveHistoryDialog();
        })
    }
    .width('100%')
  }

  @Builder
  buildResultRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .width('50%')

      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('50%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  /**
   * 显示城市选择对话框
   */
  private showCityPickerDialog() {
    this.cityDialogController = new CustomDialogController({
      builder: CityPickerDialog({
        cities: this.cities,
        onSelect: (city: CityModel) => {
          this.selectCity(city);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.5)' // 添加半透明黑色蒙板
    });
    this.cityDialogController.open();
  }

  /**
   * 选择城市
   */
  private selectCity(city: CityModel) {
    // 更新选中的城市名称
    this.selectedCity = city.getDisplayName();
    
    // 更新经纬度到模型
    this.inputModel.longitude = city.getLongitudeDecimal();
    this.inputModel.latitude = city.getLatitudeDecimal();
    
    // 更新显示文本 - 直接赋值会触发 @State 更新
    this.longitudeText = this.inputModel.longitude.toFixed(6);
    this.latitudeText = this.inputModel.latitude.toFixed(6);
    
    console.info(`选择城市: ${city.getDisplayName()}, 经度: ${this.longitudeText}, 纬度: ${this.latitudeText}`);
  }

  /**
   * 计算日照
   */
  private calculateSunshine() {
    // 在计算前,确保从界面文本同步所有值到 inputModel
    this.syncTextToModel();
    
    this.calculating = true;
    this.showResult = false;

    // 使用异步任务避免阻塞UI线程
    // 先等待100ms让遮罩层显示出来
    setTimeout(() => {
      const startTime = Date.now();
      try {
        // 使用1分钟步长进行精确计算
        this.result = this.calculator.calculateHouseSunshine(this.inputModel, 1);
        
        // 计算评分 (将分钟转换为小时)
        this.ratingResult = SunshineRatingSystem.evaluateSimple(
          this.result.exactSunshineTime / 60, // 全年总日照(小时)
          this.result.greatCold / 60, // 大寒(小时)
          this.result.winterSolstice / 60, // 冬至(小时)
          this.result.exactSunshineTime / 60 / 365 // 年平均每日(小时)
        );
        
        this.showResult = true;
        
        const duration = Date.now() - startTime;
        console.info(`计算完成,耗时: ${duration}ms, 步长: 1分钟, ` +
                     `经度: ${this.inputModel.longitude}, 纬度: ${this.inputModel.latitude}`);
      } catch (error) {
        console.error('计算日照时出错:', error);
        // TODO: 显示错误提示
      } finally {
        this.calculating = false;
      }
    }, 100);
  }

  // 显示历史记录对话框
  private showHistoryDialog() {
    if (!this.historyDialogController) {
      this.historyDialogController = new CustomDialogController({
        builder: SimpleHistoryDialog({
          onLoad: (item: SimpleHistoryItem) => {
            this.loadHistoryItem(item);
          },
          onClose: () => {
            this.historyDialogController?.close();
          }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        customStyle: true
      });
    }
    this.historyDialogController.open();
  }

  // 加载历史记录项
  private async loadHistoryItem(item: SimpleHistoryItem) {
    // 关闭历史对话框
    this.historyDialogController?.close();
    
    // 恢复所有输入参数
    this.inputModel.blockLevel = item.blockLevel;
    this.inputModel.blockLevelHeight = item.blockLevelHeight;
    this.inputModel.distance = item.distance;
    this.inputModel.latitude = item.latitude;
    this.inputModel.level = item.level;
    this.inputModel.levelHeight = item.levelHeight;
    this.inputModel.longitude = item.longitude;
    this.inputModel.timeZone = item.timeZone;
    this.inputModel.year = item.year;
    
    // 更新城市信息
    const city = this.cities.find(c => c.city === item.cityName);
    if (city) {
      this.selectCity(city);
    }
    
    // 更新显示文本
    this.updateDisplayTexts();
    
    // 自动计算
    this.calculateSunshine();
  }

  // 保存当前配置为历史记录
  private showSaveHistoryDialog() {
    if (!this.saveHistoryDialogController) {
      this.saveHistoryDialogController = new CustomDialogController({
        builder: SaveHistoryDialog({
          onSave: (name: string) => {
            this.saveHistory(name);
          },
          onClose: () => {
            this.saveHistoryDialogController?.close();
          }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        customStyle: true
      });
    }
    this.saveHistoryDialogController.open();
  }

  // 执行保存历史记录
  private async saveHistory(name: string) {
    // 关闭保存对话框
    this.saveHistoryDialogController?.close();
    
    // 确保有计算结果
    if (!this.showResult) {
      // 提示用户先进行计算
      promptAction.showToast({ message: '请先进行日照计算后再保存' });
      return;
    }
    
    // 获取城市名称
    let cityName = '未知';
    const city = this.cities.find(c => parseFloat(c.lng) === this.inputModel.longitude && parseFloat(c.lat) === this.inputModel.latitude);
    if (city) {
      cityName = city.city;
    }
    
    // 构建历史记录项
    const historyItem: SimpleHistoryItem = {
      id: Date.now().toString(),
      name: name || `记录-${new Date().toLocaleString('zh-CN')}`,
      timestamp: Date.now(),
      cityName: cityName,
      blockLevel: this.inputModel.blockLevel,
      blockLevelHeight: this.inputModel.blockLevelHeight,
      distance: this.inputModel.distance,
      latitude: this.inputModel.latitude,
      level: this.inputModel.level,
      levelHeight: this.inputModel.levelHeight,
      longitude: this.inputModel.longitude,
      timeZone: this.inputModel.timeZone,
      year: this.inputModel.year,
      totalSunshine: this.result.exactSunshineTime / 60, // 转为小时
      winterSolsticeSunshine: this.result.winterSolstice / 60,
      greatColdSunshine: this.result.greatCold / 60,
      averageDailySunshine: this.result.exactSunshineTime / 60 / 365,
      score: this.ratingResult?.score || 0
    };
    
    // 保存到历史记录
    const context = getContext(this) as Context;
    await HistoryManager.saveSimpleHistory(context, historyItem);
    
    // 显示成功提示
    promptAction.showToast({ message: '历史记录已保存' });
  }

  /**
   * 将界面显示的文本同步到 inputModel
   */
  private syncTextToModel() {
    // 同步经纬度
    const longitude = parseFloat(this.longitudeText);
    if (!isNaN(longitude) && longitude >= -180 && longitude <= 180) {
      this.inputModel.longitude = longitude;
    }
    
    const latitude = parseFloat(this.latitudeText);
    if (!isNaN(latitude) && latitude >= -90 && latitude <= 90) {
      this.inputModel.latitude = latitude;
    }
    
    // 同步其他字段
    const level = parseInt(this.levelText);
    if (!isNaN(level)) {
      this.inputModel.level = level;
    }
    
    const levelHeight = parseFloat(this.levelHeightText);
    if (!isNaN(levelHeight)) {
      this.inputModel.levelHeight = levelHeight;
    }
    
    const blockLevel = parseInt(this.blockLevelText);
    if (!isNaN(blockLevel)) {
      this.inputModel.blockLevel = blockLevel;
    }
    
    const blockLevelHeight = parseFloat(this.blockLevelHeightText);
    if (!isNaN(blockLevelHeight)) {
      this.inputModel.blockLevelHeight = blockLevelHeight;
    }
    
    const distance = parseFloat(this.distanceText);
    if (!isNaN(distance)) {
      this.inputModel.distance = distance;
    }
    
    const timeZone = parseInt(this.timeZoneText);
    if (!isNaN(timeZone)) {
      this.inputModel.timeZone = timeZone;
    }
    
    const year = parseInt(this.yearText);
    if (!isNaN(year)) {
      this.inputModel.year = year;
    }
  }
}

// 城市选择器对话框组件
@CustomDialog
struct CityPickerDialog {
  controller?: CustomDialogController;
  cities: CityModel[] = [];
  onSelect: (city: CityModel) => void = () => {};
  @State searchText: string = '';
  @State filteredCities: CityModel[] = [];

  aboutToAppear() {
    this.filteredCities = this.cities;
  }

  /**
   * 搜索城市
   */
  private filterCities(keyword: string) {
    if (!keyword || keyword.trim() === '') {
      this.filteredCities = this.cities;
    } else {
      const lowerKeyword = keyword.toLowerCase();
      this.filteredCities = this.cities.filter((city: CityModel) => {
        const displayName = city.getDisplayName().toLowerCase();
        const cityName = city.city.toLowerCase();
        const provinceName = city.province.toLowerCase();
        return displayName.includes(lowerKeyword) || 
               cityName.includes(lowerKeyword) || 
               provinceName.includes(lowerKeyword);
      });
    }
  }

  build() {
    Column() {
      // 搜索框
      TextInput({ placeholder: '搜索城市...', text: this.searchText })
        .width('100%')
        .height(40)
        .margin({ bottom: 10 })
        .backgroundColor($r('app.color.input_background'))
        .borderRadius(8)
        .padding({ left: 15, right: 15 })
        .onChange((text: string) => {
          this.searchText = text;
          this.filterCities(text);
        })

      // 城市列表
      Scroll() {
        Column() {
          if (this.filteredCities.length === 0) {
            Text('未找到匹配的城市')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 20 })
              .width('100%')
              .textAlign(TextAlign.Center)
          } else {
            ForEach(this.filteredCities, (city: CityModel, index: number) => {
              Row() {
                Text(city.getDisplayName())
                  .fontSize(16)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(15)
              .backgroundColor(index % 2 === 0 ? $r('app.color.input_background') : $r('app.color.card_background'))
              .onClick(() => {
                this.onSelect(city);
                this.controller?.close();
              })
            })
          }
        }
      }
      .layoutWeight(1)

      // 取消按钮
      Button('取消')
        .width('100%')
        .margin({ top: 10 })
        .onClick(() => {
          this.controller?.close();
        })
    }
    .width('90%')
    .height('70%')
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
  }
}
