import { GenericTSPL, TBar, TBarCode, TBox,
  TCodeType,
  TFont,
  TImage,
  TLine, TPage, TRotation, TSPL, TText, TTLine } from '@psdk/tspl';
import { GenericCPCL, CBar,
  CBox,
  CForm,
  CImage,
  CLine,
  CCodeRotation,
  CCodeType,
  CPage,
  CText,
  CFont,
  CBold,
  CRotation,
  CInverse,
  CMag, } from '@psdk/cpcl';

import { LengthMetricsUnit } from '@ohos.arkui.node'
import { EImage, GenericESC } from '@psdk/esc';

export class CommonUtil {
  /**
   * Split array
   *
   * @param colls collections
   * @param size  The size of result array
   * @return List
   */
  split<T>(colls: Array<T>, size: number): Array<Array<T>> {
    if (colls.length === 0) {
      return [];
    }
    if (size <= 0) {
      throw new Error('The size must > 0');
    }

    let rets: Array<Array<T>> = [];
    let items: Array<T> = [];

    for (let coll of colls) {
      items.push(coll);
      if (size == items.length) {
        rets.push(items);
        items = [];
      }
    }
    if (0 != items.length) {
      rets.push(items);
    }
    return rets;
  }

  tsplTemplateCmd(tspl: GenericTSPL): GenericTSPL  {
    return tspl.clear()
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
        line: TTLine.DOTTED_LINE,
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
        content: "",
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
        codeType: TCodeType.CODE_128
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
  }

  tsplImageCmd(tspl: GenericTSPL): GenericTSPL {
    return tspl.clear()
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
          image: this._createCanvas("common/images/dog.jpg", 384, 582)
        })
      )
      .print();
  }

  cpclTemplateCmd(cpcl: GenericCPCL): GenericCPCL {
    return cpcl
      .clear()
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
      .form(new CForm()) //标签纸需要加定位指令
      .print()
  }

  cpclImageCmd(cpcl: GenericCPCL): GenericCPCL {
    return cpcl.clear()
      .page(new CPage({
        width: 608,
        height: 1040
      }))
      .image(
        new CImage({
          x: 0,
          y: 0,
          compress: false,
          image: this._createCanvas("common/images/dog.jpg", 384, 582)
        })
      )
      .print();
  }

  escImageCmd(esc: GenericESC): GenericESC {
    return esc.clear()
      .enable()
      .wakeup()
      .image(
        new EImage({
          image: this._createCanvas("common/images/test.jpg", 96, 189),
          compress: false,
        })
      )
      .lineDot(40)
      .position()
      .stopJob();
  }

  _createCanvas(imgPath: string, width: number, height: number, ): OffscreenCanvas {
    const settings: RenderingContextSettings = new RenderingContextSettings(true)
    const offCanvas: OffscreenCanvas = new OffscreenCanvas(width, height, LengthMetricsUnit.PX);
    const img: ImageBitmap = new ImageBitmap(imgPath)

    let offContext = offCanvas.getContext("2d", settings)
    offContext.drawImage(img, 0, 0, width, height);

    return offCanvas;
  }
}

let commonUtil = new CommonUtil()

export default commonUtil as CommonUtil
