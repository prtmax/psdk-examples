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
  CMag,
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

// 图片打印尺寸，只需修改这里即可同步调整 Canvas 和像素数据尺寸。
const IMAGE_SIZE = {
  width: 2496,
  height: 3564,
};

const ESC_ACTIVE_REPORTS = {
  STATUS: 0xFF,
  PAPER_ERROR: 0xFE,
  START_OR_STOP: 0xFD,
  BATTERY: 0xFB,
};

function bytesToHex(bytes) {
  return bytes.map(byte => byte.toString(16).padStart(2, '0')).join('').toUpperCase();
}

function isEscActiveReport(value) {
  return value === ESC_ACTIVE_REPORTS.STATUS ||
    value === ESC_ACTIVE_REPORTS.PAPER_ERROR ||
    value === ESC_ACTIVE_REPORTS.START_OR_STOP ||
    value === ESC_ACTIVE_REPORTS.BATTERY;
}

var bluetooth = new WechatBleBluetooth({
  allowNoName: false,
			flowControl: {
				enabled: true,
			}
})
// index.js
// 获取应用实例
const app = getApp()

Page({
  escPending: '',
  escNotifyBuffer: [],
  data: {
    discoveredDevices: [],
    connectedDeviceId: "",
    connectedDevice:null,
    isPrint:false,
    cpcl: null,
    tspl: null,
    esc: null,
    printer: null,
    isEsc: false,
    escPending: '',
    escStatus: '未查询',
    escBattery: '未查询',
    escSn: '未查询',
    escEvents: [],
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
    that.escPending = '';
    that.escNotifyBuffer = [];
    that.data.connectedDevice.notify(async value => {
      if (that.data.isEsc) {
        that.handleEscNotification(value);
      }
    });
    that.setData({
      escPending: '',
      escStatus: '未查询',
      escBattery: '未查询',
      escSn: '未查询',
      escEvents: [],
    });
  },
  safeWrite: async function(psdk) {
    let that = this;
    try {
      if (!that.data.isPrint) {
        that.data.isPrint = true;
        const report = await psdk.write();//不分包发送，如果不会丢包可以不分包
        // const report = await psdk.write({
        // 	enableChunkWrite: true,
        // 	chunkSize: 20
        // });//分包发送，chunkSize:分包大小
        that.data.isPrint = false;
        console.log(report);
        wx.showToast({
          title: '成功',
        });
        return true;
      }
    } catch (e) {
      that.data.isPrint = false;
      console.error(e);
      wx.showToast({
        title: '失败',
      });
      return false;
    }
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
      .mag(new CMag({
        font: CFont.TSS24_MAX2
      })) //字号有用到MAX的或者使用MAX后要恢复成没有MAX的需要加个mag指令
      .text(new CText({
        x: 598 - 56 - 16 - 120 + 17,
        y: 696 + 80 + 136 + 11 + 6,
        content: "已验视",
        font: CFont.TSS24_MAX2
      }))
      .mag(new CMag({
        font: CFont.TSS24
      }))
      .form(new CForm())//定位指令
      .print();
    console.log(cpcl.command().string());
    await that.safeWrite(cpcl);
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
    await that.safeWrite(tspl);
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
    await that.safeWrite(tspl);
  },
  writeImage: async function () {
    console.log("writeImage")
    const that = this;
    const printer = that.data.items[0].checked
      ? that.data.tspl
      : that.data.items[1].checked
        ? that.data.cpcl
        : that.data.esc;
    if (!printer) {
      wx.showToast({
        title: '请先连接设备',
        icon: 'none',
      });
      return;
    }
    // 把图片画到离屏 canvas 上
    const canvas = wx.createOffscreenCanvas({
      type: '2d',
      width: IMAGE_SIZE.width,
      height: IMAGE_SIZE.height,
    });
    const ctx = canvas.getContext('2d');
    const image = canvas.createImage();
    await new Promise(resolve => {
      image.onload = resolve;
      image.src = "/image/p3.png"; // 要加载的图片 url, 可以是base64
    });
    ctx.drawImage(image, 0, 0, IMAGE_SIZE.width, IMAGE_SIZE.height);
    console.log("toDataURL - ", ctx.canvas.toDataURL()) // 输出的图片
    const imageData = ctx.getImageData(0, 0, IMAGE_SIZE.width, IMAGE_SIZE.height);
    const inputImage = {
      data: imageData.data,
      width: imageData.width,
      height: imageData.height,
    };
    if (that.data.items[0].checked) {
      const tspl = await that.data.tspl
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
            image: inputImage
          })
        )
        .print();
        await that.safeWrite(tspl);
    } else if (that.data.items[1].checked) {
      const cpcl = await that.data.cpcl
        .page(new CPage({
          width: 608,
          height: 1040
        }))
        .image(
          new CImage({
            x: 0,
            y: 0,
            compress: true,
            image: inputImage
          })
        )
        .print();
        await that.safeWrite(cpcl);
    } else {
      const esc = await that.data.esc
        .enable()
        .wakeup()
        .image(
          new EImage({
            image: inputImage,
            compress:true,
            threshold:128
          })
        )
        .stopJob();
        that.setEscPending('print');
        const ok = await that.safeWrite(esc);
        if (!ok) that.clearEscPending();
    }

  },
  queryEscStatus: async function () {
    if (!this.data.esc || !this.data.connectedDevice) {
      wx.showToast({title: '请先连接设备', icon: 'none'});
      return;
    }
    this.setEscPending('status');
    const ok = await this.safeWrite(this.data.esc.state());
    if (!ok) this.clearEscPending();
  },
  queryEscBattery: async function () {
    if (!this.data.esc || !this.data.connectedDevice) {
      wx.showToast({title: '请先连接设备', icon: 'none'});
      return;
    }
    this.setEscPending('battery');
    const ok = await this.safeWrite(this.data.esc.batteryVolume());
    if (!ok) this.clearEscPending();
  },
  queryEscSn: async function () {
    if (!this.data.esc || !this.data.connectedDevice) {
      wx.showToast({title: '请先连接设备', icon: 'none'});
      return;
    }
    this.setEscPending('sn');
    const ok = await this.safeWrite(this.data.esc.sn());
    if (!ok) this.clearEscPending();
  },
  setEscPending: function (pending) {
    this.escPending = pending;
    this.setData({escPending: pending});
  },
  clearEscPending: function () {
    this.escPending = '';
    this.setData({escPending: ''});
  },
  handleEscNotification: function (value) {
    const bytes = Array.from(value || []);
    if (!bytes.length) return;
    console.log('[ESC] notify:', bytesToHex(bytes));
    this.escNotifyBuffer = (this.escNotifyBuffer || []).concat(bytes);

    while (this.escNotifyBuffer.length) {
      const first = this.escNotifyBuffer[0];
      if (isEscActiveReport(first)) {
        if (this.escNotifyBuffer.length < 2) return;
        this.handleEscActiveReport(this.escNotifyBuffer.splice(0, 2));
        continue;
      }

      // OK may be split across two BLE notifications.
      if (this.escPending === 'print' && first === 0x4F && this.escNotifyBuffer.length < 2) {
        return;
      }

      const response = this.escNotifyBuffer.splice(0);
      this.handleEscResponse(response);
    }
  },
  handleEscActiveReport: function (frame) {
    const type = frame[0];
    const value = frame[1];
    if (type === ESC_ACTIVE_REPORTS.STATUS) {
      const messages = [];
      if (value & 0x01) messages.push('过热');
      if (value & 0x02) messages.push('开盖');
      if (value & 0x04) messages.push('缺纸');
      if (value & 0x08) messages.push('低电压');
      const status = messages.length ? messages.join('、') : '正常';
      this.setData({escStatus: status});
      this.addEscEvent(`打印机状态：${status}`);
      if (value & 0x06) this.clearEscPending();
      return;
    }
    if (type === ESC_ACTIVE_REPORTS.PAPER_ERROR) {
      const paperTypes = {
        0x01: '折叠黑标纸',
        0x02: '连续卷筒纸',
        0x03: '不干胶缝隙纸',
      };
      this.addEscEvent(`纸张类型错误：${paperTypes[value] || `未知(${value})`}`);
      this.clearEscPending();
      return;
    }
    if (type === ESC_ACTIVE_REPORTS.START_OR_STOP) {
      this.addEscEvent(value === 0x01 ? '打印机终止打印' : value === 0x02 ? '打印机继续打印' : `打印控制：${value}`);
      if (value === 0x01) this.clearEscPending();
      return;
    }
    if (type === ESC_ACTIVE_REPORTS.BATTERY) {
      const batteryStates = ['正常', '低电', '充电中', '充电完成'];
      const batteryState = batteryStates[value] || `未知(${value})`;
      this.setData({escBattery: batteryState});
      this.addEscEvent(`电池状态：${batteryState}`);
    }
  },
  handleEscResponse: function (bytes) {
    const pending = this.escPending;
    if (pending === 'status') {
      const flags = bytes[0] || 0;
      const messages = [];
      if (flags & 0x01) messages.push('正在打印');
      if (flags & 0x02) messages.push('纸舱盖开');
      if (flags & 0x04) messages.push('缺纸');
      if (flags & 0x08) messages.push('电池电压低');
      if (flags & 0x10) messages.push('打印头过热');
      this.setData({escStatus: messages.length ? messages.join('、') : '良好'});
      this.clearEscPending();
      return;
    }
    if (pending === 'battery') {
      const batteryStates = ['未充电', '未充电', '充电中', '已充满'];
      const stateCode = bytes.length ? bytes[0] : '';
      const state = batteryStates[stateCode] || `未知状态(${stateCode})`;
      const level = bytes.length > 1 ? bytes[1] : '未知';
      this.setData({escBattery: `${level}，${state}`});
      this.clearEscPending();
      return;
    }
    if (pending === 'sn') {
      this.setData({escSn: this.decodeEscText(bytes)});
      this.clearEscPending();
      return;
    }

    const hex = bytesToHex(bytes);
    if (hex === '4F4B' || hex === 'AA') {
      this.addEscEvent('打印完成');
      this.clearEscPending();
    } else if (hex === '4552') {
      this.addEscEvent('打印失败');
      this.clearEscPending();
    } else if (bytes.length) {
      this.addEscEvent(`收到响应：${hex}`);
    }
  },
  decodeEscText: function (bytes) {
    const cleanBytes = bytes.filter(byte => byte !== 0);
    try {
      if (typeof TextDecoder === 'function') {
        return new TextDecoder('gb18030').decode(new Uint8Array(cleanBytes)).trim() || bytesToHex(bytes);
      }
    } catch (e) {
      console.warn('[ESC] 文本解码失败', e);
    }
    return String.fromCharCode.apply(null, cleanBytes).trim() || bytesToHex(bytes);
  },
  addEscEvent: function (message) {
    const now = new Date();
    const time = [now.getHours(), now.getMinutes(), now.getSeconds()]
      .map(value => String(value).padStart(2, '0')).join(':');
    const events = [{time, message}].concat(this.data.escEvents || []).slice(0, 8);
    this.setData({escEvents: events});
    console.log('[ESC] event:', message);
  },
  onLoad() {

  },
  radioChange(e) {
    let that = this;
    const selectedType = e.detail.value;
    const items = that.data.items.map(item => ({
      ...item,
      checked: item.type === selectedType,
    }));
    that.setData({
      items,
      isEsc: selectedType === 'esc',
    });
    if (selectedType !== 'esc') {
      that.clearEscPending();
      that.escNotifyBuffer = [];
    }
  },
})
