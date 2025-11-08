# HarmonyOS 开发常用提示词

## 快速编译验证

### #compile-test
运行 HarmonyOS 项目编译命令,验证代码是否可以成功编译:
```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" clean --mode module -p product=default -p buildMode=release assembleHap --analyze=normal --parallel --incremental --daemon
```

## 开发文档查询

### #check-docs
查询 HarmonyOS 官方开发文档获取最新的 API 和开发指南:
- 主文档: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- 请根据具体需求查找相关章节

## 组件开发

### #create-component
创建一个新的 HarmonyOS 自定义组件,包含:
- @Component 装饰器
- build() 方法
- 合理的状态管理
- 符合 HarmonyOS 设计规范

### #add-page
添加一个新的页面到 HarmonyOS 应用:
1. 在 `entry/src/main/ets/pages/` 创建页面文件
2. 使用 @Entry 和 @Component 装饰器
3. 实现页面布局和交互逻辑
4. 运行编译测试验证

## 功能实现

### #implement-feature
实现一个新功能的完整流程:
1. 分析需求并设计方案
2. 编写代码实现功能
3. 运行编译命令验证
4. 如有错误则修复并重新编译

### #fix-compile-error
修复编译错误:
1. 分析编译错误信息
2. 定位问题代码
3. 根据 HarmonyOS 文档修正
4. 重新运行编译验证

## 代码优化

### #optimize-performance
优化 HarmonyOS 应用性能:
- 减少不必要的状态更新
- 优化组件渲染
- 使用合适的布局方式
- 遵循 HarmonyOS 性能最佳实践

### #refactor-code
重构代码使其更符合 HarmonyOS 开发规范:
- 提取可复用组件
- 优化状态管理
- 改进代码结构
- 提高代码可维护性

## 资源管理

### #add-resources
添加资源文件(图片、字符串等)到 HarmonyOS 项目:
1. 将资源放到 `entry/src/main/resources/` 对应目录
2. 在代码中正确引用资源
3. 验证资源是否正确加载

## 调试支持

### #debug-issue
调试 HarmonyOS 应用问题:
1. 分析问题现象
2. 检查相关代码
3. 查阅官方文档寻找解决方案
4. 修复问题并验证

### #review-code
代码审查,检查是否符合 HarmonyOS 开发规范:
- 装饰器使用是否正确
- 组件结构是否合理
- 状态管理是否规范
- 性能是否优化
