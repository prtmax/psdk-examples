import promptAction from '@ohos.promptAction'
import { FakeConnectedDevice } from '@psdk/frame-father';
import CommonUtil from '../common/CommonUtil';
import { PrinterUtil } from '../common/PrinterUtil';
import wifiUtil from '../common/WifiUtil';

@Entry
@Component
struct Wifi {
  private isOpen: boolean = false;
  @State address: string = '192.168.1.239';
  @State port: number = 9100;
  private cmdType = 'tspl';
  addressController: TextInputController = new TextInputController()
  portController: TextInputController = new TextInputController()

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
      await wifiUtil.send(binary);
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
      await wifiUtil.send(binary);
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
        Row(){
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
        Row(){
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
            this.isOpen = await wifiUtil.openSocket(this.address,this.port);
            if (this.isOpen) {
              CommonUtil.showMessage("打开成功");
              PrinterUtil.getInstance().init(new FakeConnectedDevice());
            } else {
              CommonUtil.showMessage("打开失败，检查地址或端口是否正确");
            }
          })
        Button('关闭端口')
          .width('90%')
          .height(40)
          .onClick(() => {
            wifiUtil.closeSocket();
            this.isOpen = false;
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
