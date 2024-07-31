import socket from "@ohos.net.socket";
import { BusinessError } from '@ohos.base';

let tcp: socket.TCPSocket;

export class WifiUtil {
  private isOpen: boolean = false;

  /**
   * 连接端口
   */
  async openSocket(address: string, port: number, timeout?: number): Promise<boolean> {
    tcp = socket.constructTCPSocketInstance();
    let tcpConnectOptions: socket.TCPConnectOptions = {
      address: {
        address: address,
        port: port
      },
      timeout: timeout ?? 6000
    }
    try {
      await tcp.connect(tcpConnectOptions);
      this.isOpen = true;
      return true;
    } catch (e) {
      console.log('connect fail' + e);
      this.isOpen = false;
      return false;
    }
  }

  /**
   * 获得端口打开状态
   *
   * @return true:打开 false:关闭
   */
  isOpened(): boolean {
    return this.isOpen;
  }

  /**
   * 关闭
   */
  closeSocket() {
    tcp.close().then(() => {
      console.log('close success');
    }).catch((err: BusinessError) => {
      console.log('close fail' + err);
    });
  }

  async send(sendData: Uint8Array): Promise<boolean> {
    let tcpSendOptions: socket.TCPSendOptions = {
      data: sendData.buffer
    }
    try {
      await tcp.send(tcpSendOptions);
      return true;
    } catch (e) {
      console.log('connect fail' + e);
      return false;
    }
  }
}

let wifiUtil = new WifiUtil()

export default wifiUtil as WifiUtil
