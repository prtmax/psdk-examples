import { router } from '@kit.ArkUI'

@Entry
@Component
struct MainPage {
  aboutToAppear(): void {
  }

  build() {
    Column({ space: 20 }) {
      Button('经典蓝牙').onClick(() => {
        router.pushUrl({ url: "pages/Classic" })
      })
        .height(50)
        .width('90%')

      Button('ble蓝牙').onClick(() => {
        router.pushUrl({ url: "pages/Ble" })
      })
        .height(50)
        .width('90%')

      Button('usb').onClick(() => {
        router.pushUrl({ url: "pages/Usb" })
      })
        .height(50)
        .width('90%')

      Button('以太网').onClick(() => {
        router.pushUrl({ url: "pages/Wifi" })
      })
        .height(50)
        .width('90%')
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
