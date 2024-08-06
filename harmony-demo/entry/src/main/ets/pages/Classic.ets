import DevicesPage from '../common/DevicesPage';
import DeviceData from '../model/DeviceData';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import a2dp from '@ohos.bluetooth.a2dp';
import { baseProfile } from '@kit.ConnectivityKit';
import { ConnectedDevice, PSDK } from '@psdk/frame-father';
import CommonUtil from '../common/CommonUtil';
import { OhosBluetoothClassic } from '@psdk/ohos-bluetooth-classic/build/provider';
import { JluetoothDevice } from '@psdk/device-bluetooth-traits/build/index';
import { PrinterUtil } from '../common/PrinterUtil';
import { GenericTSPL } from '@psdk/tspl';
import { GenericCPCL } from '@psdk/cpcl';
import { GenericESC } from '@psdk/esc/build/impls/generic';
import { EscQueryType } from '../common/EscTypes';

@Entry
@Component
struct Index {
  @State discoveredDevices: Array<JluetoothDevice<string>> = [];
  @State connectionState: string = '未连接';
  @State connectedDevice?: ConnectedDevice = undefined;
  private suffix = ['_BLE', '-LE', '-BLE'];
  @State cmdType: string = 'tspl';
  private ohosBluetoothClassic = new OhosBluetoothClassic({ allowNoName: false });
  private isPrint = false
  private escQueryType?: EscQueryType = undefined

  aboutToAppear() {
    this.ohosBluetoothClassic.discovered((devices) => {
      devices.forEach(device => {
        const isBle = this.suffix.find((item) => device.name.toUpperCase().endsWith(item));
        if (isBle) {
          return;
        }
        const isDuplicate = this.discoveredDevices.find(item => item.deviceId === device.deviceId);
        if (isDuplicate) {
          return;
        }
        this.discoveredDevices.push(device);
      });
      return Promise.resolve();
    });
    console.info('IndexComponent aboutToAppear');
  }

  onConnectionStateEvent = (data: baseProfile.StateChangeParam) => {
    console.info('a2dp state = ' + JSON.stringify(data));
  }

  aboutToDisappear() {
    console.info('IndexComponent aboutToDisappear');
  }

  async discovery() {
    this.discoveredDevices = [];
    try {
      await this.ohosBluetoothClassic.startDiscovery();
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: `errCode: ${(err as BusinessError).code} , errMessage: ${(err as BusinessError).message}`,
        duration: 2000
      });
    }
  }

  dataRead = (dataBuffer: ArrayBuffer) => {
    let data = new Uint8Array(dataBuffer);
    console.log('bluetooth data is: ' + data[0]);
  }

  async onConnect(device: JluetoothDevice<string>) {
    try {
      promptAction.showToast({
        message: `连接中。。。。`,
        duration: 2000
      });
      this.connectedDevice = await this.ohosBluetoothClassic.connect(device);
      PrinterUtil.getInstance().init(this.connectedDevice);
      this.connectionState = `${this.connectedDevice.deviceName()}已连接`;
      promptAction.showToast({
        message: `${this.connectedDevice.deviceName()}连接成功`,
        duration: 2000
      });
      console.log("this.connectedDevice: ", this.connectedDevice);
      this.connectedDevice.notify(async (value: Uint8Array) => {
        if (this.escQueryType !== undefined) {
          switch (this.escQueryType) {
            case EscQueryType.Info:
              console.log('jdh')
              break;
            case EscQueryType.SN:
              // esc.sn()
              break;
            case EscQueryType.Mac:
              // esc.mac()
              break;
            case EscQueryType.State:
              // esc.state()
              break;
            case EscQueryType.Version:
              // esc.version()
              break;
            case EscQueryType.Model:
              // esc.model()
              break;
            case EscQueryType.BatteryVolume:
              // esc.batteryVolume()
              break;
            case EscQueryType.ShutTime:
              // esc.getShutdownTime()
              break;
          // case EscQueryType.PaperType:
          //   esc.getPaperTypeQ3()
          //   break;
            case EscQueryType.BtName:
              // esc.name()
              break;
          }
          this.escQueryType = undefined;
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

  async safeWrite(psdk: PSDK<GenericTSPL> |  PSDK<GenericCPCL> | PSDK<GenericESC>) {
    try {
      if (!this.isPrint) {
        this.isPrint = true;
        const report = await psdk.write();//不分包发送，如果不会丢包可以不分包
        // const report = await psdk.write({
        // 	enableChunkWrite: true,
        // 	chunkSize: 20
        // });//分包发送，chunkSize:分包大小
        console.log(`safeWrite report : ${report}`);
        promptAction.showToast({
          message: '打印成功',
          duration: 1000
        });
        this.isPrint = false;
      }
    } catch (e) {
      this.isPrint = false;
      console.error(e);
      promptAction.showToast({
        message: '打印失败',
      });
    }
  }

  async onPrintTemplate() {
    if (this.connectedDevice === undefined) {
      promptAction.showToast({
        message: '请连接设备！！！',
        duration: 1000
      });
      return;
    }
    let psdk: PSDK<GenericTSPL> |  PSDK<GenericCPCL> | PSDK<GenericESC>
    switch (this.cmdType) {
      case 'tspl':
        psdk = CommonUtil.tsplTemplateCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'cpcl':
        psdk = CommonUtil.cpclTemplateCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'esc':
        promptAction.showToast({
          message: 'esc 仅支持图片打印！！！',
          duration: 2000
        });
        return;
      default:
        break;
    }
  }

  async onPrintImage() {
    if (this.connectedDevice === undefined) {
      promptAction.showToast({
        message: '请连接设备！！！',
        duration: 2000
      });
      return;
    }
    let psdk: PSDK<GenericTSPL> |  PSDK<GenericCPCL> | PSDK<GenericESC>
    switch (this.cmdType) {
      case 'tspl':
        psdk = CommonUtil.tsplImageCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'cpcl':
        psdk = CommonUtil.cpclImageCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'esc':
        psdk = CommonUtil.escImageCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      default:
        break;
    };
  }

  async onEscQuery(queryType: EscQueryType) {
    this.escQueryType = queryType
    const esc = CommonUtil.escQueryCmd(queryType);
    await this.safeWrite(esc);
  }

  onDisconnect() {
    try {
      if (this.connectedDevice === undefined) {
        promptAction.showToast({
          message: '请连接设备！！！',
          duration: 1000
        });
        return;
      }
      this.connectedDevice.disconnect();
      this.connectionState = '未连接';
      promptAction.showToast({
        message: '断开成功',
        duration: 2000
      });
      this.connectedDevice = undefined;
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
                    this.cmdType = 'tspl';
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
                    this.cmdType = 'cpcl';
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
                    this.cmdType = 'esc';
                  }
                })
            }
          }.padding({ top: 30 })

          Button('开始搜索')
            .width('90%')
            .height(40)
            .onClick(() => this.discovery())
          Button('断开连接')
            .width('90%')
            .height(40)
            .onClick(() => this.onDisconnect())
          Button('打印模版')
            .width('90%')
            .height(40)
            .onClick(() => this.onPrintTemplate())
          Button('打印图片')
            .width('90%')
            .height(40)
            .onClick(() => this.onPrintImage())
          // if (this.cmdType === 'esc') {
          //   Row({space: FlexAlign.SpaceEvenly}) {
          //     Button('查询')
          //       .onClick(() => {
          //         ActionSheet.show({
          //           title: '查询',
          //           message: '请选择查询内容', //弹窗内容
          //           autoCancel: true, //点击遮障层时，是否关闭弹窗
          //           alignment: DialogAlignment.Bottom, //弹窗位置
          //           sheets: [ //操作选项列表
          //             {
          //               title: '打印机信息 ',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.Info)
          //               }
          //             },
          //             {
          //               title: '打印机 Sn',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.SN)
          //               }
          //             },
          //             {
          //               title: '打印机 Mac ',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.Mac)
          //               }
          //             },
          //             {
          //               title: '打印机状态 ',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.State)
          //               }
          //             },
          //             {
          //               title: '打印机固件版本',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.Version)
          //               }
          //             },
          //             {
          //               title: '打印机型号',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.Model)
          //               }
          //             },
          //             {
          //               title: '电量',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.BatteryVolume)
          //               }
          //             },
          //             {
          //               title: '关机时间',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.ShutTime)
          //               }
          //             },
          //             {
          //               title: '蓝牙名称',
          //               action: async () => {
          //                 await this.onEscQuery(EscQueryType.BtName)
          //               }
          //             },
          //
          //           ]
          //         })
          //       })
          //     Button('设置')
          //   }
          // }
          Text(this.connectionState)
            .fontColor(Color.Red)
        }
        .layoutWeight(1)

        DevicesPage({
          devices: $discoveredDevices,
          connect: (device) => {
            this.onConnect(device)
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
