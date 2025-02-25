import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import ble from '@ohos.bluetooth.ble';
import CommonUtil from '../common/CommonUtil';
import { OhosBluetoothLe } from '@psdk/ohos-bluetooth-le';
import { JluetoothDevice } from '@psdk/device-bluetooth-traits';
import { ConnectedDevice, PSDK, Raw } from '@psdk/frame-father';
import { PrinterUtil } from '../common/PrinterUtil';
import DevicesPageBle from '../common/DevicesPageBle';
import { GenericTSPL } from '@psdk/tspl';
import { GenericCPCL } from '@psdk/cpcl';
import { GenericESC } from '@psdk/esc';

let allowServiceUuid: string = '49535343-FE7D-4AE5-8FA9-9FAFD205E455';
let allowWriteCharacteristicUuid: string = '49535343-8841-43F4-A8D4-ECBE34729BB3';
let allowReadCharacteristicUuid: string = '49535343-1e4d-4bd9-ba61-23c647249616';

@Entry
@Component
struct Ble {
  @State discoveredDevices: Array<JluetoothDevice<ble.ScanResult>> = [];
  @State connectionState: string = '未连接';
  @State connectedDevice?: ConnectedDevice = undefined;
  private cmdType = 'tspl';
  private mtu = 20;
  private ohosBluetoothLe = new OhosBluetoothLe({
    allowNoName: false,
    allowedWriteCharacteristic: '49535343-8841-43F4-A8D4-ECBE34729BB3',
    allowedReadCharacteristic: '49535343-1e4d-4bd9-ba61-23c647249616'
  });
  private isPrint = false;

  aboutToAppear() {
    console.info('IndexComponent aboutToAppear');
    this.ohosBluetoothLe.discovered((devices) => {
      devices.forEach(device => {
        const isDuplicate = this.discoveredDevices.find(item => item.deviceId === device.deviceId);
        if (isDuplicate) {
          return;
        }
        this.discoveredDevices.push(device);
      });
      return Promise.resolve();
    });
  }

  aboutToDisappear() {
    console.info('IndexComponent aboutToDisappear');
  }

  async discovery() {
    this.discoveredDevices = [];
    try {
      await this.ohosBluetoothLe.startDiscovery();
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  dataRead = (characteristicChangeReq: ble.BLECharacteristic) => {
    let serviceUuid: string = characteristicChangeReq.serviceUuid;
    let characteristicUuid: string = characteristicChangeReq.characteristicUuid;
    let data: Uint8Array = new Uint8Array(characteristicChangeReq.characteristicValue);
    console.log('bluetooth data is: ' + data[0]);
  }

  async onConnect(device: JluetoothDevice<ble.ScanResult>) {
    try {
      promptAction.showToast({
        message: `连接中。。。。`,
        duration: 2000
      });
      this.connectedDevice = await this.ohosBluetoothLe.connect(device);
      PrinterUtil.getInstance().init(this.connectedDevice);
      this.connectionState = `${this.connectedDevice.deviceName()}已连接`;
      promptAction.showToast({
        message: `${this.connectedDevice.deviceName()}连接成功`,
        duration: 2000
      });
      console.log("this.connectedDevice: ", this.connectedDevice);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: '连接失败',
        duration: 2000
      });
    }
  }

  async safeWrite(psdk: PSDK<GenericTSPL> | PSDK<GenericCPCL> | PSDK<GenericESC>) {
    try {
      if (!this.isPrint) {
        this.isPrint = true;
        const report = await psdk.write(); //不分包发送，如果不会丢包可以不分包
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

  async safeWriteByBinary(value: Uint8Array) {
    try {
      if (!this.isPrint) {
        this.isPrint = true;
        const report = await PrinterUtil.getInstance()
          .esc().raw(Raw.binary(value, { newline: false })).write();
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
    let psdk: PSDK<GenericTSPL> | PSDK<GenericCPCL> | PSDK<GenericESC>
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
    let value: Uint8Array;
    switch (this.cmdType) {
      case 'tspl':
        value = await CommonUtil.tsplImageCmd();
        await this.safeWriteByBinary(value);
        break;
      case 'cpcl':
        value = await CommonUtil.cpclImageCmd();
        await this.safeWriteByBinary(value);
        break;
      case 'esc':
        value = await CommonUtil.escImageCmd();
        await this.safeWriteByBinary(value);
        break;
      default:
        break;
    }
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
              this.onPrintTemplate()
            })
          Button('打印图片')
            .width('90%')
            .height(40)
            .onClick(() => {
              this.onPrintImage()
            })
          Text(this.connectionState)
            .fontColor(Color.Red)
        }
        .layoutWeight(1)

        DevicesPageBle({
          devices: $discoveredDevices, connect: (device) => {
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
