import DevicesPage from '../common/DevicesPage';
import DeviceData from '../model/DeviceData';
import { BusinessError } from '@ohos.base';
import connection from '@ohos.bluetooth.connection';
import socket from '@ohos.bluetooth.socket';
import promptAction from '@ohos.promptAction';
import a2dp from '@ohos.bluetooth.a2dp';
import { baseProfile } from '@kit.ConnectivityKit';
import { ConnectedDevice, FakeConnectedDevice} from '@psdk/frame-father';
import CommonUtil from '../common/CommonUtil';
import { OhosBluetoothClassic } from '@psdk/ohos-bluetooth-classic/build/provider';
import { PrinterUtil } from '../common/PrinterUtil';

@Entry
@Component
struct Index {
  @State discoveredDevices: DeviceData[] = [];
  @State connectionState: string = '未连接';
  private clientNumber = -1;
  private cmdType = 'tspl';
  private ohosBluetoothClassic = new OhosBluetoothClassic({
    allowNoName: false
  });

  aboutToAppear() {
    this.ohosBluetoothClassic.discovered((devices) => {
      devices.forEach(device => {
        const isDuplicate = this.discoveredDevices.find(item => item.address === device.deviceId);
        if (isDuplicate) {
          return;
        }
        this.discoveredDevices.push(new DeviceData(device.name, device.deviceId));
      });
      return Promise.resolve();
    });
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

  async discovery() {
    this.discoveredDevices = [];
    try {
      // connection.on('bluetoothDeviceFind', this.onReceiveEvent);
      // connection.startBluetoothDiscovery();
     await this.ohosBluetoothClassic.startDiscovery();
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
            PrinterUtil.getInstance().init(new FakeConnectedDevice());
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
  async onPrintTemplate() {
    try {
      let binary: Uint8Array = new Uint8Array();
      switch (this.cmdType) {
        case 'tspl':
          const gtspl = CommonUtil.tsplTemplateCmd();
          console.log(gtspl.command().string());
          binary = gtspl.command().binary();
          break;
        case 'cpcl':
          const gcpcl = CommonUtil.cpclTemplateCmd();
          console.log(gcpcl.command().string());
          binary = gcpcl.command().binary();
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

  onPrintImage() {
    try {
      let binary: Uint8Array = new Uint8Array();
      switch (this.cmdType) {
        case 'tspl':
          const gtspl = CommonUtil.tsplImageCmd();
          console.log(gtspl.command().string());
          binary = gtspl.command().binary();
          break;
        case 'cpcl':
          const gcpcl = CommonUtil.cpclImageCmd();
          console.log(gcpcl.command().string());
          binary = gcpcl.command().binary();
          break;
        case 'esc':
          const gesc = CommonUtil.escImageCmd();
          console.log(gesc.command().string());
          binary = gesc.command().binary();
          break;
        default:
          break;
      }

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

  onDisconnect() {
    try {
      socket.sppCloseClientSocket(this.clientNumber);
      this.connectionState = '未连接';
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
