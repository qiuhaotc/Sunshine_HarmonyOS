/**
 * 保存历史记录对话框
 */
@CustomDialog
export struct SaveHistoryDialog {
  @State recordName: string = '';
  
  defaultName: string = '';
  onSave?: (name: string) => void;
  onClose?: () => void;
  controller?: CustomDialogController;

  aboutToAppear() {
    this.recordName = this.defaultName;
  }

  build() {
    Column() {
      Text('保存为历史记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Column() {
        Text('记录名称')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ text: this.recordName, placeholder: '请输入记录名称' })
          .fontSize(16)
          .onChange((value: string) => {
            this.recordName = value;
          })
      }
      .width('100%')
      .margin({ bottom: 20 })
      
      Text('提示: 最多保存20条记录,超出后会自动删除最旧的记录')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 20 })
      
      Row({ space: 15 }) {
        Button('取消')
          .fontSize(16)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_secondary'))
          .border({ width: 1, color: $r('app.color.divider_color') })
          .onClick(() => {
            if (this.onClose) {
              this.onClose();
            }
          })
        
        Button('保存')
          .fontSize(16)
          .layoutWeight(1)
          .backgroundColor('#1976D2')
          .enabled(this.recordName.trim().length > 0)
          .onClick(() => {
            if (this.onSave && this.recordName.trim().length > 0) {
              this.onSave(this.recordName.trim());
            }
          })
      }
      .width('100%')
    }
    .width('85%')
    .constraintSize({ maxWidth: 400 })
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: 20,
      color: '#00000030',
      offsetX: 0,
      offsetY: 4
    })
  }
}
