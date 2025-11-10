import { BuildingModel } from '../model/BuildingModel';
import { AdvancedSunshineCalculator, UnitSunshineResult } from '../calculator/AdvancedSunshineCalculator';
import { UnitSunshineData } from '../model/UnitSunshineData';
// import { UnitSunshineCalculator } from '../calculator/UnitSunshineCalculator';
import { Building3DView } from '../components/Building3DView';
import { UnitSunshineTable } from '../components/UnitSunshineTable';
import { CityModel } from '../model/CityModel';
import { CityDataService } from '../utils/CityDataService';
import preferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';

/**
 * 下拉选项类型
 */
interface SelectOption {
  value: string;
}

/**
 * 建筑数据JSON格式
 */
interface BuildingJSON {
  id: number;
  width: number;
  length: number;
  height: number;
  floorHeight: number;
  units: number;
  rotationDeg: number;
  x: number;
  y: number;
}

/**
 * 建筑数据导出格式
 */
interface BuildingExportData {
  version: string;  // 数据格式版本
  latitude: number;
  longitude: number;
  scaleMetersPerCell: number;
  nextBuildingId: number;
  buildings: BuildingJSON[];
}

/**
 * 建筑物单元点击结果
 */
interface BuildingUnitHitResult {
  building: BuildingModel;
  unit: number;
}

/**
 * 3D坐标点
 */
interface Point3D {
  x: number;
  y: number;
  z: number;
}

/**
 * 2D坐标点
 */
interface Point2D {
  x: number;
  y: number;
}

/**
 * 高级光照计算器页面
 */
@Entry
@Component
struct AdvancedCalculatorPage {
  @State buildings: BuildingModel[] = [];
  @State selectedBuildingId: number | null = null;
  @State viewMode: string = '2d'; // '2d' 或 '3d'
  @State latitude: number = 31.684327;
  @State longitude: number = 118.510117;
  @State scaleMetersPerCell: number = 10; // 每格代表的米数
  @State showResult: boolean = false;
  @State calculating: boolean = false;
  @State calculationResult: UnitSunshineResult | null = null;
  
  // 城市选择
  @State selectedCity: string = '请选择城市';
  @State cities: CityModel[] = [];
  private cityDialogController: CustomDialogController | null = null;
  
  // 单元日照数据(用于3D视图和表格)
  @State unitSunshineData: UnitSunshineData[] = [];
  @State showUnitView: boolean = false;
  @State activeUnitView: 'table' | '3d' = 'table';
  
  // 计算目标
  @State targetBuildingId: number = 1;
  @State targetFloor: number = 1;
  @State targetUnit: number = 1;
  @State targetBuildingOptions: string[] = [];
  @State targetFloorOptions: string[] = [];
  @State targetUnitOptions: string[] = [];
  
  // 计算进度
  @State calculationProgress: string = '';
  @State totalUnitsToCalculate: number = 0;
  @State calculatedUnits: number = 0;

  private calculator: AdvancedSunshineCalculator = new AdvancedSunshineCalculator();

  // Canvas绘图相关
  @State canvasWidth: number = 800;
  @State canvasHeight: number = 600;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  
  // 建筑放置状态
  @State isPlacingBuilding: boolean = false;
  private nextBuildingId: number = 1;
  private alreadySetTheStatus: boolean = false;
  
  // 响应式布局
  @State isSmallScreen: boolean = false;
  @State showControlPanel: boolean = true;
  @StorageLink('isDarkMode') @Watch('onThemeChange') isDarkMode: boolean = false;
  
  // Canvas 颜色 - 从资源读取
  @State canvasBackgroundColor: string = '#FFFFFF';
  @State canvasGridColor: string = '#E0E0E0';
  @State canvasBuildingColor: string = '#90CAF9';
  @State canvasBuildingSelectedColor: string = '#64B5F6';
  @State canvasBuildingBorderColor: string = '#1976D2';
  @State canvasTextColor: string = '#FFFFFF';
  @State canvasAccentColor: string = '#FF6B00';
  
  // 节流控制
  private lastRedrawTime: number = 0;
  private readonly REDRAW_THROTTLE_MS = 16; // 约60fps
  
  // 建筑物编辑参数
  @State pendingWidth: number = 54;  // 米
  @State pendingLength: number = 10;  // 米
  @State pendingHeight: number = 60;  // 米
  @State pendingFloorHeight: number = 3;  // 米
  @State pendingUnits: number = 4;
  @State pendingRotation: number = 0;  // 度
  
  // 拖动状态
  private isDragging: boolean = false;
  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private dragBuildingStartX: number = 0;
  private dragBuildingStartY: number = 0;
  
  // 预览位置
  @State previewX: number = 0;
  @State previewY: number = 0;
  @State showPreview: boolean = false;
  
  // 数据持久化
  private readonly STORAGE_KEY = 'advanced_calculator_data';

  async aboutToAppear() {
    // 初始化城市数据
    this.cities = CityDataService.getAllCities();
    // 加载上次保存的数据
    this.loadFromStorage();
    // 检测屏幕尺寸
    this.checkScreenSize();
    // 加载Canvas颜色
    await this.loadCanvasColors();
  }
  
  /**
   * 加载Canvas颜色资源
   */
  private async loadCanvasColors() {
    try {
      const resourceManager = this.getUIContext().getHostContext()?.resourceManager;
      if (!resourceManager) {
        console.error('ResourceManager is not available');
        return;
      }

      // 使用getColor获取颜色数值,然后转换为十六进制字符串
      const bgColor = await resourceManager.getColor($r('app.color.canvas_background').id);
      const gridColor = await resourceManager.getColor($r('app.color.canvas_grid').id);
      const buildingColor = await resourceManager.getColor($r('app.color.canvas_building').id);
      const buildingSelectedColor = await resourceManager.getColor($r('app.color.canvas_building_selected').id);
      const buildingBorderColor = await resourceManager.getColor($r('app.color.canvas_building_border').id);
      const textColor = await resourceManager.getColor($r('app.color.canvas_text').id);
      const accentColor = await resourceManager.getColor($r('app.color.canvas_accent').id);

      // 转换为Canvas可用的颜色字符串格式
      this.canvasBackgroundColor = this.colorToHex(bgColor);
      this.canvasGridColor = this.colorToHex(gridColor);
      this.canvasBuildingColor = this.colorToHex(buildingColor);
      this.canvasBuildingSelectedColor = this.colorToHex(buildingSelectedColor);
      this.canvasBuildingBorderColor = this.colorToHex(buildingBorderColor);
      this.canvasTextColor = this.colorToHex(textColor);
      this.canvasAccentColor = this.colorToHex(accentColor);

      console.info('Canvas colors loaded:', {
        background: this.canvasBackgroundColor,
        grid: this.canvasGridColor,
        building: this.canvasBuildingColor,
        text: this.canvasTextColor,
        accent: this.canvasAccentColor
      });
    } catch (error) {
      console.error('Failed to load canvas colors:', error);
    }
  }

  /**
   * 将颜色数值转换为十六进制字符串
   */
  private colorToHex(color: number): string {
    // 颜色格式为 ARGB，转换为 #RRGGBB 或 #AARRGGBB
    const hex = (color >>> 0).toString(16).padStart(8, '0');
    return `#${hex.substring(2)}`; // 去掉alpha通道，只保留RGB
  }
  
  /**
   * 主题变化时重新加载颜色并重绘
   */
  private async onThemeChange() {
    await this.loadCanvasColors();
    // 延迟重绘，确保颜色已更新
    setTimeout(() => {
      this.redraw();
    }, 50);
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
      maskColor: 'rgba(0, 0, 0, 0.5)'
    });
    this.cityDialogController.open();
  }

  /**
   * 选择城市
   */
  private selectCity(city: CityModel) {
    // 更新选中的城市名称
    this.selectedCity = city.getDisplayName();
    
    // 更新经纬度
    this.longitude = city.getLongitudeDecimal();
    this.latitude = city.getLatitudeDecimal();
    
    console.info(`选择城市: ${city.getDisplayName()}, 经度: ${this.longitude}, 纬度: ${this.latitude}`);
  }
  
  /**
   * 检测屏幕尺寸
   */
  private checkScreenSize() {
    // 默认为大屏,会在首次 onAreaChange 时更新
    this.isSmallScreen = false;
  }
  
  /**
   * 更新屏幕尺寸判断
   */
  private updateScreenSize(width: number) {

    if(this.alreadySetTheStatus) {
      return;
    }

    // 根据实际宽度判断是否为小屏幕
    const wasSmallScreen = this.isSmallScreen;
    this.isSmallScreen = width < 600;
    
    // 如果屏幕类型改变了,重绘
    if (wasSmallScreen !== this.isSmallScreen) {
      this.alreadySetTheStatus = true;
      setTimeout(() => {
        this.redraw();
      }, 100);
    }
  }
  
  aboutToDisappear() {
    // 保存数据到本地存储
    this.saveToStorage();
  }

  build() {
    Stack() {
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
            this.getUIContext().getRouter().back();
          })
          .margin({ left: 8 })

          Text('高级光照计算器')
            .fontSize(this.isSmallScreen ? 18 : 20)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 48 })
          
          // 小屏幕时显示切换按钮
          if (this.isSmallScreen) {
            Button(this.showControlPanel ? '画布' : '设置')
              .fontSize(14)
              .height(35)
              .backgroundColor(Color.Transparent)
              .fontColor(Color.White)
              .onClick(() => {
                this.showControlPanel = !this.showControlPanel;
              })
              .margin({ right: 8 })
          }
        }
        .width('100%')
        .height(56)
        .backgroundColor('#1976D2')
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)

      if (this.isSmallScreen) {
        // 小屏幕:上下布局
        Column() {
          if (this.showControlPanel) {
            // 控制面板
            Scroll() {
              Column() {
                this.buildBasicSettings()
                this.buildBuildingEditor()
                this.buildBuildingList()
                this.buildCalculationPanel()
                this.buildUnitAnalysisPanel()
              }
              .width('100%')
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.page_background'))
          } else {
            // 绘图区域
            Column() {
              // 工具栏
              Row() {
                Text('绘图区域')
                  .fontSize(14)
                  .layoutWeight(1)

                if (this.isPlacingBuilding) {
                  Button('取消放置')
                    .fontSize(12)
                    .height(30)
                    .backgroundColor('#F44336')
                    .margin({ right: 5 })
                    .onClick(() => {
                      this.isPlacingBuilding = false;
                      this.showPreview = false;
                      this.redraw();
                    })
                  
                  Button('确认放置')
                    .fontSize(12)
                    .height(30)
                    .backgroundColor('#4CAF50')
                    .margin({ right: 5 })
                    .onClick(() => {
                      if (this.showPreview) {
                        this.placeBuilding(
                          this.canvasWidth / 2 + this.previewX * 40,
                          this.canvasHeight / 2 + this.previewY * 40
                        );
                      }
                    })
                }

                // 3D功能已隐藏
                // Button(this.viewMode === '2d' ? '2D' : '3D')
                //   .fontSize(12)
                //   .height(30)
                //   .onClick(() => {
                //     this.viewMode = this.viewMode === '2d' ? '3d' : '2d';
                //     this.redraw();
                //   })
              }
              .width('100%')
              .padding(10)
              .backgroundColor($r('app.color.card_background'))

              // Canvas画布
              Canvas(this.canvasContext)
                .width('100%')
                .layoutWeight(1)
                .backgroundColor($r('app.color.card_background'))
                .onAreaChange((oldArea, newArea) => {
                  // 获取实际画布大小
                  const newWidth = newArea.width as number;
                  const newHeight = newArea.height as number;
                  
                  // 检测尺寸是否真的变化了
                  const sizeChanged = (Math.abs(newWidth - this.canvasWidth) > 1 || Math.abs(newHeight - this.canvasHeight) > 1);
                  
                  this.canvasWidth = newWidth;
                  this.canvasHeight = newHeight;
                  
                  // 首次加载时判断屏幕尺寸
                  if (oldArea.width === 0) {
                    this.updateScreenSize(this.canvasWidth);
                  }
                  
                  // 如果尺寸变化了,重绘
                  if (sizeChanged && oldArea.width > 0) {
                    setTimeout(() => {
                      this.redraw();
                    }, 50);
                  }
                })
                .onReady(() => {
                  this.initCanvas();
                })
                .onTouch((event) => {
                  this.handleCanvasTouch(event);
                })
                .onMouse((event) => {
                  this.handleCanvasMouse(event);
                })
            }
            .width('100%')
            .layoutWeight(1)
          }
        }
        .layoutWeight(1)
      } else {
        // 大屏幕:左右布局
        Row() {
          // 左侧控制面板
          Column() {
            Scroll() {
              Column() {
                this.buildBasicSettings()
                this.buildBuildingEditor()
                this.buildBuildingList()
                this.buildCalculationPanel()
                this.buildUnitAnalysisPanel()
              }
              .width('100%')
            }
            .layoutWeight(1)
          }
          .width('30%')
          .height('100%')
          .backgroundColor($r('app.color.page_background'))

          // 右侧绘图区域
          Column() {
            // 工具栏
            Row() {
              Text('绘图区域 (上北下南)')
                .fontSize(16)
                .layoutWeight(1)

              // 3D功能已隐藏
              // Button(this.viewMode === '2d' ? '2D' : '3D')
              //   .fontSize(14)
              //   .height(30)
              //   .margin({ left: 10 })
              //   .onClick(() => {
              //     this.viewMode = this.viewMode === '2d' ? '3d' : '2d';
              //     this.redraw();
              //   })
            }
            .width('100%')
            .padding(10)
            .backgroundColor($r('app.color.card_background'))

            // Canvas画布
            Canvas(this.canvasContext)
              .width('100%')
              .layoutWeight(1)
              .backgroundColor($r('app.color.card_background'))
              .onAreaChange((oldArea, newArea) => {
                // 获取实际画布大小
                this.canvasWidth = newArea.width as number;
                this.canvasHeight = newArea.height as number;
                // 首次加载时判断屏幕尺寸
                if (oldArea.width === 0) {
                  this.updateScreenSize(this.canvasWidth);
                }
              })
              .onReady(() => {
                this.initCanvas();
              })
              .onTouch((event) => {
                this.handleCanvasTouch(event);
              })
              .onMouse((event) => {
                this.handleCanvasMouse(event);
              })
          }
          .width('70%')
          .height('100%')
        }
        .layoutWeight(1)
      }
      }
      .width('100%')
      .height('100%')

      // 加载遮罩层
      if (this.calculating) {
        this.buildLoadingMask()
      }

      // 单元视图弹窗
      if (this.showUnitView) {
        this.buildUnitViewDialog()
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
          .color($r('sys.color.ohos_id_color_emphasize'))
          .margin({ bottom: 20 })
        
        Text(this.calculationProgress || '正在计算光照时间...')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 10 })
        
        if (this.totalUnitsToCalculate > 0) {
          Text(`已计算 ${this.calculatedUnits}/${this.totalUnitsToCalculate} 个单元`)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_emphasize'))
            .margin({ bottom: 5 })
          
          Progress({ value: this.calculatedUnits, total: this.totalUnitsToCalculate, type: ProgressType.Linear })
            .width(200)
            .height(4)
            .color($r('sys.color.ohos_id_color_emphasize'))
            .margin({ bottom: 10 })
        }
        
        Text('考虑多建筑物遮挡')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 5 })
        
        Text('这可能需要较长时间')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .width(300)
      .padding(30)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(16)
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 单元视图弹窗
   */
  @Builder
  buildUnitViewDialog() {
    Column() {
      Column() {
        // 标题栏
        Row() {
          Text(this.activeUnitView === 'table' ? '单元日照表' : '3D热力图')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          Button('关闭')
            .fontSize(14)
            .height(35)
            .backgroundColor('#F44336')
            .onClick(() => {
              this.showUnitView = false;
            })
        }
        .width('100%')
        .padding(15)
        .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
        .margin({ bottom: 10 })

        // 内容区域
        if (this.activeUnitView === 'table') {
          UnitSunshineTable({ sunshineData: $unitSunshineData })
        } else {
          Building3DView({ 
            buildings: $buildings,
            sunshineData: $unitSunshineData
          })
        }
      }
      .width(this.isSmallScreen ? '95%' : '90%')
      .height(this.isSmallScreen ? '90%' : '85%')
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(16)
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.2)',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.6)')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildBasicSettings() {
    Column() {
      Text('基本设置')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 10 })

      // 城市选择
      Row() {
        Text('选择城市')
          .fontSize(14)
          .width('40%')
        
        Button(this.selectedCity)
          .fontSize(14)
          .width('60%')
          .onClick(() => {
            this.showCityPickerDialog();
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

      this.buildInputItem('经度', this.longitude.toString(), (value: string) => {
        const num = parseFloat(value);
        if (!isNaN(num)) {
          this.longitude = num;
        }
      })

      this.buildInputItem('纬度', this.latitude.toString(), (value: string) => {
        const num = parseFloat(value);
        if (!isNaN(num)) {
          this.latitude = num;
        }
      })

      // 比例尺固定为10米,只读显示
      Row() {
        Text('比例尺(米/格)')
          .fontSize(14)
          .width('40%')
        
        Text('10 (固定)')
          .fontSize(14)
          .width('60%')
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 数据管理按钮
      Row() {
        Button('导出')
          .fontSize(14)
          .width('30%')
          .onClick(() => {
            this.exportData();
          })
        
        Button('导入')
          .fontSize(14)
          .width('30%')
          .onClick(() => {
            this.importData();
          })
        
        Button('清空')
          .fontSize(14)
          .width('30%')
          .backgroundColor('#F44336')
          .onClick(() => {
            this.clearAllBuildings();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  @Builder
  buildBuildingEditor() {
    Column() {
      Text('建筑物编辑')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 10 })

      // 建筑物参数输入
      this.buildInputItem('宽度(米)', this.pendingWidth.toString(), (value: string) => {
        const num = parseFloat(value);
        if (!isNaN(num) && num > 0) {
          this.pendingWidth = num;
          if (this.selectedBuildingId !== null) {
            this.updateSelectedBuilding();
          }
        }
      })

      this.buildInputItem('长度(米)', this.pendingLength.toString(), (value: string) => {
        const num = parseFloat(value);
        if (!isNaN(num) && num > 0) {
          this.pendingLength = num;
          if (this.selectedBuildingId !== null) {
            this.updateSelectedBuilding();
          }
        }
      })

      this.buildInputItem('总高度(米)', this.pendingHeight.toString(), (value: string) => {
        const num = parseFloat(value);
        if (!isNaN(num) && num > 0) {
          this.pendingHeight = num;
          if (this.selectedBuildingId !== null) {
            this.updateSelectedBuilding();
          }
        }
      })

      this.buildInputItem('层高(米)', this.pendingFloorHeight.toString(), (value: string) => {
        const num = parseFloat(value);
        if (!isNaN(num) && num > 0) {
          this.pendingFloorHeight = num;
          if (this.selectedBuildingId !== null) {
            this.updateSelectedBuilding();
          }
        }
      })

      this.buildInputItem('单元数', this.pendingUnits.toString(), (value: string) => {
        const num = parseInt(value);
        if (!isNaN(num) && num > 0) {
          this.pendingUnits = num;
          if (this.selectedBuildingId !== null) {
            this.updateSelectedBuilding();
          }
        }
      })

      this.buildInputItem('旋转角度(°)', this.pendingRotation.toString(), (value: string) => {
        const num = parseFloat(value);
        if (!isNaN(num)) {
          this.pendingRotation = num;
          if (this.selectedBuildingId !== null) {
            this.updateSelectedBuilding();
          }
        }
      })

      Text(this.isPlacingBuilding ? 
        (this.isSmallScreen ? '切换到画布标签页放置建筑' : '现在点击画布放置建筑物') : 
        '调整参数后点击"开始放置"')
        .fontSize(12)
        .fontColor(this.isPlacingBuilding ? '#FF6B00' : $r('app.color.text_secondary'))
        .margin({ top: 10, bottom: 10 })

      Row() {
        Button(this.isPlacingBuilding ? '取消放置' : '开始放置')
          .fontSize(this.isSmallScreen ? 16 : 14)
          .height(this.isSmallScreen ? 44 : 36)
          .layoutWeight(1)
          .backgroundColor(this.isPlacingBuilding ? '#FF5722' : $r('sys.color.ohos_id_color_emphasize'))
          .onClick(() => {
            this.startPlacingBuilding();
          })

        if (this.selectedBuildingId !== null) {
          Button('删除所选')
            .fontSize(this.isSmallScreen ? 16 : 14)
            .height(this.isSmallScreen ? 44 : 36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .backgroundColor('#F44336')
            .onClick(() => {
              this.deleteSelectedBuilding();
            })
        }
      }
      .width('100%')

      Text(this.isSmallScreen ? '点击列表选择; 画布可拖动' : '点击列表或画布选择楼栋; 拖动移动')
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  @Builder
  buildBuildingList() {
    Column() {
      Text('建筑物列表')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 10 })

      if (this.buildings.length === 0) {
        Text('暂无建筑物')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 10 })
      } else {
        ForEach(this.buildings, (building: BuildingModel) => {
          this.buildBuildingListItem(building)
        })
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  @Builder
  buildBuildingListItem(building: BuildingModel) {
    Column() {
      Text(`#${building.id}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 })
      
      Text(`W:${(building.width * this.scaleMetersPerCell).toFixed(1)}m L:${(building.length * this.scaleMetersPerCell).toFixed(1)}m H:${building.height}m`)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
      
      Text(`层:${Math.floor(building.height / building.floorHeight)} 单元:${building.units}`)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(10)
    .backgroundColor(this.selectedBuildingId === building.id ? $r('app.color.success_background') : $r('app.color.input_background'))
    .borderRadius(5)
    .margin({ bottom: 5 })
    .border({
      width: this.selectedBuildingId === building.id ? 2 : 0,
      color: $r('sys.color.ohos_id_color_emphasize')
    })
    .onClick(() => {
      this.selectBuilding(building.id);
    })
  }

  @Builder
  buildCalculationPanel() {
    Column() {
      Text('光照计算')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 10 })

      // 选择目标建筑
      Row() {
        Text('目标建筑')
          .fontSize(14)
          .width('40%')

        if (this.targetBuildingOptions.length > 0) {
          Select(this.targetBuildingOptions.map((id: string): SelectOption => {
            return { value: id } as SelectOption;
          }))
            .width('60%')
            .value(`#${this.targetBuildingId}`)
            .onSelect((index: number) => {
              const value = this.targetBuildingOptions[index];
              const num = parseInt(value.replace('#', ''));
              if (!isNaN(num)) {
                this.targetBuildingId = num;
                this.updateTargetFloorOptions();
              }
            })
        } else {
          Text('无建筑物')
            .fontSize(14)
            .width('60%')
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 选择楼层
      Row() {
        Text('楼层')
          .fontSize(14)
          .width('40%')

        if (this.targetFloorOptions.length > 0) {
          Select(this.targetFloorOptions.map((floor: string): SelectOption => {
            return { value: floor } as SelectOption;
          }))
            .width('60%')
            .value(this.targetFloor.toString())
            .onSelect((index: number) => {
              const value = this.targetFloorOptions[index];
              const num = parseInt(value);
              if (!isNaN(num)) {
                this.targetFloor = num;
              }
            })
        } else {
          Text('-')
            .fontSize(14)
            .width('60%')
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 选择单元
      Row() {
        Text('单元(右起)')
          .fontSize(14)
          .width('40%')

        if (this.targetUnitOptions.length > 0) {
          Select(this.targetUnitOptions.map((unit: string): SelectOption => {
            return { value: unit } as SelectOption;
          }))
            .width('60%')
            .value(this.targetUnit.toString())
            .onSelect((index: number) => {
              const value = this.targetUnitOptions[index];
              const num = parseInt(value);
              if (!isNaN(num)) {
                this.targetUnit = num;
              }
            })
        } else {
          Text('-')
            .fontSize(14)
            .width('60%')
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')
      .margin({ bottom: 15 })

      Button('计算光照')
        .width('100%')
        .enabled(!this.calculating)
        .onClick(() => {
          this.calculateSunshine();
        })

      if (this.showResult && this.calculationResult) {
        this.buildResultDisplay()
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  @Builder
  buildResultDisplay() {
    Column() {
      Text('计算结果')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 15, bottom: 10 })

      if (this.calculationResult) {
        Column() {
          this.buildResultRow('建筑ID', `#${this.calculationResult.buildingId}`)
          this.buildResultRow('楼层', `${this.calculationResult.floorIndex}层`)
          this.buildResultRow('单元', `${this.calculationResult.unitIndex}号(右起)`)
          
          Divider().margin({ top: 10, bottom: 10 })
          
          this.buildResultRow('春分日照', `${this.calculationResult.springEquinox.toFixed(2)}小时`)
          this.buildResultRow('夏至日照', `${this.calculationResult.summerSolstice.toFixed(2)}小时`)
          this.buildResultRow('秋分日照', `${this.calculationResult.autumnalEquinox.toFixed(2)}小时`)
          this.buildResultRow('冬至日照', `${this.calculationResult.winterSolstice.toFixed(2)}小时`)
          this.buildResultRow('大寒日照', `${this.calculationResult.greatCold.toFixed(2)}小时`)
          
          Divider().margin({ top: 10, bottom: 10 })
          
          Row() {
            Text('年均日照')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .width('50%')
            
            Text(`${this.calculationResult.annualAverage.toFixed(2)}小时/天`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B00')
              .width('50%')
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .margin({ bottom: 5 })
        }
        .width('100%')
        .padding(10)
        .backgroundColor($r('app.color.input_background'))
        .borderRadius(8)
      }
    }
    .width('100%')
  }

  @Builder
  buildResultRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .width('50%')

      Text(value)
        .fontSize(14)
        .width('50%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ bottom: 5 })
  }

  /**
   * 建筑单元分析面板
   */
  @Builder
  buildUnitAnalysisPanel() {
    Column() {
      Text('建筑单元分析')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 10 })

      Text('分析指定建筑所有单元的日照情况,以3D热力图或表格形式展示')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 15 })

      // 选择目标建筑
      Row() {
        Text('目标建筑')
          .fontSize(14)
          .width('40%')

        if (this.targetBuildingOptions.length > 0) {
          Select(this.targetBuildingOptions.map((id: string): SelectOption => {
            return { value: id } as SelectOption;
          }))
            .width('60%')
            .value(`#${this.targetBuildingId}`)
            .onSelect((index: number) => {
              const value = this.targetBuildingOptions[index];
              const num = parseInt(value.replace('#', ''));
              if (!isNaN(num)) {
                this.targetBuildingId = num;
              }
            })
        } else {
          Text('无建筑物')
            .fontSize(14)
            .width('60%')
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')
      .margin({ bottom: 15 })

      Button('分析所有单元')
        .width('100%')
        .enabled(!this.calculating && this.buildings.length > 0)
        .onClick(() => {
          this.calculateAllUnits();
        })

      if (this.showUnitView && this.unitSunshineData.length > 0) {
        // 视图切换按钮
        Row() {
          Button('表格视图')
            .fontSize(14)
            .height(35)
            .layoutWeight(1)
            .backgroundColor(this.activeUnitView === 'table' ? '#1976D2' : '#E0E0E0')
            .fontColor(this.activeUnitView === 'table' ? Color.White : '#333333')
            .margin({ right: 5 })
            .onClick(() => {
              this.activeUnitView = 'table';
            })

          Button('3D热力图')
            .fontSize(14)
            .height(35)
            .layoutWeight(1)
            .backgroundColor(this.activeUnitView === '3d' ? '#1976D2' : '#E0E0E0')
            .fontColor(this.activeUnitView === '3d' ? Color.White : '#333333')
            .margin({ left: 5 })
            .onClick(() => {
              this.activeUnitView = '3d';
            })
        }
        .width('100%')
        .margin({ top: 15 })
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  @Builder
  buildInputItem(label: string, value: string, onChange: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .width('40%')

      TextInput({ text: value })
        .fontSize(14)
        .width('60%')
        .onChange(onChange)
    }
    .width('100%')
    .margin({ bottom: 8 })
  }
  
  /**
   * 初始化Canvas
   */
  private async initCanvas() {
    // 确保颜色已加载
    await this.loadCanvasColors();
    // 延迟一下再绘制,确保尺寸已更新
    setTimeout(() => {
      this.redraw();
    }, 100);
  }

  /**
   * 重绘Canvas
   */
  private redraw() {
    if (!this.canvasContext) {
      return;
    }

    // 清空画布
    this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    
    // 填充背景 - 使用资源颜色
    this.canvasContext.fillStyle = this.canvasBackgroundColor;
    this.canvasContext.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    if (this.viewMode === '2d') {
      this.draw2D();
    } else {
      this.draw3D();
    }
  }
  
  /**
   * 节流重绘 - 用于频繁触发的场景(如鼠标移动)
   */
  private redrawThrottled() {
    const now = Date.now();
    if (now - this.lastRedrawTime < this.REDRAW_THROTTLE_MS) {
      // 跳过本次重绘
      return;
    }
    this.lastRedrawTime = now;
    this.redraw();
  }

  /**
   * 2D绘图
   */
  private draw2D() {
    if (!this.canvasContext) {
      return;
    }

    const ctx = this.canvasContext;

    // 绘制网格
    this.drawGrid(ctx);

    // 绘制建筑物
    this.buildings.forEach(building => {
      this.drawBuilding2D(ctx, building, false);
    });
    
    // 绘制预览建筑物
    if (this.showPreview && this.isPlacingBuilding) {
      this.drawPreviewBuilding(ctx);
    }
  }

  /**
   * 3D绘图
   */
  private draw3D() {
    if (!this.canvasContext) {
      return;
    }

    const ctx = this.canvasContext;
    
    // 清空画布
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    
    // 绘制背景渐变 - 根据主题选择颜色
    const gradient = ctx.createLinearGradient(0, 0, 0, this.canvasHeight);
    if (this.isDarkMode) {
      gradient.addColorStop(0, '#1C1C1E');
      gradient.addColorStop(1, '#2C2C2E');
    } else {
      gradient.addColorStop(0, '#E3F2FD');
      gradient.addColorStop(1, '#BBDEFB');
    }
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    const centerX = this.canvasWidth / 2;
    const centerY = this.canvasHeight / 2;

    // 绘制网格
    this.draw3DGrid(ctx, centerX, centerY);

    // 绘制所有建筑物
    for (const building of this.buildings) {
      this.drawBuilding3D(ctx, building, centerX, centerY, false);
    }

    // 绘制预览建筑
    if (this.showPreview && this.isPlacingBuilding) {
      const previewBuilding = new BuildingModel();
      previewBuilding.x = this.previewX;
      previewBuilding.y = this.previewY;
      previewBuilding.width = this.pendingWidth / this.scaleMetersPerCell;
      previewBuilding.length = this.pendingLength / this.scaleMetersPerCell;
      previewBuilding.height = this.pendingHeight;
      previewBuilding.floorHeight = this.pendingFloorHeight;
      previewBuilding.units = this.pendingUnits;
      previewBuilding.rotationDeg = this.pendingRotation;
      this.drawBuilding3D(ctx, previewBuilding, centerX, centerY, true);
    }
  }

  /**
   * 绘制3D网格
   */
  private draw3DGrid(ctx: CanvasRenderingContext2D, centerX: number, centerY: number) {
    // 根据主题选择网格颜色
    ctx.strokeStyle = this.isDarkMode ? 'rgba(144, 202, 249, 0.15)' : 'rgba(144, 202, 249, 0.3)';
    ctx.lineWidth = 1;

    const gridSize = 80; // 放大一倍
    const gridCount = 15;
    const scale = 1.2; // 放大比例

    // 绘制地面网格（等轴测投影）
    for (let i = -gridCount; i <= gridCount; i++) {
      // X方向的线（南北方向）
      ctx.beginPath();
      for (let j = -gridCount; j <= gridCount; j++) {
        const x = centerX + (i * gridSize * scale) + (j * gridSize * scale * 0.5);
        const y = centerY + (j * gridSize * scale * 0.5) - (i * gridSize * scale * 0.25);
        
        if (j === -gridCount) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();

      // Y方向的线（东西方向）
      ctx.beginPath();
      for (let j = -gridCount; j <= gridCount; j++) {
        const x = centerX + (j * gridSize * scale) + (i * gridSize * scale * 0.5);
        const y = centerY + (i * gridSize * scale * 0.5) - (j * gridSize * scale * 0.25);
        
        if (j === -gridCount) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
    }

    // 绘制中心十字
    ctx.strokeStyle = '#FF6B00';
    ctx.lineWidth = 2;
    
    const crossSize = gridSize;
    // 北方向
    ctx.beginPath();
    ctx.moveTo(centerX, centerY);
    ctx.lineTo(centerX, centerY - crossSize);
    ctx.stroke();
    
    // 南方向
    ctx.beginPath();
    ctx.moveTo(centerX, centerY);
    ctx.lineTo(centerX, centerY + crossSize * 0.5);
    ctx.stroke();

    // 标注方位
    ctx.fillStyle = '#FF6B00';
    ctx.font = '12px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('北', centerX, centerY - crossSize - 15);
  }

  /**
   * 绘制3D建筑物
   */
  private drawBuilding3D(ctx: CanvasRenderingContext2D, building: BuildingModel, 
                         centerX: number, centerY: number, isPreview: boolean = false) {
    const gridSize = 80; // 放大一倍
    const scale = 1.2; // 放大比例
    const heightScale = 3.5; // Z轴缩放,使建筑高度更明显

    // 建筑物旋转角度
    const angle = building.rotationDeg * Math.PI / 180;
    const cosA = Math.cos(angle);
    const sinA = Math.sin(angle);

    // 建筑物本地坐标的4个角点（旋转前）
    const halfW = building.width / 2;
    const halfL = building.length / 2;

    const localCorners: Point2D[] = [
      { x: -halfW, y: -halfL },  // 左前
      { x: halfW, y: -halfL },   // 右前
      { x: halfW, y: halfL },    // 右后
      { x: -halfW, y: halfL }    // 左后
    ];

    // 旋转并转换到世界坐标
    const bottom: Point3D[] = [];
    const top: Point3D[] = [];

    for (const corner of localCorners) {
      // 旋转
      const worldX = building.x + corner.x * cosA - corner.y * sinA;
      const worldY = building.y + corner.x * sinA + corner.y * cosA;
      
      bottom.push({ x: worldX, y: worldY, z: 0 });
      top.push({ x: worldX, y: worldY, z: building.height });
    }

    // 等轴测投影到2D
    const project = (p: Point3D): Point2D => {
      // 等轴测投影：x向右，y向右下，z向上
      const screenX = centerX + (p.x * gridSize * scale) + (p.y * gridSize * scale * 0.5);
      const screenY = centerY + (p.y * gridSize * scale * 0.5) - (p.x * gridSize * scale * 0.25) - (p.z * heightScale);
      
      const result: Point2D = {
        x: screenX,
        y: screenY
      };
      return result;
    };

    const bottomProj = bottom.map(project);
    const topProj = top.map(project);

    // 检查是否有热力图数据
    const hasHeatmap = this.unitSunshineData.length > 0 && 
                       this.unitSunshineData.some(d => d.buildingId === building.id);

    // 如果有热力图数据,按单元绘制
    if (hasHeatmap && !isPreview) {
      this.drawBuilding3DWithHeatmap(ctx, building, centerX, centerY, gridSize, scale, heightScale);
    } else {
      // 正常绘制
      // 设置样式
      if (isPreview) {
        ctx.fillStyle = 'rgba(33, 150, 243, 0.3)';
        ctx.strokeStyle = '#2196F3';
        ctx.lineWidth = 2;
        ctx.setLineDash([5, 5]);
      } else {
        // 根据是否被选中和主题设置样式
        if (building.id === this.selectedBuildingId) {
          ctx.fillStyle = 'rgba(255, 152, 0, 0.7)';
          ctx.strokeStyle = '#FF9800';
        } else {
          // 深色模式使用稍亮的蓝色
          if (this.isDarkMode) {
            ctx.fillStyle = 'rgba(66, 165, 245, 0.7)';
          } else {
            ctx.fillStyle = 'rgba(25, 118, 210, 0.7)';
          }
          ctx.strokeStyle = '#1976D2';
        }
        ctx.lineWidth = 2;
        ctx.setLineDash([]);
      }

      // 绘制可见面
      // 前面
      ctx.beginPath();
      ctx.moveTo(bottomProj[2].x, bottomProj[2].y);
      ctx.lineTo(topProj[2].x, topProj[2].y);
      ctx.lineTo(topProj[3].x, topProj[3].y);
      ctx.lineTo(bottomProj[3].x, bottomProj[3].y);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      // 右侧面
      if (isPreview) {
        ctx.fillStyle = 'rgba(33, 150, 243, 0.2)';
      } else if (building.id === this.selectedBuildingId) {
        ctx.fillStyle = 'rgba(255, 152, 0, 0.5)';
      } else {
        ctx.fillStyle = this.isDarkMode ? 'rgba(66, 165, 245, 0.5)' : 'rgba(25, 118, 210, 0.5)';
      }
      ctx.beginPath();
      ctx.moveTo(bottomProj[1].x, bottomProj[1].y);
      ctx.lineTo(topProj[1].x, topProj[1].y);
      ctx.lineTo(topProj[2].x, topProj[2].y);
      ctx.lineTo(bottomProj[2].x, bottomProj[2].y);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      // 顶面
      if (isPreview) {
        ctx.fillStyle = 'rgba(33, 150, 243, 0.4)';
      } else if (building.id === this.selectedBuildingId) {
        ctx.fillStyle = 'rgba(255, 152, 0, 0.8)';
      } else {
        ctx.fillStyle = this.isDarkMode ? 'rgba(66, 165, 245, 0.8)' : 'rgba(25, 118, 210, 0.8)';
      }
      ctx.beginPath();
      ctx.moveTo(topProj[0].x, topProj[0].y);
      ctx.lineTo(topProj[1].x, topProj[1].y);
      ctx.lineTo(topProj[2].x, topProj[2].y);
      ctx.lineTo(topProj[3].x, topProj[3].y);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      // 绘制楼层线
      if (!isPreview && building.height > building.floorHeight) {
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
        ctx.lineWidth = 1;
        ctx.setLineDash([]);

        const floorCount = building.getFloorCount();
        for (let i = 1; i < floorCount; i++) {
          const h = i * building.floorHeight;
          
          // 绘制前面的楼层线
          const p1: Point3D = { x: bottom[2].x, y: bottom[2].y, z: h };
          const p2: Point3D = { x: bottom[3].x, y: bottom[3].y, z: h };
          const fp1 = project(p1);
          const fp2 = project(p2);

          ctx.beginPath();
          ctx.moveTo(fp1.x, fp1.y);
          ctx.lineTo(fp2.x, fp2.y);
          ctx.stroke();
        }
      }

      // 绘制建筑物标签
      if (!isPreview) {
        ctx.setLineDash([]);
        // 根据主题选择文本颜色
        ctx.fillStyle = this.isDarkMode ? '#000000' : '#FFFFFF';
        ctx.strokeStyle = this.isDarkMode ? '#FFFFFF' : '#000000';
        ctx.lineWidth = 3;
        ctx.font = 'bold 14px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';

        // 在建筑物顶部中心显示标签
        const labelPos = project({ x: building.x, y: building.y, z: building.height + 5 });
        ctx.strokeText(`#${building.id}`, labelPos.x, labelPos.y);
        ctx.fillText(`#${building.id}`, labelPos.x, labelPos.y);
      }

      ctx.setLineDash([]);
    }
  }  /**
   * 绘制带热力图的3D建筑物
   */
  private drawBuilding3DWithHeatmap(
    ctx: CanvasRenderingContext2D,
    building: BuildingModel,
    centerX: number,
    centerY: number,
    gridSize: number,
    scale: number,
    heightScale: number
  ) {
    const floorCount = building.getFloorCount();
    const unitCount = building.units;
    const floorHeight = building.floorHeight;
    
    // 投影函数
    const project = (p: Point3D): Point2D => {
      const screenX = centerX + (p.x * gridSize * scale) + (p.y * gridSize * scale * 0.5);
      const screenY = centerY + (p.y * gridSize * scale * 0.5) - (p.x * gridSize * scale * 0.25) - (p.z * heightScale);
      return { x: screenX, y: screenY };
    };
    
    // 建筑物角点
    const angle = building.rotationDeg * Math.PI / 180;
    const cosA = Math.cos(angle);
    const sinA = Math.sin(angle);
    const halfW = building.width / 2;
    const halfL = building.length / 2;
    
    const localCorners: Point2D[] = [
      { x: -halfW, y: -halfL },
      { x: halfW, y: -halfL },
      { x: halfW, y: halfL },
      { x: -halfW, y: halfL }
    ];
    
    const bottom: Point3D[] = [];
    const top: Point3D[] = [];
    for (const corner of localCorners) {
      const worldX = building.x + corner.x * cosA - corner.y * sinA;
      const worldY = building.y + corner.x * sinA + corner.y * cosA;
      bottom.push({ x: worldX, y: worldY, z: 0 });
      top.push({ x: worldX, y: worldY, z: building.height });
    }
    
    const bottomProj = bottom.map(project);
    const topProj = top.map(project);
    
    ctx.lineWidth = 1;
    ctx.setLineDash([]);
    
    // 按楼层和单元绘制
    for (let floor = 1; floor <= floorCount; floor++) {
      const z0 = (floor - 1) * floorHeight;
      const z1 = floor * floorHeight;
      
      // 前面 (面向观察者的面)
      for (let unit = 0; unit < unitCount; unit++) {
        // 查找该单元的日照数据
        const unitData = this.unitSunshineData.find(
          d => d.buildingId === building.id && d.floor === floor && d.unitIndex === unit
        );
        
        if (unitData) {
          // 使用热力图颜色
          const color = unitData.getHeatmapColor();
          ctx.fillStyle = color.replace(')', ', 0.8)').replace('rgb', 'rgba');
          ctx.strokeStyle = color;
        } else {
          // 默认颜色 - 根据主题选择
          if (this.isDarkMode) {
            ctx.fillStyle = 'rgba(66, 165, 245, 0.7)';
          } else {
            ctx.fillStyle = 'rgba(25, 118, 210, 0.7)';
          }
          ctx.strokeStyle = '#1976D2';
        }
        
        // 计算单元在前面的位置
        const unitWidth = building.width / unitCount;
        const unitLeft = -building.width / 2 + unit * unitWidth;
        const unitRight = unitLeft + unitWidth;
        
        // 前面的4个角点(本地坐标)
        const corners: Point2D[] = [
          { x: unitRight, y: building.length / 2 },  // 右下
          { x: unitRight, y: building.length / 2 },  // 右上
          { x: unitLeft, y: building.length / 2 },   // 左上
          { x: unitLeft, y: building.length / 2 }    // 左下
        ];
        
        // 投影4个角点
        const points: Point2D[] = [];
        for (let i = 0; i < corners.length; i++) {
          const worldX = building.x + corners[i].x * cosA - corners[i].y * sinA;
          const worldY = building.y + corners[i].x * sinA + corners[i].y * cosA;
          const z = i < 2 ? z1 : z0;  // 上面两点用z1,下面两点用z0
          points.push(project({ x: worldX, y: worldY, z: z }));
        }
        
        // 绘制单元矩形
        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        ctx.lineTo(points[1].x, points[1].y);
        ctx.lineTo(points[2].x, points[2].y);
        ctx.lineTo(points[3].x, points[3].y);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
      }
    }
    
    // 绘制右侧面(简化处理,不分单元) - 根据主题选择颜色
    ctx.fillStyle = this.isDarkMode ? 'rgba(66, 165, 245, 0.5)' : 'rgba(25, 118, 210, 0.5)';
    ctx.strokeStyle = '#1976D2';
    ctx.beginPath();
    ctx.moveTo(bottomProj[1].x, bottomProj[1].y);
    ctx.lineTo(topProj[1].x, topProj[1].y);
    ctx.lineTo(topProj[2].x, topProj[2].y);
    ctx.lineTo(bottomProj[2].x, bottomProj[2].y);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    
    // 绘制顶面 - 根据主题选择颜色
    ctx.fillStyle = this.isDarkMode ? 'rgba(66, 165, 245, 0.8)' : 'rgba(25, 118, 210, 0.8)';
    ctx.strokeStyle = '#1976D2';
    ctx.beginPath();
    ctx.moveTo(topProj[0].x, topProj[0].y);
    ctx.lineTo(topProj[1].x, topProj[1].y);
    ctx.lineTo(topProj[2].x, topProj[2].y);
    ctx.lineTo(topProj[3].x, topProj[3].y);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    
    // 绘制建筑物标签 - 根据主题选择文本颜色
    ctx.setLineDash([]);
    ctx.fillStyle = this.isDarkMode ? '#000000' : '#FFFFFF';
    ctx.strokeStyle = this.isDarkMode ? '#FFFFFF' : '#000000';
    ctx.lineWidth = 3;
    ctx.font = 'bold 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    const labelPos = project({ x: building.x, y: building.y, z: building.height + 5 });
    ctx.strokeText(`#${building.id}`, labelPos.x, labelPos.y);
    ctx.fillText(`#${building.id}`, labelPos.x, labelPos.y);
  }

  /**
   * 绘制网格
   */
  private drawGrid(ctx: CanvasRenderingContext2D) {
    // 使用资源颜色绘制网格
    ctx.strokeStyle = this.canvasGridColor;
    ctx.lineWidth = 1;

    const gridSize = 40; // 每格40像素
    const rows = Math.floor(this.canvasHeight / gridSize);
    const cols = Math.floor(this.canvasWidth / gridSize);

    // 绘制水平线
    for (let i = 0; i <= rows; i++) {
      ctx.beginPath();
      ctx.moveTo(0, i * gridSize);
      ctx.lineTo(this.canvasWidth, i * gridSize);
      ctx.stroke();
    }

    // 绘制垂直线
    for (let i = 0; i <= cols; i++) {
      ctx.beginPath();
      ctx.moveTo(i * gridSize, 0);
      ctx.lineTo(i * gridSize, this.canvasHeight);
      ctx.stroke();
    }
    
    // 绘制中心十字线(坐标原点)
    ctx.strokeStyle = this.canvasAccentColor;
    ctx.lineWidth = 2;
    const centerX = this.canvasWidth / 2;
    const centerY = this.canvasHeight / 2;
    
    // 水平线
    ctx.beginPath();
    ctx.moveTo(centerX - 20, centerY);
    ctx.lineTo(centerX + 20, centerY);
    ctx.stroke();
    
    // 垂直线
    ctx.beginPath();
    ctx.moveTo(centerX, centerY - 20);
    ctx.lineTo(centerX, centerY + 20);
    ctx.stroke();
    
    // 标注方位
    ctx.fillStyle = this.canvasAccentColor;
    ctx.font = '12px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('北', centerX, centerY - 30);
    ctx.fillText('南', centerX, centerY + 30);
    ctx.fillText('西', centerX - 30, centerY);
    ctx.fillText('东', centerX + 30, centerY);
  }

  /**
   * 绘制2D建筑物
   */
  private drawBuilding2D(ctx: CanvasRenderingContext2D, building: BuildingModel, isPreview: boolean) {
    const gridSize = 40; // 每格40像素,与drawGrid保持一致
    
    // 建筑物中心位置(逻辑单位)
    const centerX = building.x;
    const centerY = building.y;
    
    // 建筑物尺寸(逻辑单位)
    const width = building.width;
    const length = building.length;
    
    // 转换为画布坐标(左上角为原点)
    const canvasCenterX = this.canvasWidth / 2 + centerX * gridSize;
    const canvasCenterY = this.canvasHeight / 2 + centerY * gridSize;
    
    const pixelWidth = width * gridSize;
    const pixelLength = length * gridSize;
    
    // 考虑旋转
    ctx.save();
    ctx.translate(canvasCenterX, canvasCenterY);
    ctx.rotate(building.rotationDeg * Math.PI / 180);
    
    // 绘制建筑物矩形
    if (isPreview) {
      // 预览样式:半透明蓝色
      ctx.fillStyle = 'rgba(33, 150, 243, 0.3)';
      ctx.strokeStyle = '#2196F3';
      ctx.lineWidth = 2;
      ctx.setLineDash([8, 4]);  // 虚线
    } else {
      // 正常样式 - 使用资源颜色
      ctx.fillStyle = this.selectedBuildingId === building.id 
        ? this.canvasBuildingSelectedColor 
        : this.canvasBuildingColor;
      ctx.strokeStyle = this.canvasBuildingBorderColor;
      ctx.lineWidth = 2;
      ctx.setLineDash([]);  // 实线
    }
    
    ctx.fillRect(-pixelWidth / 2, -pixelLength / 2, pixelWidth, pixelLength);
    ctx.strokeRect(-pixelWidth / 2, -pixelLength / 2, pixelWidth, pixelLength);
    
    if (!isPreview) {
      // 绘制单元分隔线
      if (building.units > 1) {
        ctx.strokeStyle = this.canvasBuildingBorderColor;
        ctx.lineWidth = 1;
        ctx.setLineDash([4, 2]);  // 虚线
        const unitWidth = pixelWidth / building.units;
        
        for (let i = 1; i < building.units; i++) {
          const x = -pixelWidth / 2 + i * unitWidth;
          ctx.beginPath();
          ctx.moveTo(x, -pixelLength / 2);
          ctx.lineTo(x, pixelLength / 2);
          ctx.stroke();
        }
        ctx.setLineDash([]);  // 恢复实线
      }
      
      // 绘制单元编号(从右到左)
      ctx.fillStyle = this.canvasTextColor;
      ctx.font = '12px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const unitWidth = pixelWidth / building.units;
      
      for (let i = 0; i < building.units; i++) {
        const unitNumber = building.units - i;  // 从右到左编号
        const x = -pixelWidth / 2 + (i + 0.5) * unitWidth;
        const y = 0;
        
        // 如果是目标单元且是目标建筑,高亮显示
        const isTargetUnit = (building.id === this.targetBuildingId && unitNumber === this.targetUnit);
        if (isTargetUnit) {
          ctx.fillStyle = '#FF9800';
          ctx.font = 'bold 14px sans-serif';
        } else {
          ctx.fillStyle = this.canvasTextColor;
          ctx.font = '12px sans-serif';
        }
        
        ctx.fillText(`${unitNumber}`, x, y);
      }
      
      // 绘制建筑物ID在顶部
      ctx.fillStyle = this.canvasTextColor;
      ctx.font = 'bold 14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(`#${building.id}`, 0, -pixelLength / 2 + 15);
      
      // 绘制朝向指示(一个小箭头指向南)
      ctx.strokeStyle = this.canvasAccentColor;
      ctx.lineWidth = 2;
      ctx.setLineDash([]);  // 实线箭头
      ctx.beginPath();
      ctx.moveTo(0, -pixelLength / 2);
      ctx.lineTo(0, -pixelLength / 2 - 15);
      ctx.lineTo(-5, -pixelLength / 2 - 10);
      ctx.moveTo(0, -pixelLength / 2 - 15);
      ctx.lineTo(5, -pixelLength / 2 - 10);
      ctx.stroke();
    } else {
      // 预览时显示尺寸信息
      ctx.fillStyle = '#2196F3';
      ctx.font = '12px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const widthM = (width * this.scaleMetersPerCell).toFixed(1);
      const lengthM = (length * this.scaleMetersPerCell).toFixed(1);
      ctx.fillText(`${widthM}m × ${lengthM}m`, 0, 0);
    }
    
    ctx.restore();
  }

  /**
   * 绘制预览建筑物
   */
  private drawPreviewBuilding(ctx: CanvasRenderingContext2D) {
    if (!ctx) {
      return;
    }
    
    // 创建临时建筑物用于预览
    const previewBuilding = new BuildingModel();
    previewBuilding.id = 0;  // 预览ID为0
    previewBuilding.x = this.previewX;
    previewBuilding.y = this.previewY;
    previewBuilding.width = this.pendingWidth / this.scaleMetersPerCell;
    previewBuilding.length = this.pendingLength / this.scaleMetersPerCell;
    previewBuilding.height = this.pendingHeight;
    previewBuilding.floorHeight = this.pendingFloorHeight;
    previewBuilding.units = this.pendingUnits;
    previewBuilding.rotationDeg = this.pendingRotation;
    
    this.drawBuilding2D(ctx, previewBuilding, true);
    
    // 绘制十字准星
    const gridSize = 40;
    const canvasCenterX = this.canvasWidth / 2 + this.previewX * gridSize;
    const canvasCenterY = this.canvasHeight / 2 + this.previewY * gridSize;
    
    ctx.save();
    ctx.strokeStyle = '#F44336';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 2]);
    
    // 横线
    ctx.beginPath();
    ctx.moveTo(canvasCenterX - 15, canvasCenterY);
    ctx.lineTo(canvasCenterX + 15, canvasCenterY);
    ctx.stroke();
    
    // 竖线
    ctx.beginPath();
    ctx.moveTo(canvasCenterX, canvasCenterY - 15);
    ctx.lineTo(canvasCenterX, canvasCenterY + 15);
    ctx.stroke();
    
    ctx.restore();
  }

  /**
   * 加载默认建筑物
   */
  private loadDefaultBuildings() {
    // 不加载默认建筑物,让用户手动添加
    this.buildings = [];
    this.nextBuildingId = 1;
  }

  /**
   * 开始放置建筑物
   */
  private startPlacingBuilding() {
    this.isPlacingBuilding = !this.isPlacingBuilding;
    if (!this.isPlacingBuilding) {
      // 取消放置时隐藏预览
      this.showPreview = false;
      this.redraw();
    } else {
      // 开始放置时
      // 初始化预览位置为中心
      this.previewX = 0;
      this.previewY = 0;
      this.showPreview = true;
      
      // 如果是小屏幕则自动切换到画布视图
      if (this.isSmallScreen) {
        this.showControlPanel = false;
        // 延迟一下确保Canvas已经渲染
        setTimeout(() => {
          this.redraw();
        }, 100);
      } else {
        // 大屏幕直接绘制
        this.redraw();
      }
    }
  }
  
  /**
   * 处理Canvas触摸事件
   */
  private handleCanvasTouch(event: TouchEvent) {
    if (!event.touches || event.touches.length === 0) {
      return;
    }

    const touch = event.touches[0];
    const x = touch.x;
    const y = touch.y;

    if (event.type === TouchType.Down) {
      this.handleTouchDown(x, y);
    } else if (event.type === TouchType.Move) {
      this.handleTouchMove(x, y);
    } else if (event.type === TouchType.Up) {
      this.handleTouchUp(x, y);
    }
  }

  /**
   * 处理Canvas鼠标事件
   */
  private handleCanvasMouse(event: MouseEvent) {
    const x = event.x;
    const y = event.y;

    if (event.action === MouseAction.Press) {
      // 鼠标按下
      this.handleTouchDown(x, y);
    } else if (event.action === MouseAction.Move) {
      // 鼠标拖动(按住按钮移动)
      this.handleTouchMove(x, y);
    } else if (event.action === MouseAction.Release) {
      // 鼠标释放
      this.handleTouchUp(x, y);
    } else if (event.action === MouseAction.Hover) {
      // 鼠标悬停(未按下按钮移动)
      // 在放置模式下,需要实时更新预览位置
      if (this.isPlacingBuilding) {
        this.handleTouchMove(x, y);
      }
    }
  }

  /**
   * 处理触摸开始
   */
  private handleTouchDown(x: number, y: number) {
    if (this.isPlacingBuilding) {
      // 放置模式,不处理拖动
      return;
    }

    // 检查是否点击了建筑物
    const building = this.hitTestBuilding(x, y);
    if (building) {
      this.selectBuilding(building.id);
      this.isDragging = true;
      this.dragStartX = x;
      this.dragStartY = y;
      this.dragBuildingStartX = building.x;
      this.dragBuildingStartY = building.y;
    }
  }

  /**
   * 处理触摸移动
   */
  private handleTouchMove(x: number, y: number) {
    if (this.isPlacingBuilding) {
      // 放置模式,更新预览位置
      const gridSize = 40;
      const newPreviewX = (x - this.canvasWidth / 2) / gridSize;
      const newPreviewY = (y - this.canvasHeight / 2) / gridSize;
      
      // 只有位置真正改变时才更新
      if (Math.abs(newPreviewX - this.previewX) > 0.1 || Math.abs(newPreviewY - this.previewY) > 0.1) {
        this.previewX = newPreviewX;
        this.previewY = newPreviewY;
        this.showPreview = true;
        this.redrawThrottled();
      }
      return;
    }
    
    if (this.isDragging && this.selectedBuildingId !== null) {
      const building = this.buildings.find(b => b.id === this.selectedBuildingId);
      if (building) {
        // 3D视图下需要根据投影反算坐标变化
        if (this.viewMode === '3d') {
          const gridSize = 80;
          const scale = 1.2;
          const centerX = this.canvasWidth / 2;
          const centerY = this.canvasHeight / 2;
          
          // 简化处理:将屏幕移动量转换为逻辑坐标移动量
          // 等轴测投影: screenX = centerX + (worldX * gridSize * scale) + (worldY * gridSize * scale * 0.5)
          // 简化反算: 主要考虑X方向移动
          const screenDeltaX = x - this.dragStartX;
          const screenDeltaY = y - this.dragStartY;
          
          // 粗略反算世界坐标变化
          const worldDeltaX = (screenDeltaX - screenDeltaY * 0.5) / (gridSize * scale);
          const worldDeltaY = screenDeltaY / (gridSize * scale * 0.5);
          
          building.x = this.dragBuildingStartX + worldDeltaX;
          building.y = this.dragBuildingStartY + worldDeltaY;
        } else {
          // 2D视图
          const gridSize = 40;
          const deltaX = (x - this.dragStartX) / gridSize;
          const deltaY = (y - this.dragStartY) / gridSize;
          
          building.x = this.dragBuildingStartX + deltaX;
          building.y = this.dragBuildingStartY + deltaY;
        }
        
        this.redrawThrottled();
      }
    }
  }

  /**
   * 处理触摸结束
   */
  private handleTouchUp(x: number, y: number) {
    if (this.isPlacingBuilding) {
      // 放置模式
      this.placeBuilding(x, y);
      return;
    }

    if (this.isDragging) {
      this.isDragging = false;
      // 拖动结束后保存
      this.saveToStorage();
    } else {
      // 单击选择建筑物和单元
      const result = this.hitTestBuildingUnit(x, y);
      if (result) {
        this.selectBuilding(result.building.id);
        // 自动设置点击的单元为目标单元
        this.targetUnit = result.unit;
        console.info(`点击了建筑物 #${result.building.id} 的单元 ${result.unit}`);
        this.redraw();  // 重绘以显示高亮
      }
    }
  }

  /**
   * 碰撞检测 - 检查点击位置是否在建筑物内,并返回单元编号
   */
  private hitTestBuildingUnit(clickX: number, clickY: number): BuildingUnitHitResult | null {
    if (this.viewMode === '3d') {
      return this.hitTestBuildingUnit3D(clickX, clickY);
    }
    
    const gridSize = 40;
    
    // 转换为逻辑坐标
    const logicalX = (clickX - this.canvasWidth / 2) / gridSize;
    const logicalY = (clickY - this.canvasHeight / 2) / gridSize;
    
    // 从后向前遍历(后绘制的在上层)
    for (let i = this.buildings.length - 1; i >= 0; i--) {
      const building = this.buildings[i];
      
      // 考虑旋转的碰撞检测
      const rad = -building.rotationDeg * Math.PI / 180;  // 反向旋转
      const dx = logicalX - building.x;
      const dy = logicalY - building.y;
      
      // 旋转点击位置到建筑物本地坐标系
      const localX = dx * Math.cos(rad) - dy * Math.sin(rad);
      const localY = dx * Math.sin(rad) + dy * Math.cos(rad);
      
      // 检查是否在矩形内
      if (Math.abs(localX) <= building.width / 2 && Math.abs(localY) <= building.length / 2) {
        // 计算点击的单元编号(从右到左)
        const unitWidth = building.width / building.units;
        const relativeX = localX + building.width / 2;  // 转换为从左边开始的坐标
        const unitIndex = Math.floor(relativeX / unitWidth);  // 0-based index from left
        const unitNumber = building.units - unitIndex;  // 从右到左编号,1-based
        
        const result: BuildingUnitHitResult = {
          building: building,
          unit: Math.max(1, Math.min(building.units, unitNumber))
        };
        return result;
      }
    }
    
    return null;
  }

  /**
   * 3D视图的碰撞检测
   */
  private hitTestBuildingUnit3D(clickX: number, clickY: number): BuildingUnitHitResult | null {
    const gridSize = 80; // 与3D绘制保持一致
    const scale = 1.2;
    const centerX = this.canvasWidth / 2;
    const centerY = this.canvasHeight / 2;
    
    // 从后向前遍历
    for (let i = this.buildings.length - 1; i >= 0; i--) {
      const building = this.buildings[i];
      
      // 建筑物旋转
      const angle = building.rotationDeg * Math.PI / 180;
      const cosA = Math.cos(angle);
      const sinA = Math.sin(angle);
      
      // 建筑物4个底部角点
      const halfW = building.width / 2;
      const halfL = building.length / 2;
      
      const localCorners: Point2D[] = [
        { x: -halfW, y: -halfL },
        { x: halfW, y: -halfL },
        { x: halfW, y: halfL },
        { x: -halfW, y: halfL }
      ];
      
      // 投影到屏幕坐标
      const screenCorners: Point2D[] = [];
      for (const corner of localCorners) {
        const worldX = building.x + corner.x * cosA - corner.y * sinA;
        const worldY = building.y + corner.x * sinA + corner.y * cosA;
        
        const screenX = centerX + (worldX * gridSize * scale) + (worldY * gridSize * scale * 0.5);
        const screenY = centerY + (worldY * gridSize * scale * 0.5) - (worldX * gridSize * scale * 0.25);
        
        screenCorners.push({ x: screenX, y: screenY });
      }
      
      // 使用射线法判断点是否在多边形内
      if (this.isPointInPolygon(clickX, clickY, screenCorners)) {
        // 简化:返回单元1(可以后续优化)
        const result: BuildingUnitHitResult = {
          building: building,
          unit: 1
        };
        return result;
      }
    }
    
    return null;
  }

  /**
   * 射线法判断点是否在多边形内
   */
  private isPointInPolygon(x: number, y: number, polygon: Point2D[]): boolean {
    let inside = false;
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const xi = polygon[i].x;
      const yi = polygon[i].y;
      const xj = polygon[j].x;
      const yj = polygon[j].y;
      
      const intersect = ((yi > y) !== (yj > y)) && 
                       (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) {
        inside = !inside;
      }
    }
    return inside;
  }

  /**
   * 碰撞检测 - 检查点击位置是否在建筑物内
   */
  private hitTestBuilding(clickX: number, clickY: number): BuildingModel | null {
    const result = this.hitTestBuildingUnit(clickX, clickY);
    return result ? result.building : null;
  }

  /**
   * 选择建筑物
   */
  private selectBuilding(id: number) {
    this.selectedBuildingId = id;
    const building = this.buildings.find(b => b.id === id);
    
    if (building) {
      // 更新编辑面板的参数
      this.pendingWidth = building.width * this.scaleMetersPerCell;  // 转换为米
      this.pendingLength = building.length * this.scaleMetersPerCell;
      this.pendingHeight = building.height;
      this.pendingFloorHeight = building.floorHeight;
      this.pendingUnits = building.units;
      this.pendingRotation = building.rotationDeg;
      
      // 自动设置为目标建筑
      this.targetBuildingId = id;
      this.updateTargetFloorOptions();
      
      console.info(`选中建筑物 #${id}`);
    }
    
    this.redraw();
  }

  /**
   * 更新选中建筑物的参数
   */
  private updateSelectedBuilding() {
    if (this.selectedBuildingId === null) {
      return;
    }
    
    const building = this.buildings.find(b => b.id === this.selectedBuildingId);
    if (building) {
      // 从米转换为逻辑单位
      building.width = this.pendingWidth / this.scaleMetersPerCell;
      building.length = this.pendingLength / this.scaleMetersPerCell;
      building.height = this.pendingHeight;
      building.floorHeight = this.pendingFloorHeight;
      building.units = this.pendingUnits;
      building.rotationDeg = this.pendingRotation;
      
      this.saveToStorage();
      this.redraw();
    }
  }

  /**
   * 删除选中的建筑物
   */
  private deleteSelectedBuilding() {
    if (this.selectedBuildingId === null) {
      return;
    }
    
    this.buildings = this.buildings.filter(b => b.id !== this.selectedBuildingId);
    console.info(`删除建筑物 #${this.selectedBuildingId}`);
    this.selectedBuildingId = null;
    this.updateTargetBuildingOptions();
    this.saveToStorage();
    this.redraw();
  }

  /**
   * 更新目标建筑下拉选项
   */
  private updateTargetBuildingOptions() {
    this.targetBuildingOptions = this.buildings.map(b => `#${b.id}`);
    
    if (this.buildings.length > 0) {
      // 确保当前选择的建筑存在
      const exists = this.buildings.find(b => b.id === this.targetBuildingId);
      if (!exists) {
        this.targetBuildingId = this.buildings[0].id;
      }
      this.updateTargetFloorOptions();
    } else {
      this.targetFloorOptions = [];
      this.targetUnitOptions = [];
    }
  }

  /**
   * 更新目标楼层和单元下拉选项
   */
  private updateTargetFloorOptions() {
    const building = this.buildings.find((b: BuildingModel) => b.id === this.targetBuildingId);
    if (building) {
      const maxFloor = Math.floor(building.height / building.floorHeight);
      this.targetFloorOptions = Array.from<number, string>({ length: maxFloor }, (_: number, i: number): string => (i + 1).toString());
      
      // 确保当前楼层在范围内
      if (this.targetFloor > maxFloor) {
        this.targetFloor = maxFloor;
      } else if (this.targetFloor < 1) {
        this.targetFloor = 1;
      }
      
      // 更新单元选项
      this.targetUnitOptions = Array.from<number, string>({ length: building.units }, (_: number, i: number): string => (i + 1).toString());
      
      // 确保当前单元在范围内
      if (this.targetUnit > building.units) {
        this.targetUnit = building.units;
      } else if (this.targetUnit < 1) {
        this.targetUnit = 1;
      }
    } else {
      this.targetFloorOptions = [];
      this.targetUnitOptions = [];
    }
  }

  /**
   * 在画布上放置建筑物
   */
  private placeBuilding(clickX: number, clickY: number) {
    const gridSize = 40;
    
    // 将点击坐标转换为逻辑单位(以格子为单位)
    const gridX = (clickX - this.canvasWidth / 2) / gridSize;
    const gridY = (clickY - this.canvasHeight / 2) / gridSize;
    
    // 创建新建筑,使用编辑面板的参数
    const building = new BuildingModel();
    building.id = this.nextBuildingId++;
    building.x = gridX;
    building.y = gridY;
    building.width = this.pendingWidth / this.scaleMetersPerCell;  // 米转逻辑单位
    building.length = this.pendingLength / this.scaleMetersPerCell;
    building.height = this.pendingHeight;
    building.floorHeight = this.pendingFloorHeight;
    building.units = this.pendingUnits;
    building.rotationDeg = this.pendingRotation;
    
    this.buildings.push(building);
    
    // 更新目标建筑下拉选项
    this.updateTargetBuildingOptions();
    
    this.selectedBuildingId = building.id;  // 自动选中新建筑物
    this.isPlacingBuilding = false; // 放置后退出放置模式
    this.showPreview = false;  // 隐藏预览
    
    // 小屏幕模式下自动切换回设置面板
    if (this.isSmallScreen) {
      this.showControlPanel = true;
    }
    
    console.info(`已放置建筑物 #${building.id}:
      点击位置: (${clickX.toFixed(1)}, ${clickY.toFixed(1)})
      逻辑位置: (${gridX.toFixed(2)}, ${gridY.toFixed(2)})
      尺寸(米): ${this.pendingWidth} x ${this.pendingLength} x ${this.pendingHeight}
      当前建筑物总数: ${this.buildings.length}`);
    
    // 保存到本地存储
    this.saveToStorage();
    
    // 重绘画布
    this.redraw();
  }

  /**
   * 移除建筑物
   */
  private removeBuilding(id: number) {
    this.buildings = this.buildings.filter(b => b.id !== id);
    if (this.selectedBuildingId === id) {
      this.selectedBuildingId = null;
    }
    this.redraw();
  }

  /**
   * 计算光照
   */
  private calculateSunshine() {
    // 验证输入
    if (this.buildings.length === 0) {
      console.error('没有建筑物');
      return;
    }

    // 查找目标建筑
    const targetBuilding = this.buildings.find(b => b.id === this.targetBuildingId);
    if (!targetBuilding) {
      console.error('未找到目标建筑');
      return;
    }

    // 验证楼层和单元
    const maxFloor = targetBuilding.getFloorCount();
    if (this.targetFloor < 1 || this.targetFloor > maxFloor) {
      console.error(`楼层必须在1-${maxFloor}之间`);
      return;
    }

    if (this.targetUnit < 1 || this.targetUnit > targetBuilding.units) {
      console.error(`单元必须在1-${targetBuilding.units}之间`);
      return;
    }

    this.calculating = true;
    this.showResult = false;
    this.calculationResult = null;

    // 使用异步任务避免阻塞UI
    setTimeout(() => {
      const startTime = Date.now();
      try {
        // 调用高级计算器
        this.calculationResult = this.calculator.calculateUnitSunshine(
          this.buildings,
          targetBuilding,
          this.targetFloor,
          this.targetUnit,
          this.latitude,
          this.longitude,
          this.scaleMetersPerCell,
          5 // 5分钟步长
        );
        
        this.showResult = true;
        
        const duration = Date.now() - startTime;
        console.info(`高级计算完成,耗时: ${duration}ms`);
        console.info(`结果: 春分=${this.calculationResult.springEquinox.toFixed(2)}h, ` +
                     `夏至=${this.calculationResult.summerSolstice.toFixed(2)}h, ` +
                     `秋分=${this.calculationResult.autumnalEquinox.toFixed(2)}h, ` +
                     `冬至=${this.calculationResult.winterSolstice.toFixed(2)}h, ` +
                     `年均=${this.calculationResult.annualAverage.toFixed(2)}h/天`);
      } catch (error) {
        console.error('计算光照时出错:', JSON.stringify(error));
      } finally {
        this.calculating = false;
      }
    }, 100);
  }

  /**
   * 计算指定建筑所有单元的日照
   */
  private calculateAllUnits() {
    // 验证输入
    if (this.buildings.length === 0) {
      console.error('没有建筑物');
      return;
    }

    // 查找目标建筑
    const targetBuilding = this.buildings.find(b => b.id === this.targetBuildingId);
    if (!targetBuilding) {
      console.error('未找到目标建筑');
      return;
    }

    this.calculating = true;
    this.showUnitView = false;
    this.unitSunshineData = [];
    this.calculatedUnits = 0;
    
    // 计算总单元数
    const totalFloors = Math.floor(targetBuilding.height / targetBuilding.floorHeight);
    this.totalUnitsToCalculate = totalFloors * targetBuilding.units;
    this.calculationProgress = '准备计算...';

    // 使用分块异步计算避免阻塞UI
    const startTime = Date.now();
    
    // 分块大小:每次处理4个单元(降低批次大小以获得更平滑的进度)
    const chunkSize = 4;
    let currentFloor = 1;
    let currentUnit = 1;  // unitIndex从1开始
    const resultData: UnitSunshineData[] = [];
    
    // 分块计算函数
    const processChunk = () => {
      try {
        let processed = 0;
        
        // 处理一个块
        while (processed < chunkSize && currentFloor <= totalFloors) {
          // 使用AdvancedSunshineCalculator计算单元日照(与单一单元计算保持一致)
          const calcResult = this.calculator.calculateUnitSunshine(
            this.buildings,
            targetBuilding,
            currentFloor,
            currentUnit,
            this.latitude,
            this.longitude,
            this.scaleMetersPerCell,
            15  // 使用15分钟步长以提高速度
          );
          
          // 转换为UnitSunshineData格式
          const data = new UnitSunshineData();
          data.buildingId = targetBuilding.id;
          data.floor = currentFloor;
          data.unitIndex = currentUnit - 1;  // 表格显示用0-based索引
          
          // 计算单元中心点坐标
          const unitWidth = targetBuilding.width / targetBuilding.units;
          data.x = targetBuilding.x + (currentUnit - 1) * unitWidth + unitWidth / 2;
          data.y = targetBuilding.y + targetBuilding.length / 2;
          data.z = (currentFloor - 0.5) * targetBuilding.floorHeight;
          
          // 设置日照数据（与计算光照输出保持一致）
          data.springEquinoxSunshine = calcResult.springEquinox;
          data.summerSolsticeSunshine = calcResult.summerSolstice;
          data.autumnEquinoxSunshine = calcResult.autumnalEquinox;
          data.winterSolsticeSunshine = calcResult.winterSolstice;
          data.greatColdSunshine = calcResult.greatCold;
          data.totalSunshineHours = calcResult.annualAverage * 365;  // 年均日照*365天
          
          resultData.push(data);
          
          this.calculatedUnits++;
          processed++;
          
          // 移动到下一个单元
          currentUnit++;
          if (currentUnit > targetBuilding.units) {
            currentUnit = 1;
            currentFloor++;
          }
        }
        
        // 更新进度
        this.calculationProgress = `正在计算 ${currentFloor}/${totalFloors} 楼...`;
        
        // 如果还有未处理的单元,继续下一块
        if (currentFloor <= totalFloors) {
          setTimeout(processChunk, 50); // 50ms延迟,给UI刷新时间
        } else {
          // 计算完成
          this.unitSunshineData = resultData;
          this.showUnitView = true;
          this.activeUnitView = 'table';
          
          const duration = Date.now() - startTime;
          console.info(`单元分析完成,耗时: ${duration}ms, 计算了 ${resultData.length} 个单元`);
          
          // 统计信息
          const qualifiedCount = resultData.filter(d => d.meetsStandard()).length;
          const qualifiedRate = (qualifiedCount / resultData.length * 100).toFixed(1);
          console.info(`达标率: ${qualifiedRate}% (${qualifiedCount}/${resultData.length})`);
          
          this.calculating = false;
          this.calculationProgress = '';
          this.totalUnitsToCalculate = 0;
          this.calculatedUnits = 0;
        }
      } catch (error) {
        console.error('计算单元日照时出错:', JSON.stringify(error));
        this.calculating = false;
        this.calculationProgress = '';
        this.totalUnitsToCalculate = 0;
        this.calculatedUnits = 0;
      }
    };
    
    // 启动第一块计算
    setTimeout(processChunk, 100);
  }

  /**
   * 导出数据为JSON格式
   */
  private exportToJSON(): BuildingExportData {
    const exportData: BuildingExportData = {
      version: '1.0',
      latitude: this.latitude,
      longitude: this.longitude,
      scaleMetersPerCell: this.scaleMetersPerCell,
      nextBuildingId: this.nextBuildingId,
      buildings: this.buildings.map((b: BuildingModel): BuildingJSON => {
        const buildingJSON: BuildingJSON = {
          id: b.id,
          width: b.width,
          length: b.length,
          height: b.height,
          floorHeight: b.floorHeight,
          units: b.units,
          rotationDeg: b.rotationDeg,
          x: b.x,
          y: b.y
        };
        return buildingJSON;
      })
    };
    return exportData;
  }

  /**
   * 从JSON数据导入
   */
  private importFromJSON(data: BuildingExportData) {
    try {
      this.latitude = data.latitude;
      this.longitude = data.longitude;
      // 比例尺固定为10米,不从导入数据中读取
      // this.scaleMetersPerCell = data.scaleMetersPerCell;
      this.nextBuildingId = data.nextBuildingId;
      
      this.buildings = data.buildings.map(b => {
        const building = new BuildingModel();
        building.id = b.id;
        building.width = b.width;
        building.length = b.length;
        building.height = b.height;
        building.floorHeight = b.floorHeight;
        building.units = b.units;
        building.rotationDeg = b.rotationDeg;
        building.x = b.x;
        building.y = b.y;
        return building;
      });
      
      this.selectedBuildingId = null;
      this.updateTargetBuildingOptions();
      this.redraw();
      
      console.info(`导入成功: ${this.buildings.length} 个建筑物`);
    } catch (error) {
      console.error('导入数据失败:', JSON.stringify(error));
    }
  }

  /**
   * 保存数据到本地存储
   */
  private async saveToStorage() {
    try {
      const context = getContext(this);
      const dataPreferences = await preferences.getPreferences(context, 'AdvancedCalculatorData');
      const jsonData = JSON.stringify(this.exportToJSON());
      await dataPreferences.put(this.STORAGE_KEY, jsonData);
      await dataPreferences.flush();
      console.info('数据已保存到本地存储');
    } catch (error) {
      console.error('保存到本地存储失败:', JSON.stringify(error));
    }
  }

  /**
   * 从本地存储加载数据
   */
  private async loadFromStorage() {
    try {
      const context = getContext(this);
      const dataPreferences = await preferences.getPreferences(context, 'AdvancedCalculatorData');
      const jsonData = await dataPreferences.get(this.STORAGE_KEY, '') as string;
      
      if (jsonData) {
        const data = JSON.parse(jsonData) as BuildingExportData;
        this.importFromJSON(data);
        console.info('从本地存储加载数据成功');
      } else {
        // 没有保存的数据,初始化默认值
        this.loadDefaultBuildings();
        this.updateTargetBuildingOptions();
      }
    } catch (error) {
      console.error('从本地存储加载失败:', JSON.stringify(error));
      // 加载失败时使用默认值
      this.loadDefaultBuildings();
      this.updateTargetBuildingOptions();
    }
  }

  /**
   * 导出数据到文件
   */
  private async exportData() {
    try {
      const jsonData = JSON.stringify(this.exportToJSON(), null, 2);
      const fileName = `sunshine_buildings_${new Date().getTime()}.json`;
      
      // 使用文件选择器保存文件
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = [fileName];
      documentSaveOptions.fileSuffixChoices = ['.json'];
      
      const documentPicker = new picker.DocumentViewPicker();
      const uris = await documentPicker.save(documentSaveOptions);
      
      if (uris && uris.length > 0) {
        const file = fs.openSync(uris[0], fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, jsonData);
        fs.closeSync(file);
        
        console.info(`数据已导出到: ${uris[0]}`);
        
        // 提示用户导出成功
        AlertDialog.show({
          title: '导出成功',
          message: `建筑数据已成功导出\n共 ${this.buildings.length} 个建筑物`,
          confirm: {
            value: '确定',
            action: () => {}
          }
        });
      }
    } catch (error) {
      console.error('导出数据失败:', JSON.stringify(error));
      AlertDialog.show({
        title: '导出失败',
        message: '导出建筑数据时发生错误',
        confirm: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }

  /**
   * 从文件导入数据
   */
  private async importData() {
    try {
      // 使用文件选择器选择文件
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      documentSelectOptions.fileSuffixFilters = ['.json'];
      
      const documentPicker = new picker.DocumentViewPicker();
      const uris = await documentPicker.select(documentSelectOptions);
      
      if (uris && uris.length > 0) {
        const file = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
        const buffer = new ArrayBuffer(10 * 1024 * 1024); // 10MB buffer
        const readLen = fs.readSync(file.fd, buffer);
        fs.closeSync(file);
        
        const jsonData = String.fromCharCode(...new Uint8Array(buffer.slice(0, readLen)));
        const data = JSON.parse(jsonData) as BuildingExportData;
        
        // 确认导入
        AlertDialog.show({
          title: '确认导入',
          message: `将导入 ${data.buildings.length} 个建筑物\n当前数据将被覆盖`,
          primaryButton: {
            value: '取消',
            action: () => {}
          },
          secondaryButton: {
            value: '确定',
            action: () => {
              this.importFromJSON(data);
              AlertDialog.show({
                title: '导入成功',
                message: `已成功导入 ${data.buildings.length} 个建筑物`,
                confirm: {
                  value: '确定',
                  action: () => {}
                }
              });
            }
          }
        });
      }
    } catch (error) {
      console.error('导入数据失败:', JSON.stringify(error));
      AlertDialog.show({
        title: '导入失败',
        message: '导入建筑数据时发生错误\n请确保文件格式正确',
        confirm: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }

  /**
   * 清空所有建筑物
   */
  private clearAllBuildings() {
    AlertDialog.show({
      title: '确认清空',
      message: `将清空所有建筑物 (共 ${this.buildings.length} 个)\n此操作不可恢复`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确定',
        action: () => {
          this.buildings = [];
          this.selectedBuildingId = null;
          this.nextBuildingId = 1;
          this.updateTargetBuildingOptions();
          this.redraw();
          this.saveToStorage();
          console.info('已清空所有建筑物');
        }
      }
    });
  }
}

/**
 * 城市选择器对话框组件
 */
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
