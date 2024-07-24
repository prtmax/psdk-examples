import DeviceData from '../model/DeviceData'
@Component
export default struct DevicesPage {
  @Link devices: Array<DeviceData>
  private connect: (address: string) => void = () => {}
  build() {
    Column() {
      List({ space: 10 }) {
        ForEach(this.devices, (item: DeviceData) => {
          ListItem() {
            Column() {
              Text('' + item.name+"\r\n"+item.address)
                .width('100%')
                .height(100)
                .fontSize(16)
                .textAlign(TextAlign.Center)
                .borderRadius(10)
                .backgroundColor(0xFFFFFF)
            }
          }
          .onClick(() => {
            this.connect(item.address)
          })
        })
      }
      .listDirection(Axis.Vertical) // 排列方向
      .divider({ strokeWidth: 2, color: 0xFFFFFF, startMargin: 20, endMargin: 20 }) // 每行之间的分界线
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