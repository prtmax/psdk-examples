import util from '@ohos.util';
import DevicesPage from '../common/DevicesPage';
import DeviceData from '../model/DeviceData';
import { BusinessError } from '@ohos.base';
import connection from '@ohos.bluetooth.connection';
import socket from '@ohos.bluetooth.socket';
import promptAction from '@ohos.promptAction';
import a2dp from '@ohos.bluetooth.a2dp';
import { baseProfile } from '@kit.ConnectivityKit';
import { GenericTSPL, TBar, TBarCode, TBox,
  TCodeType,
  TFont, TLine, TPage, TRotation, TSPL, TText, TTLine } from '@psdk/tspl';
import { ConnectedDevice, FakeConnectedDevice, Lifecycle } from '@psdk/frame-father';
let tspl: GenericTSPL;
@Entry
@Component
struct Index {
  @State discoveredDevices: DeviceData[] = [];
  @State connectionState: string = '未连接';
  private clientNumber = -1;
  private cmd = 'tspl';
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(200, 300)
  private img:ImageBitmap = new ImageBitmap("common/images/dog.jpg")
  aboutToAppear() {
    console.info('IndexComponent aboutToAppear');
    try {
      let a2dpSrc = a2dp.createA2dpSrcProfile();
      a2dpSrc.on('connectionStateChange', this.onConnectionStateEvent);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
  onConnectionStateEvent = (data: baseProfile.StateChangeParam)=> {
    console.info('a2dp state = ' + JSON.stringify(data));
  }
  aboutToDisappear() {
    console.info('IndexComponent aboutToDisappear');
  }

  discovery() {
    this.discoveredDevices = [];
    try {
      connection.on('bluetoothDeviceFind', this.onReceiveEvent);
      connection.startBluetoothDiscovery();
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  onReceiveEvent = (data: Array<string>) => {
    console.info('bluetooth device find = ' + JSON.stringify(data));
    try {
      let remoteDeviceName: string = connection.getRemoteDeviceName(data[0]);
      if (remoteDeviceName === '') {
        return;
      }
      if (remoteDeviceName === null) {
        return;
      }
      if (remoteDeviceName.toUpperCase().endsWith('_BLE') ||
      remoteDeviceName.toUpperCase().endsWith('-LE') ||
      remoteDeviceName.toUpperCase().endsWith('-BLE')) {
        return;
      }
      const isDuplicate = this.discoveredDevices.find(item => item.address === data[0]);
      if (isDuplicate) {
        return;
      }
      this.discoveredDevices.push(new DeviceData(remoteDeviceName, data[0]));
    } catch (err) {
      console.error("errCode:" + err.code + ",errMessage:" + err.message);
    }
  }
  dataRead = (dataBuffer: ArrayBuffer) => {
    let data = new Uint8Array(dataBuffer);
    console.log('bluetooth data is: ' + data[0]);
  }

  onConnect(address: string) {
    let sppOption: socket.SppOptions = { uuid: '00001101-0000-1000-8000-00805f9b34fb', secure: false, type: 0 };
    try {
      socket.sppConnect(address, sppOption, (code: BusinessError, number: number) => {
        if (code) {
          console.error('sppListen error, code is ' + code);
          promptAction.showToast({
            message: '连接失败',
            duration: 2000
          });
          return;
        } else {
          console.log('bluetooth serverSocket Number: ' + number);
          // 获取的clientNumber用作客户端后续读/写操作socket的id。
          this.clientNumber = number;
          try {
            const lifecycle = new Lifecycle(new FakeConnectedDevice());
            tspl = TSPL.generic(lifecycle);
            connection.stopBluetoothDiscovery();
            socket.on('sppRead', number, this.dataRead);
          } catch (err) {
            console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' +
            (err as BusinessError).message);
          }
          let remoteDeviceName: string = connection.getRemoteDeviceName(address);
          this.connectionState = remoteDeviceName+'已连接';
          promptAction.showToast({
            message: '连接成功',
            duration: 2000
          });
        }
      });
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: '连接失败',
        duration: 2000
      });
    }
  }
  async writeTsplModel() {
    try {
      const gtspl = tspl.clear()
        .page(new TPage({
          width: 76,
          height: 130
        }))
        .box(new TBox({
          startX: 0,
          startY: 1,
          endX: 598,
          endY: 664,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88,
          endX: 598,
          endY: 88,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128,
          endX: 598,
          endY: 88 + 128,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128 + 80,
          endX: 598,
          endY: 88 + 128 + 80,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128 + 80 + 144,
          endX: 598 - 56 - 16,
          endY: 88 + 128 + 80 + 144,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128 + 80 + 144 + 128,
          endX: 598 - 56 - 16,
          endY: 88 + 128 + 80 + 144 + 128,
          width: 2
        }))
        .line(new TLine({
          startX: 52,
          startY: 88 + 128 + 80,
          endX: 52,
          endY: 88 + 128 + 80 + 144 + 128,
          width: 2
        }))
        .line(new TLine({
          startX: 598 - 56 - 16,
          startY: 88 + 128 + 80,
          endX: 598 - 56 - 16,
          endY: 664,
          width: 2
        }))
        .bar(new TBar({
          x: 120,
          y: 88 + 12,
          width: 500,
          height: 2,
          line: TTLine.DOTTED_LINE,
        }))
        .text(new TText({
          x: 120 + 12,
          y: 88 + 20 + 76,
          content: "1234567890",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 32,
          content: "",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 96,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 144 + 32,
          content: "发",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 144 + 80,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 128 + 16,
          content: "签收人/签收时间",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 430,
          y: 88 + 128 + 80 + 144 + 128 + 36,
          content: "月",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 490,
          y: 88 + 128 + 80 + 144 + 128 + 36,
          content: "日",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 24,
          content: "收姓名" + " " + "13777777777",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 24 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 24,
          content: "名字" + " " + "13777777777",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 24 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 104,
          content: "派",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 160,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 208,
          content: "联",
          font: TFont.TSS24
        }))
        .box(new TBox({
          startX: 0,
          startY: 1,
          endX: 598,
          endY: 968,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 696 + 80,
          endX: 598,
          endY: 696 + 80,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 696 + 80 + 136,
          endX: 598 - 56 - 16,
          endY: 696 + 80 + 136,
          width: 2
        }))
        .line(new TLine({
          startX: 52,
          startY: 80,
          endX: 52,
          endY: 696 + 80 + 136,
          width: 2
        }))
        .line(new TLine({
          startX: 598 - 56 - 16,
          startY: 80,
          endX: 598 - 56 - 16,
          endY: 968,
          width: 2
        }))
        .barcode(new TBarCode({
          x: 320,
          y: 696 - 4,
          cellWidth: 2,
          height: 56,
          content: "1234567890",
          rotation: TRotation.ROTATION_0,
          codeType: TCodeType.CODE_128
        }))
        .text(new TText({
          x: 320 + 8,
          y: 696 + 54,
          content: "1234567890",
          font: TFont.TSS16
        }))
        .text(new TText({
          x: 12,
          y: 696 + 80 + 35,
          content: "发",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 696 + 80 + 84,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 696 + 80 + 28,
          content: "名字" + " " + "13777777777",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 696 + 80 + 28 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 50,
          content: "客",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 82,
          content: "户",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 106,
          content: "联",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12 + 8,
          y: 696 + 80 + 136 + 22 - 5,
          content: "物品：" + "几个快递" + " " + "12kg",
          font: TFont.TSS24
        }))
        .box(new TBox({
          startX: 598 - 56 - 16 - 120,
          startY: 696 + 80 + 136 + 11,
          endX: 598 - 56 - 16 - 16,
          endY: 968 - 11,
          width: 2
        }))
        .text(new TText({
          x: 598 - 56 - 16 - 120 + 17,
          y: 696 + 80 + 136 + 11 + 6,
          content: "已验视",
          font: TFont.TSS24
        }))
        .print();
      console.log(gtspl.command().string());
      const binary = gtspl.command().binary();
      socket.sppWrite(this.clientNumber, binary.buffer);
      promptAction.showToast({
        message: '打印成功',
        duration: 2000
      });
    } catch (e) {
      console.error(e);
      promptAction.showToast({
        message: '打印失败',
        duration: 2000
      });
    }
  }
  onWrite() {
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
      socket.sppWrite(this.clientNumber, result.buffer);
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
      socket.sppCloseClientSocket(this.clientNumber);
      this.connectionState = '未连接';
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
  onPrintImage() {
    try {
      let offContext = this.offCanvas.getContext("2d", this.settings)
      offContext.drawImage(this.img,0,0,384,582);
      this.context.drawImage(this.img,0,0,384,582)
      let imageData = this.context.getImageData(0,0,384,582)
      this.context.putImageData(imageData,150,150)
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
              this.writeTsplModel()
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