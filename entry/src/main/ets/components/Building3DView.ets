import { BuildingModel } from '../model/BuildingModel';
import { UnitSunshineData, View3DConfig } from '../model/UnitSunshineData';

/**
 * 3D坐标点
 */
interface Point3D {
  x: number;
  y: number;
  z: number;
}

/**
 * 2D投影坐标点
 */
interface Point2D {
  x: number;
  y: number;
}

/**
 * 3D建筑视图组件
 */
@Component
export struct Building3DView {
  @Link buildings: BuildingModel[];
  @Link sunshineData: UnitSunshineData[];
  @State config: View3DConfig = new View3DConfig();
  @State rotationX: number = 45;
  @State rotationY: number = 45;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);

  build() {
    Column() {
      // 控制面板
      Row() {
        Text('3D视图控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Row({ space: 10 }) {
          Checkbox({ name: 'heatmap' })
            .select(this.config.showHeatmap)
            .onChange((value: boolean) => {
              this.config.showHeatmap = value;
              this.drawScene();
            })
          Text('热力图')
            .fontSize(14)

          Checkbox({ name: 'grid' })
            .select(this.config.showGrid)
            .onChange((value: boolean) => {
              this.config.showGrid = value;
              this.drawScene();
            })
          Text('网格')
            .fontSize(14)
        }
      }
      .width('100%')
      .padding(10)
      .backgroundColor($r('app.color.card_background'))

      // 旋转控制
      Column() {
        Row() {
          Text('俯仰角:')
            .fontSize(14)
            .width(80)
          Slider({
            value: this.rotationX,
            min: 0,
            max: 90,
            step: 5
          })
            .layoutWeight(1)
            .onChange((value: number) => {
              this.rotationX = value;
              this.config.cameraAngleX = value;
              this.drawScene();
            })
          Text(`${this.rotationX.toFixed(0)}°`)
            .fontSize(14)
            .width(50)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding({ left: 10, right: 10 })

        Row() {
          Text('旋转角:')
            .fontSize(14)
            .width(80)
          Slider({
            value: this.rotationY,
            min: 0,
            max: 360,
            step: 5
          })
            .layoutWeight(1)
            .onChange((value: number) => {
              this.rotationY = value;
              this.config.cameraAngleY = value;
              this.drawScene();
            })
          Text(`${this.rotationY.toFixed(0)}°`)
            .fontSize(14)
            .width(50)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
      }
      .backgroundColor($r('app.color.card_background'))
      .padding({ top: 10, bottom: 10 })

      // Canvas画布
      Canvas(this.canvasContext)
        .width('100%')
        .height(400)
        .backgroundColor('#F0F0F0')
        .onReady(() => {
          this.drawScene();
        })
    }
    .width('100%')
  }

  /**
   * 绘制3D场景
   */
  private drawScene() {
    const ctx = this.canvasContext;
    const width = this.config.viewWidth;
    const height = this.config.viewHeight;

    // 清空画布
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#F5F5F5';
    ctx.fillRect(0, 0, width, height);

    // 绘制网格
    if (this.config.showGrid) {
      this.drawGrid(ctx, width, height);
    }

    // 绘制建筑物
    this.drawBuildings(ctx, width, height);

    // 绘制热力图
    if (this.config.showHeatmap && this.sunshineData.length > 0) {
      this.drawHeatmap(ctx, width, height);
    }
  }

  /**
   * 绘制网格
   */
  private drawGrid(ctx: CanvasRenderingContext2D, width: number, height: number) {
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 0.5;

    const gridSize = 20;
    const centerX = width / 2;
    const centerY = height / 2;

    // 绘制水平线
    for (let i = -10; i <= 10; i++) {
      const y = centerY + i * gridSize;
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }

    // 绘制垂直线
    for (let i = -10; i <= 10; i++) {
      const x = centerX + i * gridSize;
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }
  }

  /**
   * 绘制建筑物
   */
  private drawBuildings(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const centerX = width / 2;
    const centerY = height / 2;
    const scale = 5;

    for (const building of this.buildings) {
      // 计算3D投影坐标
      const points = this.getBuilding3DPoints(building);
      const projected = points.map(p => this.project3D(p, centerX, centerY, scale));

      // 绘制建筑物轮廓
      ctx.fillStyle = 'rgba(25, 118, 210, 0.6)';
      ctx.strokeStyle = '#1976D2';
      ctx.lineWidth = 2;

      // 绘制底面
      ctx.beginPath();
      ctx.moveTo(projected[0].x, projected[0].y);
      for (let i = 1; i < 4; i++) {
        ctx.lineTo(projected[i].x, projected[i].y);
      }
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      // 绘制顶面
      ctx.beginPath();
      ctx.moveTo(projected[4].x, projected[4].y);
      for (let i = 5; i < 8; i++) {
        ctx.lineTo(projected[i].x, projected[i].y);
      }
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      // 绘制侧面
      for (let i = 0; i < 4; i++) {
        ctx.beginPath();
        ctx.moveTo(projected[i].x, projected[i].y);
        ctx.lineTo(projected[(i + 1) % 4].x, projected[(i + 1) % 4].y);
        ctx.lineTo(projected[(i + 1) % 4 + 4].x, projected[(i + 1) % 4 + 4].y);
        ctx.lineTo(projected[i + 4].x, projected[i + 4].y);
        ctx.closePath();
        ctx.fillStyle = 'rgba(25, 118, 210, 0.4)';
        ctx.fill();
        ctx.stroke();
      }
    }
  }

  /**
   * 绘制热力图
   */
  private drawHeatmap(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const centerX = width / 2;
    const centerY = height / 2;
    const scale = 5;

    for (const data of this.sunshineData) {
      const building = this.buildings.find(b => b.id === data.buildingId);
      if (!building) continue;

      // 计算单元位置
      const point: Point3D = {
        x: data.x,
        y: data.y,
        z: data.z
      };

      const projected = this.project3D(point, centerX, centerY, scale);

      // 绘制热力点
      const color = data.getHeatmapColor();
      const opacity = data.getHeatmapOpacity();
      
      ctx.fillStyle = this.hexToRgba(color, opacity);
      ctx.beginPath();
      ctx.arc(projected.x, projected.y, 4, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  /**
   * 获取建筑物的8个顶点坐标
   */
  private getBuilding3DPoints(building: BuildingModel): Point3D[] {
    const height = building.height;
    const halfWidth = building.width / 2;
    const halfLength = building.length / 2;

    const points: Point3D[] = [
      // 底面4个顶点
      { x: building.x - halfWidth, y: building.y - halfLength, z: 0 },
      { x: building.x + halfWidth, y: building.y - halfLength, z: 0 },
      { x: building.x + halfWidth, y: building.y + halfLength, z: 0 },
      { x: building.x - halfWidth, y: building.y + halfLength, z: 0 },
      // 顶面4个顶点
      { x: building.x - halfWidth, y: building.y - halfLength, z: height },
      { x: building.x + halfWidth, y: building.y - halfLength, z: height },
      { x: building.x + halfWidth, y: building.y + halfLength, z: height },
      { x: building.x - halfWidth, y: building.y + halfLength, z: height }
    ];
    return points;
  }

  /**
   * 3D到2D投影
   */
  private project3D(
    point: Point3D,
    centerX: number,
    centerY: number,
    scale: number
  ): Point2D {
    const angleX = this.config.cameraAngleX * Math.PI / 180;
    const angleY = this.config.cameraAngleY * Math.PI / 180;

    // 旋转变换
    const cosX = Math.cos(angleX);
    const sinX = Math.sin(angleX);
    const cosY = Math.cos(angleY);
    const sinY = Math.sin(angleY);

    // 绕Y轴旋转
    let x = point.x * cosY - point.z * sinY;
    let z = point.x * sinY + point.z * cosY;
    let y = point.y;

    // 绕X轴旋转
    const y2 = y * cosX - z * sinX;
    const z2 = y * sinX + z * cosX;

    // 简单透视投影
    const distance = this.config.cameraDistance;
    const perspective = distance / (distance + z2);

    const result: Point2D = {
      x: centerX + x * scale * perspective,
      y: centerY - y2 * scale * perspective
    };
    return result;
  }

  /**
   * 颜色转换
   */
  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
}
