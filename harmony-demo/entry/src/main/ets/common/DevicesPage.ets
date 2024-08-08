import { JluetoothDevice } from '@psdk/device-bluetooth-traits/build/index';

@Component
export default struct DevicesPage {
  @Link devices: Array<JluetoothDevice<string>>
  private connect: (device: JluetoothDevice<string>) => void = () => {}
  build() {
    Column() {
      List({ space: 10 }) {
        ForEach(this.devices, (item: JluetoothDevice<string>) => {
          ListItem() {
            Text(item.name + "\r" + item.deviceId)
              .padding({top: 10, bottom: 10})
              .width('100%')
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .borderRadius(10)
              .backgroundColor(0xFFFFFF)
          }
          .onClick(() => {
            this.connect(item)
          })
        })
      }
      .listDirection(Axis.Vertical) // 排列方向
      .divider({ strokeWidth: 2, color: '#ffe9f0f0'}) // 每行之间的分界线
      .edgeEffect(EdgeEffect.Spring)
      .width('90%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xDCDCDC)
    .padding({ top: 5 })
  }
}
