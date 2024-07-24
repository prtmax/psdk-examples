import usbUtil from '../common/UsbUtil';
import util from '@ohos.util';
import promptAction from '@ohos.promptAction'
@Entry
@Component
struct Usb {
  @State switchText: string = '打开USB'
  private isOpen: boolean = false;

  async onSend() {
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
      let sendResult = await usbUtil.send_usb(result);
    } catch (e) {
    }

  }


  showMessage(text: string) {
    try {
      promptAction.showToast({
        message: text,
        duration: 2000,
      });
    } catch (error) {
      console.error(`showToast args error code is ${error.code}, message is ${error.message}`);
    }
  }

  build() {
    Row() {
      Column({ space: 15 }) {
        Button(this.switchText)
          .width('90%')
          .height(40)
          .onClick(() => {
            if (this.isOpen) {
              usbUtil.closeUsb();
              this.switchText = "打开USB";
              this.isOpen = false;
            } else {
              if (usbUtil.openUsb()) {
                this.switchText = "关闭USB";
                this.isOpen = true;
              } else {
                this.showMessage("打开失败，检查是否有可用的USB端口");
              }
            }
          })
        Button('打印76*130模版')
          .width('90%')
          .height(40)
          .onClick(() => {
            if (!this.isOpen) {
              this.showMessage("未打开USB端口");
              return
            }
            this.onSend()
          })
        Button('打印图片')
          .width('90%')
          .height(40)
          .onClick(() => {
            usbUtil.openUsb()
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}