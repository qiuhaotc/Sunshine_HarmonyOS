import { HouseSunshineModel } from '../model/HouseSunshineModel';

/**
 * 图表数据项
 */
interface ChartDataItem {
  label: string;
  value: number;
  color?: string;
  month?: number;
}

/**
 * 图表内边距
 */
interface ChartPadding {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

/**
 * 简单计算器日照时间可视化图表组件
 */
@Component
export struct SimpleSunshineCharts {
  @Prop result: HouseSunshineModel | null = null;
  @State activeChartType: 'bar' | 'line' = 'bar';
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 0;
  
  private barCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private barCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.barCanvasSettings);
  
  private lineCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private lineCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.lineCanvasSettings);

  build() {
    Column() {
      // 图表类型切换按钮
      Row() {
        Button('柱状图')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.activeChartType === 'bar' ? '#1976D2' : '#E0E0E0')
          .fontColor(this.activeChartType === 'bar' ? Color.White : '#666666')
          .onClick(() => {
            this.activeChartType = 'bar';
            this.drawChart();
          })
          .margin({ right: 8 })
        
        Button('折线图')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.activeChartType === 'line' ? '#1976D2' : '#E0E0E0')
          .fontColor(this.activeChartType === 'line' ? Color.White : '#666666')
          .onClick(() => {
            this.activeChartType = 'line';
            this.drawChart();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 15 })

      // 图表画布
      if (this.activeChartType === 'bar') {
        Canvas(this.barCanvasContext)
          .width('100%')
          .height(250)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onReady(() => {
            this.drawChart();
          })
          .onAreaChange((oldValue: Area, newValue: Area) => {
            this.canvasWidth = newValue.width as number;
            this.canvasHeight = newValue.height as number;
            this.drawChart();
          })
      } else {
        Canvas(this.lineCanvasContext)
          .width('100%')
          .height(250)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onReady(() => {
            this.drawChart();
          })
          .onAreaChange((oldValue: Area, newValue: Area) => {
            this.canvasWidth = newValue.width as number;
            this.canvasHeight = newValue.height as number;
            this.drawChart();
          })
      }
      
      // 图例说明
      Row() {
        Text('提示: ')
          .fontSize(11)
          .fontColor('#999999')
        
        if (this.activeChartType === 'bar') {
          Text('柱状图直观展示各节气日照时长对比')
            .fontSize(11)
            .fontColor('#666666')
        } else {
          Text('折线图展示全年日照时间变化趋势')
            .fontSize(11)
            .fontColor('#666666')
        }
      }
      .width('100%')
      .margin({ top: 10 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
    .margin({ top: 15 })
  }

  /**
   * 绘制图表
   */
  private drawChart() {
    if (!this.result || this.canvasWidth === 0 || this.canvasHeight === 0) {
      return;
    }

    if (this.activeChartType === 'bar') {
      this.drawBarChart();
    } else {
      this.drawLineChart();
    }
  }

  /**
   * 绘制柱状图
   */
  private drawBarChart() {
    const ctx = this.barCanvasContext;
    const width = this.canvasWidth;
    const height = this.canvasHeight;
    
    // 清空画布
    ctx.clearRect(0, 0, width, height);
    
    // 数据(转换为小时)
    const data: ChartDataItem[] = [
      { label: '春分', value: this.result!.springEquinox / 60, color: '#66BB6A' },
      { label: '夏至', value: this.result!.summerSolstice / 60, color: '#FFA726' },
      { label: '秋分', value: this.result!.autumnalEquinox / 60, color: '#EF5350' },
      { label: '冬至', value: this.result!.winterSolstice / 60, color: '#42A5F5' },
      { label: '大寒', value: this.result!.greatCold / 60, color: '#AB47BC' }
    ];
    
    const padding: ChartPadding = { top: 30, right: 20, bottom: 50, left: 50 };
    const chartWidth = width - padding.left - padding.right;
    const chartHeight = height - padding.top - padding.bottom;
    
    // 找到最大值用于缩放
    const maxValue = Math.max(...data.map(d => d.value));
    const yScale = chartHeight / (maxValue * 1.1);
    
    // 绘制Y轴
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding.left, padding.top);
    ctx.lineTo(padding.left, height - padding.bottom);
    ctx.stroke();
    
    // 绘制Y轴刻度和网格线
    const ySteps = 5;
    ctx.font = '10px sans-serif';
    ctx.fillStyle = '#666666';
    ctx.textAlign = 'right';
    for (let i = 0; i <= ySteps; i++) {
      const y = height - padding.bottom - (chartHeight / ySteps) * i;
      const value = (maxValue * 1.1 / ySteps) * i;
      
      // 刻度线
      ctx.strokeStyle = '#CCCCCC';
      ctx.beginPath();
      ctx.moveTo(padding.left - 5, y);
      ctx.lineTo(padding.left, y);
      ctx.stroke();
      
      // 网格线
      if (i > 0) {
        ctx.strokeStyle = '#F0F0F0';
        ctx.setLineDash([3, 3]);
        ctx.beginPath();
        ctx.moveTo(padding.left, y);
        ctx.lineTo(width - padding.right, y);
        ctx.stroke();
        ctx.setLineDash([]);
      }
      
      // 刻度值
      ctx.fillText(value.toFixed(1), padding.left - 10, y + 3);
    }
    
    // 绘制X轴
    ctx.strokeStyle = '#CCCCCC';
    ctx.beginPath();
    ctx.moveTo(padding.left, height - padding.bottom);
    ctx.lineTo(width - padding.right, height - padding.bottom);
    ctx.stroke();
    
    // 绘制柱状图
    const barWidth = chartWidth / data.length * 0.7;
    const barGap = chartWidth / data.length * 0.3;
    
    data.forEach((item, index) => {
      const x = padding.left + (chartWidth / data.length) * index + barGap / 2;
      const barHeight = item.value * yScale;
      const y = height - padding.bottom - barHeight;
      
      // 绘制柱子
      ctx.fillStyle = item.color || '#90CAF9';
      ctx.fillRect(x, y, barWidth, barHeight);
      
      // 绘制数值标签
      ctx.fillStyle = '#333333';
      ctx.font = '11px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(item.value.toFixed(2), x + barWidth / 2, y - 5);
      
      // 绘制X轴标签
      ctx.fillStyle = '#666666';
      ctx.font = '12px sans-serif';
      ctx.fillText(item.label, x + barWidth / 2, height - padding.bottom + 20);
    });
    
    // 绘制标题
    ctx.fillStyle = '#333333';
    ctx.font = 'bold 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('节气日照时间对比(小时)', width / 2, 20);
  }

  /**
   * 绘制折线图
   */
  private drawLineChart() {
    const ctx = this.lineCanvasContext;
    const width = this.canvasWidth;
    const height = this.canvasHeight;
    
    // 清空画布
    ctx.clearRect(0, 0, width, height);
    
    // 数据(按时间顺序,转换为小时)
    const data: ChartDataItem[] = [
      { label: '大寒', value: this.result!.greatCold / 60, month: 1 },
      { label: '春分', value: this.result!.springEquinox / 60, month: 3 },
      { label: '夏至', value: this.result!.summerSolstice / 60, month: 6 },
      { label: '秋分', value: this.result!.autumnalEquinox / 60, month: 9 },
      { label: '冬至', value: this.result!.winterSolstice / 60, month: 12 }
    ];
    
    const padding: ChartPadding = { top: 30, right: 20, bottom: 50, left: 50 };
    const chartWidth = width - padding.left - padding.right;
    const chartHeight = height - padding.top - padding.bottom;
    
    // 找到最大值和最小值
    const maxValue = Math.max(...data.map(d => d.value));
    const minValue = Math.min(...data.map(d => d.value));
    const valueRange = maxValue - minValue;
    const yScale = chartHeight / (valueRange * 1.2);
    const yOffset = minValue * 0.9;
    
    // 绘制Y轴
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding.left, padding.top);
    ctx.lineTo(padding.left, height - padding.bottom);
    ctx.stroke();
    
    // 绘制Y轴刻度和网格线
    const ySteps = 5;
    ctx.font = '10px sans-serif';
    ctx.fillStyle = '#666666';
    ctx.textAlign = 'right';
    for (let i = 0; i <= ySteps; i++) {
      const y = height - padding.bottom - (chartHeight / ySteps) * i;
      const value = yOffset + (valueRange * 1.2 / ySteps) * i;
      
      ctx.strokeStyle = '#F0F0F0';
      ctx.setLineDash([3, 3]);
      ctx.beginPath();
      ctx.moveTo(padding.left, y);
      ctx.lineTo(width - padding.right, y);
      ctx.stroke();
      ctx.setLineDash([]);
      
      ctx.fillText(value.toFixed(1), padding.left - 10, y + 3);
    }
    
    // 绘制X轴
    ctx.strokeStyle = '#CCCCCC';
    ctx.beginPath();
    ctx.moveTo(padding.left, height - padding.bottom);
    ctx.lineTo(width - padding.right, height - padding.bottom);
    ctx.stroke();
    
    // 绘制折线
    ctx.strokeStyle = '#1976D2';
    ctx.lineWidth = 2;
    ctx.beginPath();
    
    data.forEach((item, index) => {
      const x = padding.left + (chartWidth / (data.length - 1)) * index;
      const y = height - padding.bottom - (item.value - yOffset) * yScale;
      
      if (index === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();
    
    // 绘制数据点和标签
    data.forEach((item, index) => {
      const x = padding.left + (chartWidth / (data.length - 1)) * index;
      const y = height - padding.bottom - (item.value - yOffset) * yScale;
      
      // 数据点
      ctx.fillStyle = '#1976D2';
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, 2 * Math.PI);
      ctx.fill();
      
      // 外圈
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 2;
      ctx.stroke();
      
      // 数值标签
      ctx.fillStyle = '#333333';
      ctx.font = '11px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(item.value.toFixed(2), x, y - 10);
      
      // X轴标签
      ctx.fillStyle = '#666666';
      ctx.font = '12px sans-serif';
      ctx.fillText(item.label, x, height - padding.bottom + 20);
    });
    
    // 绘制标题
    ctx.fillStyle = '#333333';
    ctx.font = 'bold 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('全年日照时间趋势', width / 2, 20);
  }
}
