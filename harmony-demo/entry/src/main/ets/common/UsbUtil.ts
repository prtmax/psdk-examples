import usb from '@ohos.usbManager';
import { BusinessError } from '@ohos.base';
let currentDevice: usb.USBDevice;
let mUsbInterface: usb.USBInterface| null;
let mUsbEndpointOut: usb.USBEndpoint| null;
let mUsbEndpointIn: usb.USBEndpoint| null;
let mUsbDeviceConnection: usb.USBDevicePipe| null;
export class UsbUtil {
  private VIDQR: number = 0x09C5;
  private VIDMY: number = 0x09C6;
  private isOpen: boolean = false;
  /**
   * 打开USB端口
   */
  openUsb(): boolean {
    let devicesList: Array<usb.USBDevice> = usb.getDevices();
    for (let i = 0; i < devicesList.length; i++) {
      if ((devicesList[i].vendorId == this.VIDQR) || (devicesList[i].vendorId == this.VIDMY)) {
        currentDevice = devicesList[i];
        if (!usb.hasRight(devicesList[i].name)) {
          usb.requestRight(devicesList[i].name);
        }
        try {
          if (this.initCommunication(devicesList[i])) {
            return true;
          }
        } catch (e) {
          return false;
        }
      }
    }
    return false;
  }
  initCommunication(device: usb.USBDevice): boolean {
    let interfaceCount = device.configs[0].interfaces.length;
    for (let interfaceIndex = 0; interfaceIndex < interfaceCount; interfaceIndex++) {
      let usbInterface = device.configs[0].interfaces[interfaceIndex];
      if (7 != usbInterface.clazz) {
        continue;
      }
      mUsbInterface = usbInterface;
      for (let i = 0; i < usbInterface.endpoints.length; i++) {
        let ep = usbInterface.endpoints[i];
        if (ep.type == 2) {
          if (ep.direction == usb.USBRequestDirection.USB_REQUEST_DIR_TO_DEVICE) {
            mUsbEndpointOut = ep;
          } else if (ep.direction == usb.USBRequestDirection.USB_REQUEST_DIR_FROM_DEVICE) {
            mUsbEndpointIn = ep;
          }
        }
      }
      if ((null == mUsbEndpointIn) || (null == mUsbEndpointOut)) {
        mUsbEndpointIn = null;
        mUsbEndpointOut = null;
        this.isOpen = false;
        return false;
      } else {
        if (!usb.hasRight(currentDevice.name)) {
          this.isOpen = false;
          return false;
        } else {
          this.isOpen = true;
          return true;
        }
      }
    }
    return false;
  }
  /**
   * 获得usb打开状态
   *
   * @return true:USB打开 false:USB关闭
   */
  isOpened(): boolean {
    return this.isOpen;
  }
  /**
   * 关闭usb
   */
  closeUsb() {
    mUsbEndpointIn = null;
    mUsbEndpointOut = null;
    if (mUsbDeviceConnection != null) {
      usb.releaseInterface(mUsbDeviceConnection, mUsbInterface);
      usb.closePipe(mUsbDeviceConnection);
      mUsbDeviceConnection = null;
      this.isOpen = false;
    }
  }

  async send_usb(sendData: Uint8Array): Promise<boolean> {
    let length = sendData.length;
    let size = 512;
    let count = 0;
    let yushu = length % size;
    count = (length + size - 1) / size;
    let index = 0;
    if (currentDevice != null) {
      if (mUsbDeviceConnection == null) {
        usb.requestRight(currentDevice.name);
        mUsbDeviceConnection = usb.connectDevice(currentDevice);
        let ret = usb.claimInterface(mUsbDeviceConnection, mUsbInterface, true);
      }
      if (mUsbEndpointOut != null) {
        if (count == 1) {
          let result = await usb.bulkTransfer(mUsbDeviceConnection, mUsbEndpointOut, sendData, 1500);
          if (result == -1) {
            return false;
          }
        } else {
          for (let i = 0; i < count; i++) {
            if (yushu != 0 && i == (count - 1)) {
              let temp = new Uint8Array(yushu);
              for (let j = 0; j < yushu; j++) {
                temp[j] = sendData[index + j];
              }
              let result = await usb.bulkTransfer(mUsbDeviceConnection, mUsbEndpointOut, temp, 1500);
              if (result == -1) {
                return false;
              }
              index = 0;
            } else {
              let temp = new Uint8Array(size);
              for (let j = 0; j < size; j++) {
                temp[j] = sendData[index + j];
              }
              let result = await usb.bulkTransfer(mUsbDeviceConnection, mUsbEndpointOut, temp, 1500);
              index += size;
              if (result == -1) {
                return false;
              }
            }
          }
        }
      } else {
        console.log("mUsbEndpointOut == null需先获得usb权限");
        return false;
      }
    } else {
      console.log("未检测到打印机设备");
      return false;
    }
    return true;
  }

  /**
   * 读取数据
   *
   * @param tempBytes 数据缓冲区
   * @return 返回读取数据的长度
   */
  read_usb(tempBytes: Uint8Array): number {
    if (mUsbDeviceConnection == null) {
      usb.requestRight(currentDevice.name);
      mUsbDeviceConnection = usb.connectDevice(currentDevice);
      let ret = usb.claimInterface(mUsbDeviceConnection, mUsbInterface, true);
    }
    usb.bulkTransfer(mUsbDeviceConnection, mUsbEndpointIn, tempBytes, 15000).then((dataLength: number) => {
      if (dataLength >= 0) {
        return dataLength;
      } else {
        return 0;
      }
    }).catch((error: BusinessError) => {
      return 0;
    });
    return 0;
  }
}

let usbUtil = new UsbUtil()

export default usbUtil as UsbUtil