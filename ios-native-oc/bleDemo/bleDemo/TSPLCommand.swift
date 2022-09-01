//
//  TSPLCommand.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/9/1.
//

import Foundation

import adapter
import father

import tspl

class TSPLCommand: TypeC{
    var device: ConnectedDevice
    
    init(_ device:ConnectedDevice) {
        self.device = device
    }

    
    func startAction(event: EventName) {
        switch event {
        case .line:
            line()
        case .image:
            image()
        case .sample:
            sample()
        default:
            break
        }
        
    }
    
    func commandList() -> Array<EventName> {
        return [.image,.sample]
    }
    
}

extension TSPLCommand{
    
    /// 打印图片
    func image() {
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .image(arg: TImage.build({
                return TRealImage(startX: 100, startY: 100, width: 100, height: 100, image: TypeFactory.getImageData() ?? Data(), compress: true, mode: .OVERWRITE)
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)

    }
    
    /// 打印样本
    func sample(){
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .line(arg: TLine.build({
                return TRealLine(startX: 0, startY: 0, endX: 10, endY: 10, width: 10, height: 10, mode: .DOTTED_M1)
            }))
            .text(arg: TText.build({
                return TRealText(startX: 50, startY: 50, xmulti: 5, ymulti: 5, isBold: true, content: "111113433rfffffff", font: Font.TSS16, rotation: .ROTATE_0)
            }))
            .image(arg: TImage.build({
                return TRealImage(startX: 100, startY: 100, width: 100, height: 100, image: TypeFactory.getImageData() ?? Data(), compress: true, mode: .OVERWRITE)
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)

    }
    
    /**
     * 画线(只能画横竖线)
     */
    public func bar()  {
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .bar(arg: TBar.build({
                return TRealBar(startX: 50, startY: 50, endX: 200, endY: 200, width: 150, height: 150, lineType: .DOTTED)
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)
    }
    
    /**
     * 二维码
     */
    public func barcode(){
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .barcode(arg: TBarCode.build({
                return TRealBarCode(startX: 50, startY: 50, codeType: .CODE_128, height: 150, displayType: .CENTER, rotation: .ROTATE_0, cellwidth: 20, content: "1233333333332332")
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)
        
    }
    
    /**
     * 电池电量
     */
    public func batteryVolume(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = TSPL.generic(lifecycle).batteryVolume().write()
        printMsg(wroteReporter)
    }
    
    /**
     * 打印边框
     */
    public func box() {
      
    }
    
    /**
     * 画圆
     */
    public func circle() {
      
    }

    /**
     * 设置浓度
     * @param density 浓度值(0-15)
     * @return
     */
    public func density()  {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = TSPL.generic(lifecycle).density(density: 10).write()
        printMsg(wroteReporter)
    }
    
    /**
     *   打印二维条码DATAMATRIX
     */
    public func dmatrix(){
      
    }
    
    
    /**
     *  二维码
     */
    public func qrcode() {
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .qrcode(arg: TQRCode.build({
                return TRealQRCode(startX: 50, startY: 50, cellWidth: 10, content: "12333223335777", version: "1233")
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)
    }

    /**
     *  查询状态
     */
    public func state() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = TSPL.generic(lifecycle).state().write()
        printMsg(wroteReporter)
    }
    
    /**
     *  打印文本
     */
    public func text() {
     
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .text(arg: TText.build({
                return TRealText(startX: 50, startY: 50, xmulti: 5, ymulti: 5, isBold: true, content: "skskskdkdkdkdkdkdkd", font: .TSS16, rotation: .ROTATE_0)
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)
    }
    
    /**
     *  打印文本框
     */
    public func textBox(){
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .textBox(arg: TTextBox.build({
                return TRealTextBox(startX: 0, startY: 0, xmulti: 5, ymulti: 5, width: 20, linespace: 4, isBold: true, content: "wddddddddddddddddddddd")
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)
    }
    
    /**
     *  查询版本
     */
    public func version(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = TSPL.generic(lifecycle).version().write()
        printMsg(wroteReporter)
    }
    
    /**
     * 画线(能画斜线)
     */
    public func line() {
        let lifecycle = Lifecycle(connectedDevice: device)
                
        let wroteReporter = TSPL.generic(lifecycle).page(arg: TPage.build({
            return TRealPage(width: 500, height: 500)
        }))
            .line(arg: TLine.build({
                return TRealLine(startX: 0, startY: 0, endX: 300, endY: 300, width: 5, height: 5, mode: .DOTTED_M1)
            }))
            .print(copies: 1)
            .write()
        
        printMsg(wroteReporter)
    }
    
    /**
     *  查询SN
     */
    public func sn()  {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = TSPL.generic(lifecycle).sn().write()
        printMsg(wroteReporter)
    }
}
