import promptAction from '@ohos.promptAction'
import { GenericCPCL } from '@psdk/cpcl';
import { GenericESC } from '@psdk/esc';
import { ConnectedDevice, PSDK } from '@psdk/frame-father';
import { OhosNetwork } from '@psdk/ohos-network';
import { GenericTSPL } from '@psdk/tspl';
import CommonUtil from '../common/CommonUtil';
import { PrinterUtil } from '../common/PrinterUtil';

@Entry
@Component
struct Wifi {
  private isOpen: boolean = false;
  @State address: string = '192.168.1.239';
  @State port: number = 9100;
  private cmdType = 'tspl';
  addressController: TextInputController = new TextInputController()
  portController: TextInputController = new TextInputController()
  private ohosNetwork = new OhosNetwork();
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

        Row() {
          Text('IP地址')
            .margin(10)
          TextInput({ text: this.address, placeholder: '输入IP地址...', controller: this.addressController })
            .caretColor(Color.Blue)
            .width('60%')
            .height(40)
            .fontSize(14)
            .fontColor(Color.Black)
            .onChange((value: string) => {
              this.address = value
            })
        }

        Row() {
          Text('端口号')
            .margin(10)
          TextInput({ text: this.port.toString(), placeholder: '输入端口号...', controller: this.portController })
            .caretColor(Color.Blue)
            .width('60%')
            .height(40)
            .fontSize(14)
            .fontColor(Color.Black)
            .onChange((value: string) => {
              this.port = parseInt(value);
            })
        }

        Button('连接端口')
          .width('90%')
          .height(40)
          .onClick(async () => {
            if (this.address === '' || this.port.toString() === '') {
              CommonUtil.showMessage("请输入IP地址或端口号");
            }
            this.connectedDevice = await this.ohosNetwork.connect(this.address, this.port);
            if (this.connectedDevice) {
              CommonUtil.showMessage("打开成功");
              PrinterUtil.getInstance().init(this.connectedDevice);
            } else {
              CommonUtil.showMessage("打开失败，检查地址或端口是否正确");
            }
          })
        Button('关闭端口')
          .width('90%')
          .height(40)
          .onClick(async () => {
            if (this.connectedDevice) {
              await this.connectedDevice.disconnect();
              this.connectedDevice = undefined;
            } else {
              CommonUtil.showMessage("没有可关闭端口");
            }
          })
        Button('打印模版')
          .width('90%')
          .height(40)
          .onClick(() => {
            if (!this.isOpen) {
              CommonUtil.showMessage("未打开端口");
              return
            }
            this.onPrintTemplate();
          })
        Button('打印图片')
          .width('90%')
          .height(40)
          .onClick(() => {
            if (!this.isOpen) {
              CommonUtil.showMessage("未打开端口");
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
