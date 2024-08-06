import promptAction from '@ohos.promptAction'
import CommonUtil from '../common/CommonUtil';
import { ConnectedDevice, PSDK } from '@psdk/frame-father';
import { PrinterUtil } from '../common/PrinterUtil';
import { GenericTSPL } from '@psdk/tspl';
import { GenericCPCL } from '@psdk/cpcl';
import { GenericESC } from '@psdk/esc';
import { OhosUsb } from '@psdk/ohos-usb';
import { BusinessError } from '@kit.BasicServicesKit';


@Entry
@Component
struct Usb {
  @State switchText: string = '打开USB'
  private isOpen: boolean = false;
  private cmdType = 'tspl';
  private ohosUsb = new OhosUsb();
  private connectedDevice?: ConnectedDevice = undefined;
  private isPrint = false;

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
    let psdk: PSDK<GenericTSPL> | PSDK<GenericCPCL> | PSDK<GenericESC>
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
    }
    ;
  }

  async onConnect() {
    try {
      this.connectedDevice = await this.ohosUsb.openUsb();

      if (this.connectedDevice === undefined || this.connectedDevice === null) {
        promptAction.showToast({
          message: '打开失败，检查是否有可用的USB端口',
          duration: 1000
        });
        return;
      }
      this.switchText = "关闭USB";
      this.isOpen = true;
      PrinterUtil.getInstance().init(this.connectedDevice);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: '打开失败，检查是否有可用的USB端口' + (err as BusinessError).message,
        duration: 2000
      });
    }
  }

  onDisconnect() {
    try {
      if (this.connectedDevice === undefined) {
        promptAction.showToast({
          message: '未打开USB端口',
          duration: 1000
        });
        return;
      }
      this.connectedDevice.disconnect();
      promptAction.showToast({
        message: '关闭成功',
        duration: 2000
      });
      this.connectedDevice = undefined;
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  build() {
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

        Button(this.switchText)
          .width('90%')
          .height(40)
          .onClick(() => {
            if (this.isOpen) {
              this.onDisconnect();
            } else {
              this.onConnect();
            }
          })
        Button('打印模版')
          .width('90%')
          .height(40)
          .onClick(() => {
            if (!this.isOpen) {
              promptAction.showToast({
                message: '未打开USB端口',
                duration: 2000
              });
              return
            }
            this.onPrintTemplate();
          })
        Button('打印图片')
          .width('90%')
          .height(40)
          .onClick(() => {
            if (!this.isOpen) {
              promptAction.showToast({
                message: '未打开USB端口',
                duration: 2000
              });
              return
            }
            this.onPrintImage();
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
