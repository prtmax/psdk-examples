import {
  WechatBleBluetooth
} from "@psdk/device-ble-wechat";
import {
  FakeConnectedDevice,
  ConnectedDevice,
  Lifecycle,
  Raw
} from '@psdk/frame-father';
import {
  CPCL,
  CBar,
  CBox,
  CForm,
  CImage,
  CLine,
  CCodeRotation,
  CCodeType,
  CPage,
  CText,
  CFont,
} from "@psdk/cpcl";
import {
  TSPL,
  TBar,
  TBarCode,
  TBox,
  TImage,
  TPage,
  TRotation,
  TCodeType,
  TLine,
  TText,
  TFont,
  TTLine,
  TQRCode,
} from "@psdk/tspl";
import {
  ESC,
  EImage
} from "@psdk/esc";
var bluetooth = new WechatBleBluetooth({
  allowedWriteCharacteristic: '49535343-8841-43F4-A8D4-ECBE34729BB3',
	allowedReadCharacteristic: '49535343-1e4d-4bd9-ba61-23c647249616',
  allowNoName: false,
})
// index.js
// 获取应用实例
const app = getApp()

Page({
  data: {
    discoveredDevices: [],
    connectedDeviceId: "",
    connectedDevice:null,
    cpcl: null,
    tspl: null,
    esc: null,
    printer: null,
    items: [{
        type: 'tspl',
        checked: 'true',
      },
      {
        type: 'cpcl',
      },
      {
        type: 'esc',
      },
    ],
    current: 0,
  },
  // 打开蓝牙
  openBluetooth: function () {
    let that = this
    let discoveredDevices1 = that.data.discoveredDevices;
    discoveredDevices1=[]
    that.setData({
      discoveredDevices: []
    })
    bluetooth.discovered(async (devices) => {
      // 发现新设备
      console.log("发现新设备");
      if (!devices.length) return;
      discoveredDevices1 = discoveredDevices1.concat(devices)
      that.setData({
        discoveredDevices: discoveredDevices1
      })

    });
    bluetooth.startDiscovery();

  },
  // 关闭蓝牙模块
  closeBluetooth: function () {
    console.log("断开连接")
    let that = this
    if (that.data.connectedDevice != null) {
      that.data.connectedDevice.disconnect();
    }
    this.setData({
      connectedDevice:null,
      connectedDeviceId: ""
    })

  },
  //连接设备
  connectTO: async function (e) {
    let that = this;
    
    console.log(e);
    wx.showLoading();
    // 连接设备
    try {
      that.data.connectedDevice = await bluetooth.connect(that.data.discoveredDevices[e.currentTarget.id]);
      console.log(that.data.connectedDevice);
    } catch (error) {
      console.log(error);
      wx.showToast({
        title: '连接失败',
      })
      return;
    }
    wx.showToast({
      title: '连接成功',
    })
    console.log(that.data.discoveredDevices[e.currentTarget.id].deviceId);
    that.setData({
      connectedDeviceId: that.data.discoveredDevices[e.currentTarget.id].deviceId
    })
    const lifecycle = new Lifecycle(that.data.connectedDevice);
    that.data.cpcl = CPCL.generic(lifecycle);
    that.data.tspl = TSPL.generic(lifecycle);
    that.data.esc = ESC.generic(lifecycle);
  },
  writeModel: async function () {
    let that = this;
    if (that.data.items[0].checked) {
      that.writeTsplModel();
    }else if(that.data.items[1].checked){
      that.writeCpclModel();
    }
  },
  writeCpclModel: async function () {
    let that = this;
    const cpcl = that.data.cpcl
      .page(new CPage({
        width: 608,
        height: 1040
      }))
      .box(new CBox({
        topLeftX: 0,
        topLeftY: 1,
        bottomRightX: 598,
        bottomRightY: 664,
        lineWidth: 2
      }))
      .line(new CLine({
        startX: 0,
        startY: 88,
        endX: 598,
        endY: 88,
        width: 2
      }))
      .line(new CLine({
        startX: 0,
        startY: 88 + 128,
        endX: 598,
        endY: 88 + 128,
        width: 2
      }))
      .line(new CLine({
        startX: 0,
        startY: 88 + 128 + 80,
        endX: 598,
        endY: 88 + 128 + 80,
        width: 2
      }))
      .line(new CLine({
        startX: 0,
        startY: 88 + 128 + 80 + 144,
        endX: 598 - 56 - 16,
        endY: 88 + 128 + 80 + 144,
        width: 2
      }))
      .line(new CLine({
        startX: 0,
        startY: 88 + 128 + 80 + 144 + 128,
        endX: 598 - 56 - 16,
        endY: 88 + 128 + 80 + 144 + 128,
        width: 2
      }))
      .line(new CLine({
        startX: 52,
        startY: 88 + 128 + 80,
        endX: 52,
        endY: 88 + 128 + 80 + 144 + 128,
        width: 2
      }))
      .line(new CLine({
        startX: 598 - 56 - 16,
        startY: 88 + 128 + 80,
        endX: 598 - 56 - 16,
        endY: 664,
        width: 2
      }))
      .bar(new CBar({
        x: 120,
        y: 88 + 12,
        lineWidth: 1,
        height: 80,
        content: "1234567890",
        codeRotation: CCodeRotation.ROTATION_0,
        codeType: CCodeType.CODE128
      }))
      .text(new CText({
        x: 120 + 12,
        y: 88 + 20 + 76,
        content: "1234567890",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 12,
        y: 88 + 128 + 80 + 32,
        content: "收",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 12,
        y: 88 + 128 + 80 + 96,
        content: "件",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 12,
        y: 88 + 128 + 80 + 144 + 32,
        content: "发",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 12,
        y: 88 + 128 + 80 + 144 + 80,
        content: "件",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 144 + 128 + 16,
        content: "签收人/签收时间",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 430,
        y: 88 + 128 + 80 + 144 + 128 + 36,
        content: "月",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 490,
        y: 88 + 128 + 80 + 144 + 128 + 36,
        content: "日",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 24,
        content: "收姓名" + " " + "13777777777",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 24 + 32,
        content: "南京市浦口区威尼斯水城七街区七街区",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 144 + 24,
        content: "名字" + " " + "13777777777",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 144 + 24 + 32,
        content: "南京市浦口区威尼斯水城七街区七街区",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 598 - 56 - 5,
        y: 88 + 128 + 80 + 104,
        content: "派",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 598 - 56 - 5,
        y: 88 + 128 + 80 + 160,
        content: "件",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 598 - 56 - 5,
        y: 88 + 128 + 80 + 208,
        content: "联",
        font: CFont.TSS24
      }))
      .box(new CBox({
        topLeftX: 0,
        topLeftY: 1,
        bottomRightX: 598,
        bottomRightY: 968,
        lineWidth: 2
      }))
      .line(new CLine({
        startX: 0,
        startY: 696 + 80,
        endX: 598,
        endY: 696 + 80,
        width: 2
      }))
      .line(new CLine({
        startX: 0,
        startY: 696 + 80 + 136,
        endX: 598 - 56 - 16,
        endY: 696 + 80 + 136,
        width: 2
      }))
      .line(new CLine({
        startX: 52,
        startY: 80,
        endX: 52,
        endY: 696 + 80 + 136,
        width: 2
      }))
      .line(new CLine({
        startX: 598 - 56 - 16,
        startY: 80,
        endX: 598 - 56 - 16,
        endY: 968,
        width: 2
      }))
      .bar(new CBar({
        x: 320,
        y: 696 - 4,
        lineWidth: 1,
        height: 56,
        content: "1234567890",
        codeRotation: CCodeRotation.ROTATION_0,
        codeType: CCodeType.CODE128
      }))
      .text(new CText({
        x: 320 + 8,
        y: 696 + 54,
        content: "1234567890",
        font: CFont.TSS16
      }))
      .text(new CText({
        x: 12,
        y: 696 + 80 + 35,
        content: "发",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 12,
        y: 696 + 80 + 84,
        content: "件",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 52 + 20,
        y: 696 + 80 + 28,
        content: "名字" + " " + "13777777777",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 52 + 20,
        y: 696 + 80 + 28 + 32,
        content: "南京市浦口区威尼斯水城七街区七街区",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 598 - 56 - 5,
        y: 696 + 80 + 50,
        content: "客",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 598 - 56 - 5,
        y: 696 + 80 + 82,
        content: "户",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 598 - 56 - 5,
        y: 696 + 80 + 106,
        content: "联",
        font: CFont.TSS24
      }))
      .text(new CText({
        x: 12 + 8,
        y: 696 + 80 + 136 + 22 - 5,
        content: "物品：" + "几个快递" + " " + "12kg",
        font: CFont.TSS24
      }))
      .box(new CBox({
        topLeftX: 598 - 56 - 16 - 120,
        topLeftY: 696 + 80 + 136 + 11,
        bottomRightX: 598 - 56 - 16 - 16,
        bottomRightY: 968 - 11,
        lineWidth: 2
      }))
      .text(new CText({
        x: 598 - 56 - 16 - 120 + 17,
        y: 696 + 80 + 136 + 11 + 6,
        content: "已验视",
        font: CFont.TSS24
      }))
      .form(new CForm())
      .print();
    console.log(cpcl.command().string());
    const report = await cpcl.write({enableChunkWrite:true,chunkSize:20});//分包发送 20一包 嫌慢可以增加分包数 不保证会不会丢包
    console.log(report);
  },
  writeTsplModel: async function () {
    let that = this;
    const tspl = that.data.tspl
      .page(new TPage({
        width: 76,
        height: 130
      }))
      .box(new TBox({
        startX: 0,
        startY: 1,
        endX: 598,
        endY: 664,
        width: 2
      }))
      .line(new TLine({
        startX: 0,
        startY: 88,
        endX: 598,
        endY: 88,
        width: 2
      }))
      .line(new TLine({
        startX: 0,
        startY: 88 + 128,
        endX: 598,
        endY: 88 + 128,
        width: 2
      }))
      .line(new TLine({
        startX: 0,
        startY: 88 + 128 + 80,
        endX: 598,
        endY: 88 + 128 + 80,
        width: 2
      }))
      .line(new TLine({
        startX: 0,
        startY: 88 + 128 + 80 + 144,
        endX: 598 - 56 - 16,
        endY: 88 + 128 + 80 + 144,
        width: 2
      }))
      .line(new TLine({
        startX: 0,
        startY: 88 + 128 + 80 + 144 + 128,
        endX: 598 - 56 - 16,
        endY: 88 + 128 + 80 + 144 + 128,
        width: 2
      }))
      .line(new TLine({
        startX: 52,
        startY: 88 + 128 + 80,
        endX: 52,
        endY: 88 + 128 + 80 + 144 + 128,
        width: 2
      }))
      .line(new TLine({
        startX: 598 - 56 - 16,
        startY: 88 + 128 + 80,
        endX: 598 - 56 - 16,
        endY: 664,
        width: 2
      }))
      .bar(new TBar({
        x: 120,
        y: 88 + 12,
        width: 500,
        height: 2,
        line:TTLine.DOTTED_LINE,
      }))
      .text(new TText({
        x: 120 + 12,
        y: 88 + 20 + 76,
        content: "1234567890",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 12,
        y: 88 + 128 + 80 + 32,
        content: "收",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 12,
        y: 88 + 128 + 80 + 96,
        content: "件",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 12,
        y: 88 + 128 + 80 + 144 + 32,
        content: "发",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 12,
        y: 88 + 128 + 80 + 144 + 80,
        content: "件",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 144 + 128 + 16,
        content: "签收人/签收时间",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 430,
        y: 88 + 128 + 80 + 144 + 128 + 36,
        content: "月",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 490,
        y: 88 + 128 + 80 + 144 + 128 + 36,
        content: "日",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 24,
        content: "收姓名" + " " + "13777777777",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 24 + 32,
        content: "南京市浦口区威尼斯水城七街区七街区",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 144 + 24,
        content: "名字" + " " + "13777777777",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 52 + 20,
        y: 88 + 128 + 80 + 144 + 24 + 32,
        content: "南京市浦口区威尼斯水城七街区七街区",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 598 - 56 - 5,
        y: 88 + 128 + 80 + 104,
        content: "派",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 598 - 56 - 5,
        y: 88 + 128 + 80 + 160,
        content: "件",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 598 - 56 - 5,
        y: 88 + 128 + 80 + 208,
        content: "联",
        font: TFont.TSS24
      }))
      .box(new TBox({
        startX: 0,
        startY: 1,
        endX: 598,
        endY: 968,
        width: 2
      }))
      .line(new TLine({
        startX: 0,
        startY: 696 + 80,
        endX: 598,
        endY: 696 + 80,
        width: 2
      }))
      .line(new TLine({
        startX: 0,
        startY: 696 + 80 + 136,
        endX: 598 - 56 - 16,
        endY: 696 + 80 + 136,
        width: 2
      }))
      .line(new TLine({
        startX: 52,
        startY: 80,
        endX: 52,
        endY: 696 + 80 + 136,
        width: 2
      }))
      .line(new TLine({
        startX: 598 - 56 - 16,
        startY: 80,
        endX: 598 - 56 - 16,
        endY: 968,
        width: 2
      }))
      .barcode(new TBarCode({
        x: 320,
        y: 696 - 4,
        cellWidth: 2,
        height: 56,
        content: "1234567890",
        rotation: TRotation.ROTATION_0,
        codeType: TCodeType.CODE128
      }))
      .text(new TText({
        x: 320 + 8,
        y: 696 + 54,
        content: "1234567890",
        font: TFont.TSS16
      }))
      .text(new TText({
        x: 12,
        y: 696 + 80 + 35,
        content: "发",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 12,
        y: 696 + 80 + 84,
        content: "件",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 52 + 20,
        y: 696 + 80 + 28,
        content: "名字" + " " + "13777777777",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 52 + 20,
        y: 696 + 80 + 28 + 32,
        content: "南京市浦口区威尼斯水城七街区七街区",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 598 - 56 - 5,
        y: 696 + 80 + 50,
        content: "客",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 598 - 56 - 5,
        y: 696 + 80 + 82,
        content: "户",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 598 - 56 - 5,
        y: 696 + 80 + 106,
        content: "联",
        font: TFont.TSS24
      }))
      .text(new TText({
        x: 12 + 8,
        y: 696 + 80 + 136 + 22 - 5,
        content: "物品：" + "几个快递" + " " + "12kg",
        font: TFont.TSS24
      }))
      .box(new TBox({
        startX: 598 - 56 - 16 - 120,
        startY: 696 + 80 + 136 + 11,
        endX: 598 - 56 - 16 - 16,
        endY: 968 - 11,
        width: 2
      }))
      .text(new TText({
        x: 598 - 56 - 16 - 120 + 17,
        y: 696 + 80 + 136 + 11 + 6,
        content: "已验视",
        font: TFont.TSS24
      }))
      .print();
    console.log(tspl.command().string());
    const report = await tspl.write({enableChunkWrite:true,chunkSize:20});//分包发送 20一包 嫌慢可以增加分包数 不保证会不会丢包
    console.log(report);
  },
  writeTsplRibbonModel: async function () {
    let that = this;
    const tspl = that.data.tspl
    .page(new TPage({
      width: 76,
      height: 130
    }))
    //注释的为热转印机器指令
    .label() //标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
    // .bline() //黑标纸打印
    // .continuous() //连续纸打印
    // .offset(0) //进纸
    // .ribbon(false) //热敏模式
    // .shift(0) //垂直偏移
    // .reference(0, 0) //相对偏移
    .qrcode(new TQRCode({
      x: 20,
      y: 20,
      content: "发发发发发",
      cellWidth:2
    }))
    ///使用自定义矢量字体SIMHEI.TTF放大倍数mulX,mulY计算方式想打多大(mm)/0.35取整，例如想打5mm字体：5/0.35=14
    .text(new TText({
      x: 320 + 8,
      y: 696 + 54,
      content: "发发发发发",
      rawFont: "SIMHEI.TTF",
      mulX: 14,
      mulY: 14
    }))
    .text(new TText({
      x: 12,
      y: 696 + 80 + 35,
      content: "发发发发发",
      rawFont: "SIMHEI.TTF",
      mulX: 14,
      mulY: 14
    }))
    .print();
    console.log(tspl.command().string());
    const report = await tspl.write({enableChunkWrite:true,chunkSize:20});//分包发送 20一包 嫌慢可以增加分包数 不保证会不会丢包
    console.log(report);
  },
  writeImage: async function () {
    console.log("writeImage")
    const that = this;
    // 把图片画到离屏 canvas 上
    const canvas = wx.createOffscreenCanvas({
      type: '2d',
      width: 576,
      height: 873
    });
    const ctx = canvas.getContext('2d');
    const image = canvas.createImage();
    await new Promise(resolve => {
      image.onload = resolve;
      image.src = "/image/dog.jpg"; // 要加载的图片 url, 可以是base64
    });
    ctx.drawImage(image, 0, 0, 576, 873);
    console.log("toDataURL - ", ctx.canvas.toDataURL()) // 输出的图片
    if (that.data.items[0].checked) {
      const report = await that.data.tspl
        .page(new TPage({
          width: 76,
          height: 130
        }))
        .gap(true)
        .image(
          new TImage({
            x: 0,
            y: 0,
            compress: true,
            image: canvas
          })
        )
        .print()
        .write({enableChunkWrite:true,chunkSize:20});//分包发送 20一包 嫌慢可以增加分包数 不保证会不会丢包
      console.log(report);
    } else if (that.data.items[1].checked) {
      const report = await that.data.cpcl
        .page(new CPage({
          width: 608,
          height: 1040
        }))
        .image(
          new CImage({
            x: 0,
            y: 0,
            compress: true,
            image: canvas
          })
        )
        .print()
        .write({enableChunkWrite:true,chunkSize:20});//分包发送 20一包 嫌慢可以增加分包数 不保证会不会丢包
      console.log(report);
    } else {
      const report = await that.data.esc
        .enable()
        .wakeup()
        .image(
          new EImage({
            image: canvas,
            compress:true,
            threshold:128
          })
        )
        .stopJob()
        .write({enableChunkWrite:true,chunkSize:20});//分包发送 20一包 嫌慢可以增加分包数 不保证会不会丢包
      console.log(report);
    }

  },
  onLoad() {
    if (wx.getUserProfile) {
      this.setData({
        canIUseGetUserProfile: true
      })
    }
  },
  radioChange(e) {
    let that = this;
    console.log('radio发生change事件，携带value值为：', e.detail.value)
    const items = that.data.items
    for (let i = 0, len = items.length; i < len; ++i) {
      items[i].checked = items[i].type === e.detail.value
    }

  },

})
