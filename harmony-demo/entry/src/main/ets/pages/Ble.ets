import util from '@ohos.util';
import DevicesPage from '../common/DevicesPage';
import DeviceData from '../model/DeviceData';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import {constant } from '@kit.ConnectivityKit';
import ble from '@ohos.bluetooth.ble';
import commonUtil from '../common/CommonUtil';

let device: ble.GattClientDevice;
let allowServiceUuid: string = '49535343-FE7D-4AE5-8FA9-9FAFD205E455';
let allowWriteCharacteristicUuid: string = '49535343-8841-43F4-A8D4-ECBE34729BB3';
let allowReadCharacteristicUuid: string = '49535343-1e4d-4bd9-ba61-23c647249616';
let serviceUuid: string;
let writeCharacteristicUuid: string;
let readCharacteristicUuid: string;
@Entry
@Component
struct Ble {
  @State discoveredDevices: DeviceData[] = [];
  @State connectionState: string = '未连接';
  private cmd = 'tspl';
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(200, 300)
  private img: ImageBitmap = new ImageBitmap("common/images/dog.jpg")
  private mtu = 20;
  aboutToAppear() {
    console.info('IndexComponent aboutToAppear');
  }

  aboutToDisappear() {
    console.info('IndexComponent aboutToDisappear');
  }

  onConnectionStateEvent = async (state: ble.BLEConnectionChangeState) => {
    console.log('bluetooth connect state changed');
    let connectState: ble.ProfileConnectionState = state.state;
    if (connectState == constant.ProfileConnectionState.STATE_CONNECTED) {
      device.setBLEMtuSize(512);
      device.on('BLEMtuChange', (mtu: number) => {
        console.info('BLEMtuChange, mtu: ' + mtu);
        this.mtu = mtu;
      });
      let allServices = await device.getServices();
      for (const service of allServices) {
        if(service.serviceUuid.toLowerCase() === allowServiceUuid.toLowerCase()){
          serviceUuid = service.serviceUuid;
          let allCharacteristics = service.characteristics;
          for (const characteristic of allCharacteristics) {
            if(characteristic.characteristicUuid.toLowerCase() === allowWriteCharacteristicUuid.toLowerCase()){
              writeCharacteristicUuid = characteristic.characteristicUuid;
            }
            if(characteristic.characteristicUuid.toLowerCase() === allowReadCharacteristicUuid.toLowerCase()){
              readCharacteristicUuid = characteristic.characteristicUuid;
            }
          }
        }
      }
      let remoteDeviceName: string = await device.getDeviceName();
      this.connectionState = remoteDeviceName + '已连接';
      promptAction.showToast({
        message: '连接成功',
        duration: 2000
      });
    }
    if (connectState == constant.ProfileConnectionState.STATE_DISCONNECTED) {
      this.connectionState = '未连接';
    }
  }

  discovery() {
    this.discoveredDevices = [];
    try {
      ble.on("BLEDeviceFind", this.onReceiveEvent);
      let scanOptions: ble.ScanOptions = {
        interval: 500,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
      }
      ble.startBLEScan(null, scanOptions);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  onReceiveEvent = (data: Array<ble.ScanResult>) => {
    console.info('bluetooth device find = ' + JSON.stringify(data));
    try {
      let remoteDeviceName: string = data[0].deviceName;
      if (remoteDeviceName === '') {
        return;
      }
      if (remoteDeviceName === null) {
        return;
      }
      const isDuplicate = this.discoveredDevices.find(item => item.address === data[0].deviceId);
      if (isDuplicate) {
        return;
      }
      this.discoveredDevices.push(new DeviceData(remoteDeviceName, data[0].deviceId));
    } catch (err) {
      console.error("errCode:" + err.code + ",errMessage:" + err.message);
    }
  }
  dataRead = (characteristicChangeReq: ble.BLECharacteristic) => {
    let serviceUuid: string = characteristicChangeReq.serviceUuid;
    let characteristicUuid: string = characteristicChangeReq.characteristicUuid;
    let data: Uint8Array = new Uint8Array(characteristicChangeReq.characteristicValue);
    console.log('bluetooth data is: ' + data[0]);
  }

  async onConnect(address: string) {
    try {
      device = ble.createGattClientDevice(address);
      device.on('BLEConnectionStateChange', this.onConnectionStateEvent);
      device.connect()
      ble.stopBLEScan();
      device.on('BLECharacteristicChange', this.dataRead);

    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: '连接失败',
        duration: 2000
      });
    }
  }

  async onWrite() {
    try {
      let printString = 'SIZE 100 mm,175 mm\r\n' +
        'DIRECTION 0,0\r\n' +
        'SET CUTTER 1\r\n' +
        'SET GAP ON\r\n' +
        'SPEED 6\r\n' +
        'DENSITY 12\r\n' +
        'CLS\r\n' +
        'TEXT 20,10,"TSS24.BF2",0,2,2,"测试啊"\r\n' +
        'BAR 300,10,4,90,0\r\n' +
        'LINE 320,420,600,700,5\r\n' +
        'LINE 320,780,600,780,8,M3\r\n' +
        'TEXTBOX 30,800,"TSS24.BF2",0,1,1,700,L24,B1,"万琛电子根据物流行业对电子面单打印机的需求，推出全新的电子面单打印机—启锐电子面单打印机，针对物流行业对电子面单的高标准，该机型做了大量的调整和创新，推出了现行同规格电子面单打印机没有的全新功能，同时也对现有打印机存在的问题进行了转向改进。"\r\n' +
        'BAR 30,100,740,4,0\r\n' +
        'BAR 30,880,740,4,0\r\n' +
        'BAR 30,1300,740,4,0\r\n' +
        'TEXT 400,25,"TSS24.BF2",0,3,3,"上海浦东"\r\n' +
        'TEXT 30,120,"TSS24.BF2",0,1,1,"发  件  人：张三 (电话 874236021)"\r\n' +
        'TEXT 30,150,"TSS24.BF2",0,1,1,"发件人地址：广州省 深圳市 福田区 思创路123号\["]工业园\["]1栋2楼"\r\n' +
        'TEXT 30,200,"TSS24.BF2",0,1,1,"收  件  人：李四 (电话 13899658435)"\r\n' +
        'TEXT 30,230,"TSS24.BF2",0,1,1,"收件人地址：上海市 浦东区 太仓路司务小区9栋1105室"\r\n' +
        'TEXT 30,700,"TSS16.BF2",0,1,1,"各类邮件禁寄、限寄的范围，除上述规定外，还应参阅“中华人民共和国海关对"\r\n' +
        'TEXT 30,720,"TSS16.BF2",0,1,1,"进出口邮递物品监管办法”和国家法令有关禁止和限制邮寄物品的规定，以及邮"\r\n' +
        'TEXT 30,740,"TSS16.BF2",0,1,1,"寄物品的规定，以及邮电部转发的各国（地区）邮 政禁止和限制。"\r\n' +
        'TEXT 30,760,"TSS16.BF2",0,1,1,"寄件人承诺不含有法律规定的违禁物品。"\r\n' +
        'BARCODE 80,300,"128",90,2,0,4,4,"873456093465"\r\n' +
        'BARCODE 550,910,"128",50,2,0,2,2,"873456093465"\r\n' +
        'BOX 40,500,340,650,4,20\r\n' +
        'TEXT 60,520,"TSS24.BF2",0,1,1,"寄件人签字："\r\n' +
        'TEXT 130,625,"TSS24.BF2",0,1,1,"2015-10-30 09:09"\r\n' +
        'TEXT 50,1000,"TSS32.BF2",0,2,3,E8,"广东 ---- 上海浦东"\r\n' +
        'CIRCLE 700,1200,50,6\r\n' +
        'TEXT 670,1170,"TSS24.BF2",0,3,3,"碎"\r\n' +
        'QRCODE 600,620,H,4,A,0,M2,S7,"www.qrprt.com   www.qrprt.com   www.qrprt.com"\r\n' +
        'PRINT 1,1\r\n';
      let textEncoder = new util.TextEncoder('gbk');
      let result = textEncoder.encodeInto(printString);
      // let cmd = Uint8Array.from([0x10, 0xff, 0xef, 0xf2])

      let writeData = Array.from(result);
      let parts = commonUtil.split(writeData, this.mtu);

      for (const part of parts) {
        const partBinary = new Uint8Array(part);
        let characteristic: ble.BLECharacteristic = {
          serviceUuid: serviceUuid,
          characteristicUuid: writeCharacteristicUuid,
          characteristicValue: partBinary.buffer,
          descriptors: []
        };
        await device.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE);
      }

      promptAction.showToast({
        message: '打印成功',
        duration: 2000
      });
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: '打印失败',
        duration: 2000
      });
    }
  }


  onDisconnect() {
    try {
      device.disconnect();
      this.connectionState = '未连接';
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  onPrintImage() {
    try {
      let offContext = this.offCanvas.getContext("2d", this.settings)
      offContext.drawImage(this.img, 0, 0, 384, 582);
      this.context.drawImage(this.img, 0, 0, 384, 582)
      let imageData = this.context.getImageData(0, 0, 384, 582)
      this.context.putImageData(imageData, 150, 150)
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  build() {
    Stack() {
      Row() {
        Column({ space: 15 }) {
          Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
            Text('指令：')
            Column() {
              Text('tspl')
              Radio({ value: 'tspl', group: 'radioGroup' })
                .checked(true)
                .radioStyle({
                  checkedBackgroundColor: Color.Blue
                })
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.cmd = 'tspl';
                  }
                })
            }

            Column() {
              Text('cpcl')
              Radio({ value: 'cpcl', group: 'radioGroup' })
                .checked(false)
                .radioStyle({
                  checkedBackgroundColor: Color.Blue
                })
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.cmd = 'cpcl';
                  }
                })
            }

            Column() {
              Text('esc')
              Radio({ value: 'esc', group: 'radioGroup' })
                .checked(false)
                .radioStyle({
                  checkedBackgroundColor: Color.Blue
                })
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.cmd = 'esc';
                  }
                })
            }
          }.padding({ top: 30 })

          Button('开始搜索')
            .width('90%')
            .height(40)
            .onClick(() => {
              this.discovery()
            })
          Button('断开连接')
            .width('90%')
            .height(40)
            .onClick(() => {
              this.onDisconnect()
            })
          Button('打印模版')
            .width('90%')
            .height(40)
            .onClick(() => {
              this.onWrite()
            })
          Button('打印图片')
            .width('90%')
            .height(40)
            .onClick(() => {
              this.discovery()
            })
          Text(this.connectionState)
            .fontColor(Color.Red)
        }
        .layoutWeight(1)

        DevicesPage({
          devices: $discoveredDevices, connect: (address) => {
            this.onConnect(address)
          }
        })
          .layoutWeight(1)

      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
    }

  }
}