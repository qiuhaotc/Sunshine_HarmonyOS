import { UnitSunshineResult } from '../calculator/AdvancedSunshineCalculator';

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
 * 日照时间可视化图表组件
 * 包含折线图、柱状图等多种展示方式
 */
@Component
export struct SunshineCharts {
  @Prop calculationResult: UnitSunshineResult | null = null;
  @State activeChartType: 'bar' | 'line' | 'radar' = 'bar';
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 0;
  
  private barCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private barCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.barCanvasSettings);
  
  private lineCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private lineCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.lineCanvasSettings);
  
  private radarCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private radarCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.radarCanvasSettings);

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
          .margin({ right: 8 })
        
        Button('雷达图')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.activeChartType === 'radar' ? '#1976D2' : '#E0E0E0')
          .fontColor(this.activeChartType === 'radar' ? Color.White : '#666666')
          .onClick(() => {
            this.activeChartType = 'radar';
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
      } else if (this.activeChartType === 'line') {
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
      } else {
        Canvas(this.radarCanvasContext)
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
      this.buildLegend();
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.input_background'))
    .borderRadius(8)
  }

  /**
   * 绘制图表
   */
  private drawChart() {
    if (!this.calculationResult || this.canvasWidth === 0 || this.canvasHeight === 0) {
      return;
    }

    if (this.activeChartType === 'bar') {
      this.drawBarChart();
    } else if (this.activeChartType === 'line') {
      this.drawLineChart();
    } else {
      this.drawRadarChart();
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
    
    // 数据
    const data: ChartDataItem[] = [
      { label: '春分', value: this.calculationResult!.springEquinox, color: '#66BB6A' },
      { label: '夏至', value: this.calculationResult!.summerSolstice, color: '#FFA726' },
      { label: '秋分', value: this.calculationResult!.autumnalEquinox, color: '#EF5350' },
      { label: '冬至', value: this.calculationResult!.winterSolstice, color: '#42A5F5' },
      { label: '大寒', value: this.calculationResult!.greatCold, color: '#AB47BC' },
      { label: '年均', value: this.calculationResult!.annualAverage, color: '#FF6B00' }
    ];
    
    const padding: ChartPadding = { top: 30, right: 20, bottom: 50, left: 50 };
    const chartWidth = width - padding.left - padding.right;
    const chartHeight = height - padding.top - padding.bottom;
    
    // 找到最大值用于缩放
    const maxValue = Math.max(...data.map(d => d.value));
    const yScale = chartHeight / (maxValue * 1.1); // 留10%空间
    
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
      ctx.fillText(item.value.toFixed(1), x + barWidth / 2, y - 5);
      
      // 绘制X轴标签
      ctx.fillStyle = '#666666';
      ctx.font = '12px sans-serif';
      ctx.fillText(item.label, x + barWidth / 2, height - padding.bottom + 20);
    });
    
    // 绘制标题
    ctx.fillStyle = '#333333';
    ctx.font = 'bold 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('日照时间对比(小时)', width / 2, 20);
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
    
    // 数据(按月份或季节排列)
    const data: ChartDataItem[] = [
      { label: '大寒', value: this.calculationResult!.greatCold, month: 1 },
      { label: '春分', value: this.calculationResult!.springEquinox, month: 3 },
      { label: '夏至', value: this.calculationResult!.summerSolstice, month: 6 },
      { label: '秋分', value: this.calculationResult!.autumnalEquinox, month: 9 },
      { label: '冬至', value: this.calculationResult!.winterSolstice, month: 12 }
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
    
    // 绘制Y轴刻度
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
      ctx.fillText(item.value.toFixed(1), x, y - 10);
      
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

  /**
   * 绘制雷达图
   */
  private drawRadarChart() {
    const ctx = this.radarCanvasContext;
    const width = this.canvasWidth;
    const height = this.canvasHeight;
    
    // 清空画布
    ctx.clearRect(0, 0, width, height);
    
    // 数据
    const data: ChartDataItem[] = [
      { label: '春分', value: this.calculationResult!.springEquinox },
      { label: '夏至', value: this.calculationResult!.summerSolstice },
      { label: '秋分', value: this.calculationResult!.autumnalEquinox },
      { label: '冬至', value: this.calculationResult!.winterSolstice },
      { label: '大寒', value: this.calculationResult!.greatCold }
    ];
    
    const centerX = width / 2;
    const centerY = height / 2 + 10;
    const maxRadius = Math.min(width, height) / 2 - 60;
    
    // 找到最大值用于缩放
    const maxValue = Math.max(...data.map(d => d.value), 12); // 至少12小时
    
    // 绘制背景圆圈和网格线
    const levels = 5;
    for (let i = 0; i <= levels; i++) {
      const radius = (maxRadius / levels) * i;
      
      // 圆圈
      ctx.strokeStyle = i === 0 ? '#CCCCCC' : '#F0F0F0';
      ctx.lineWidth = i === 0 ? 2 : 1;
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      ctx.stroke();
      
      // 刻度值
      if (i > 0) {
        ctx.fillStyle = '#999999';
        ctx.font = '10px sans-serif';
        ctx.textAlign = 'center';
        const value = (maxValue / levels) * i;
        ctx.fillText(value.toFixed(1), centerX, centerY - radius - 5);
      }
    }
    
    // 绘制轴线
    const angleStep = (2 * Math.PI) / data.length;
    data.forEach((item, index) => {
      const angle = angleStep * index - Math.PI / 2; // 从顶部开始
      const x = centerX + maxRadius * Math.cos(angle);
      const y = centerY + maxRadius * Math.sin(angle);
      
      ctx.strokeStyle = '#E0E0E0';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.lineTo(x, y);
      ctx.stroke();
    });
    
    // 绘制数据区域
    ctx.fillStyle = 'rgba(25, 118, 210, 0.2)';
    ctx.strokeStyle = '#1976D2';
    ctx.lineWidth = 2;
    ctx.beginPath();
    
    data.forEach((item, index) => {
      const angle = angleStep * index - Math.PI / 2;
      const ratio = item.value / maxValue;
      const radius = maxRadius * ratio;
      const x = centerX + radius * Math.cos(angle);
      const y = centerY + radius * Math.sin(angle);
      
      if (index === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    
    // 绘制数据点和标签
    data.forEach((item, index) => {
      const angle = angleStep * index - Math.PI / 2;
      const ratio = item.value / maxValue;
      const radius = maxRadius * ratio;
      const x = centerX + radius * Math.cos(angle);
      const y = centerY + radius * Math.sin(angle);
      
      // 数据点
      ctx.fillStyle = '#1976D2';
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, 2 * Math.PI);
      ctx.fill();
      
      // 标签位置(在轴线外侧)
      const labelRadius = maxRadius + 35;
      const labelX = centerX + labelRadius * Math.cos(angle);
      const labelY = centerY + labelRadius * Math.sin(angle);
      
      // 绘制标签
      ctx.fillStyle = '#333333';
      ctx.font = '12px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(item.label, labelX, labelY);
      ctx.font = '10px sans-serif';
      ctx.fillStyle = '#666666';
      ctx.fillText(item.value.toFixed(1) + 'h', labelX, labelY + 14);
    });
    
    // 绘制标题
    ctx.fillStyle = '#333333';
    ctx.font = 'bold 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('日照时间雷达图', width / 2, 20);
  }

  /**
   * 构建图例说明
   */
  @Builder
  buildLegend() {
    if (this.activeChartType !== 'radar') {
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
  }
}
