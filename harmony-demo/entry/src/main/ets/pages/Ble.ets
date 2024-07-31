import DevicesPage from '../common/DevicesPage';
import DeviceData from '../model/DeviceData';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import {constant } from '@kit.ConnectivityKit';
import ble from '@ohos.bluetooth.ble';
import CommonUtil from '../common/CommonUtil';
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
  private cmdType = 'tspl';
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
      let writeData = Array.from(binary);
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
    } catch (e) {
      console.error(e);
      promptAction.showToast({
        message: '打印失败',
        duration: 2000
      });
    }
  }

  async onPrintImage() {
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
      let writeData = Array.from(binary);
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
      device.disconnect();
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
