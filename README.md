# 房屋光照计算器 - HarmonyOS版本

<p align="center">
  <img src="entry/src/main/resources/base/media/startIcon.png" alt="App Icon" width="120"/>
</p>

<p align="center">
  <strong>专业的房屋光照计算应用</strong><br>
  精确计算房屋全年各时间段的光照情况，帮助您做出明智的购房决策
</p>

## ✨ 功能特性

### 📱 基础光照计算器

适用于简单场景，快速评估单栋建筑遮挡下的房屋光照情况。

#### 核心功能
- **🌍 城市快速选择**
  - 支持从40+个中国主要城市中快速选择
  - 自动填充城市经纬度信息
  - 支持手动输入自定义经纬度

- **📍 经纬度输入**
  - 支持度-分-秒格式输入（如：118-30-37.97）
  - 自动转换为十进制进行精确计算
  - 支持多种分隔符（°、'、"、-）

- **🏢 参数配置**
  - 所在楼层和层高设置
  - 遮挡楼栋层数和层高
  - 与遮挡楼栋的距离
  - 时区和年份自定义

- **☀️ 光照计算**
  - 全年总日照时间统计
  - 全年有效日照时间
  - 特殊日期光照分析：
    - 春分（3月20日左右）
    - 夏至（6月21日左右）
    - 秋分（9月23日左右）
    - 冬至（12月22日左右）
    - 大寒（1月20日左右）
  - 日照时间百分比可视化

- **✅ 国标验证**
  - 自动验证是否满足国家日照标准
  - 大寒日照时间 ≥ 2小时
  - 冬至日照时间 ≥ 1小时

### 🎯 高级光照计算器

支持复杂多建筑场景，提供专业级光照分析功能。

#### 高级功能
- **🏗️ 建筑物管理**
  - 支持添加、编辑、删除多栋建筑物
  - 可配置建筑物尺寸（宽度、长度、高度）
  - 支持设置楼层高度和单元数量
  - 建筑物旋转角度调整（0-360°）
  - 拖拽式建筑物布局

- **🗺️ 2D平面布局**
  - Canvas 2D 绘图展示建筑布局
  - 网格化绘图区域，支持比例尺配置
  - 可视化建筑物位置和朝向
  - 支持建筑物拖拽移动
  - 选中建筑物高亮显示
  - 建筑物信息实时标注

- **🎨 3D立体视图**
  - 3D建筑模型可视化展示
  - 支持视图旋转、缩放、平移
  - 可调节俯仰角（0-90°）和旋转角（0-360°）
  - 网格显示开关
  - 热力图叠加显示（开发中）
  - 一键还原默认视角

- **📊 单元光照分析**
  - 选择特定建筑、楼层、单元进行分析
  - 全年光照时长计算
  - 特殊日期（春分、夏至、秋分、冬至、大寒）光照详情
  - 年度平均日照时间
  - 多单元批量计算支持
  - 实时计算进度显示

- **📈 数据展示**
  - 单元日照表格视图
  - 支持按楼层、单元筛选
  - 数据排序功能（楼层/日照时长）
  - 直观的日照时长显示
  - 国标合规性标注

- **💾 数据持久化**
  - 建筑布局自动保存
  - 支持导入/导出配置文件（JSON格式）
  - 场景快速切换

- **📱 响应式设计**
  - 支持手机、平板、折叠屏设备
  - 自适应屏幕尺寸
  - 深色/浅色主题自动适配
  - 优化触控体验

## 🏗️ 项目结构

```
entry/src/main/ets/
├── calculator/                     # 计算器核心
│   ├── SimpleSunshineCalculator.ets      # 基础光照计算器
│   ├── AdvancedSunshineCalculator.ets    # 高级光照计算器
│   └── UnitSunshineCalculator.ets        # 单元光照计算器
├── model/                          # 数据模型
│   ├── HouseInputModel.ets               # 房屋输入参数模型
│   ├── HouseSunshineModel.ets            # 光照结果模型
│   ├── BuildingModel.ets                 # 建筑物模型
│   ├── CityModel.ets                     # 城市数据模型
│   ├── SunPosition.ets                   # 太阳位置模型
│   ├── Point3D.ets                       # 3D坐标点
│   └── UnitSunshineData.ets              # 单元日照数据
├── components/                     # UI组件
│   ├── Building3DView.ets                # 3D建筑视图组件
│   └── UnitSunshineTable.ets             # 单元日照表格组件
├── utils/                          # 工具类
│   ├── SunAngleHelper.ets                # 太阳角度计算工具
│   └── CityDataService.ets               # 城市数据服务
├── pages/                          # 页面
│   ├── Index.ets                         # 主页导航
│   ├── SimpleCalculator.ets              # 基础计算器页面
│   ├── AdvancedCalculator.ets            # 高级计算器页面
│   ├── AboutPage.ets                     # 关于页面
│   ├── LauncherPage.ets                  # 启动页
│   └── PrivacyPage.ets                   # 隐私政策页面
└── shiningability/                 # 应用能力
    └── ShiningAbility.ets                # 主能力入口
```

## 🚀 技术亮点

### 1. 精确的天文算法
- 采用专业天文算法计算太阳位置
- 考虑地球公转、自转、黄赤交角等因素
- 时角、赤纬、太阳高度角、方位角精确计算
- 支持任意经纬度、任意时间点的计算
- 计算精度达到分钟级

### 2. 复杂场景遮挡分析
- 3D空间射线追踪算法
- 多建筑物遮挡关系计算
- 考虑建筑物旋转角度的影响
- 动态遮挡判断
- 高效的空间计算优化

### 3. 用户友好的交互设计
- 直观的图形化操作界面
- 拖拽式建筑物布局
- 实时预览和反馈
- 多种视图模式切换
- 响应式布局适配

### 4. HarmonyOS 原生特性
- 基于 ArkTS 开发，性能优异
- 声明式 UI 范式，代码简洁
- 完整的状态管理
- Canvas 2D 绘图能力
- 数据持久化支持
- 深色模式适配

### 5. 数据可视化
- 2D 平面布局图
- 3D 立体建筑模型
- 热力图日照展示（开发中）
- 表格化数据呈现
- 直观的计算结果展示

## 📦 编译说明

### 编译命令
```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" clean --mode module -p product=default -p buildMode=release assembleHap --analyze=normal --parallel --incremental --daemon
```

### 编译状态
✅ **编译通过** - 项目代码已通过 ArkTS 编译器验证，所有语法和类型检查均已通过。

## 📱 使用指南

### 基础光照计算器使用流程

1. **启动应用**
   - 打开应用，在主页选择"基础光照计算器"

2. **选择城市**
   - 点击"选择城市"按钮
   - 从城市列表中选择您所在的城市
   - 系统自动填充经纬度（可手动微调）

3. **输入参数**
   - 所在楼层：您的房屋所在楼层
   - 层高：每层的高度（米）
   - 遮挡楼栋层数：前方遮挡建筑的总层数
   - 遮挡楼栋层高：遮挡建筑的层高（米）
   - 距离：您的楼与遮挡楼的距离（米）
   - 时区和年份：一般使用默认值

4. **计算光照**
   - 点击"计算光照时间"按钮
   - 等待计算完成（通常几秒钟）

5. **查看结果**
   - 查看全年日照时间统计
   - 查看特殊日期的日照情况
   - 检查是否符合国家标准

### 高级光照计算器使用流程

1. **配置基础参数**
   - 设置经纬度（可选择城市）
   - 设置比例尺（米/格）

2. **添加建筑物**
   - 在左侧面板输入建筑参数：
     - 宽度、长度、高度
     - 层高、单元数
     - 旋转角度
   - 点击"添加到画布"按钮
   - 在2D视图中拖拽调整位置

3. **管理建筑物**
   - 点击建筑物进行选中
   - 使用拖拽调整建筑位置
   - 可编辑或删除已添加的建筑

4. **选择计算目标**
   - 选择要分析的建筑物
   - 选择楼层和单元
   - 点击"计算光照"

5. **查看分析结果**
   - 切换到"单元视图"查看详细数据
   - 在"表格"视图中查看数值
   - 在"3D"视图中查看空间分布
   - 支持筛选和排序

6. **保存和导出**
   - 场景自动保存
   - 可导出配置文件
   - 可导入之前的配置

### 经纬度格式说明

- **度-分-秒格式**: `度-分-秒`
  - 示例：`118-30-37.97`（南京）
- **十进制格式**: 直接输入小数
  - 示例：`118.510117`
- **支持的分隔符**: `-`、`°`、`'`、`"`
- **城市示例**:
  - 北京: `116-24-48.18` / `39-54-39.33`
  - 上海: `121-28-49.94` / `31-14-9.35`
  - 广州: `113-15-47.88` / `23-7-31.68`

## 💡 计算原理

### 太阳位置计算

应用采用天文学标准算法计算太阳位置：

1. **赤纬角计算**：根据日期计算太阳赤纬角
2. **时角计算**：根据经度、时区和时间计算太阳时角
3. **高度角计算**：`sin(h) = sin(φ)sin(δ) + cos(φ)cos(δ)cos(H)`
   - h: 太阳高度角
   - φ: 纬度
   - δ: 赤纬角
   - H: 时角
4. **方位角计算**：确定太阳在天空中的方位

### 遮挡分析算法

#### 基础计算器

- 简化的二维遮挡模型
- 考虑遮挡建筑的高度和距离
- 计算太阳高度角是否被遮挡

#### 高级计算器

- 完整的三维空间遮挡分析
- 使用射线追踪算法
- 考虑多建筑物的相互遮挡
- 支持建筑物任意旋转角度

## 🎯 应用场景

- **购房决策**: 评估房屋采光质量
- **房产评估**: 专业人士进行房产价值评估
- **建筑设计**: 建筑师进行日照分析
- **规划审批**: 验证建筑设计是否符合日照标准
- **争议仲裁**: 为采光纠纷提供数据支持

## 📊 国家标准参考

根据《民用建筑设计统一标准》（GB 50352-2019）：

- **住宅建筑**：大寒日日照时间不应低于2小时
- **老年人居住建筑**：冬至日日照时间不应低于2小时
- **旧区改建**：冬至日日照时间不应低于1小时

本应用的计算结果可作为参考，具体标准请以当地建设部门规定为准。

## 🔄 版本历史

### v1.0.0 (当前版本)

#### 已完成功能

- ✅ 基础光照计算器完整功能
- ✅ 高级光照计算器核心功能
- ✅ 2D 建筑布局绘图
- ✅ 3D 建筑模型展示
- ✅ 单元光照分析
- ✅ 数据持久化
- ✅ 配置导入导出
- ✅ 响应式布局
- ✅ 深色模式支持
- ✅ 40+ 城市数据库

#### 待优化功能

- 🚧 3D 视图热力图显示
- 🚧 图表可视化增强
- 🚧 批量导出报告
- 🚧 更多城市数据
- 🚧 计算性能优化
- 🚧 UI/UX 优化

## 🛠️ 开发技术

### 核心技术栈

- **开发语言**: ArkTS (TypeScript for HarmonyOS)
- **UI框架**: ArkUI 声明式范式
- **图形绘制**: Canvas 2D API
- **数据存储**: Preferences API
- **文件操作**: File Picker API

### 关键技术实现

- **天文计算**: 自研太阳位置计算算法
- **3D渲染**: Canvas 2D 实现的伪3D投影
- **射线追踪**: 空间几何遮挡计算
- **状态管理**: @State/@Link 响应式数据绑定
- **异步计算**: 支持长时间计算的进度反馈

## 📖 参考资料

### 开源参考

- 原始项目: [qiuhaotc/Sunshine](https://github.com/qiuhaotc/Sunshine)
- 计算逻辑和功能设计参考自上述开源项目
- 代码完全使用 ArkTS 重新实现

### 技术文档

- [HarmonyOS 开发文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide)
- [ArkTS 语言参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts)
- [ArkUI 组件参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview)

### 标准规范

- GB 50352-2019 《民用建筑设计统一标准》
- GB/T 50033-2013 《建筑采光设计标准》
- JGJ 26-2018 《严寒和寒冷地区居住建筑节能设计标准》

## 🔧 开发环境配置

### 系统要求

- **操作系统**: Windows 10/11 或 macOS
- **开发工具**: DevEco Studio 5.0+
- **Node.js**: 16.x 或更高版本
- **HarmonyOS SDK**: API 12

### 编译步骤

1. 克隆项目到本地
2. 使用 DevEco Studio 打开项目
3. 等待依赖自动安装
4. 使用命令行编译：

```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" `
  "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" `
  clean --mode module -p product=default -p buildMode=release `
  assembleHap --analyze=normal --parallel --incremental --daemon
```

5. 生成的 HAP 包位于: `entry/build/default/outputs/default/`

### 运行调试

1. 连接 HarmonyOS 设备或启动模拟器
2. 点击 DevEco Studio 的"运行"按钮
3. 选择目标设备
4. 应用将自动安装并启动

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 贡献方式

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 代码规范

- 遵循 ArkTS 编码规范
- 保持代码整洁和良好注释
- 提交前确保代码能够编译通过
- 添加必要的功能说明文档

## 📞 联系方式

- **项目主页**: [GitHub - Sunshine_HarmonyOS](https://github.com/qiuhaotc/Sunshine_HarmonyOS)
- **Issues**: [提交问题](https://github.com/qiuhaotc/Sunshine_HarmonyOS/issues)
- **原项目**: [Sunshine Web版](https://github.com/qiuhaotc/Sunshine)

## ⚖️ 免责声明

1. 本应用提供的计算结果仅供参考，不作为法律依据
2. 实际日照情况受多种因素影响，包括但不限于天气、空气质量、周边环境等
3. 涉及房产交易或法律纠纷时，请咨询专业机构
4. 开发者不对使用本应用做出的决策承担任何责任

## 📄 许可证

本项目采用 Apache 2.0 许可证 - 详见 [LICENSE](LICENSE) 文件

## 👏 致谢

- 感谢 [qiuhaotc/Sunshine](https://github.com/qiuhaotc/Sunshine) 项目提供的灵感和参考
- 感谢 HarmonyOS 开发者社区的支持
- 感谢所有为本项目做出贡献的开发者

---

**让每个家都能沐浴阳光 ☀️**
