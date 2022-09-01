//
//  CPCLCommand.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/9/1.
//

import Foundation
import adapter
import father
import cpcl

class CPCLCommand: TypeC{
    var device: ConnectedDevice
    
    init(_ device:ConnectedDevice) {
        self.device = device
    }
    
    func commandList() -> Array<EventName> {
        return [.sample]
    }
    
    
    func startAction(event: EventName) {
        
    }
    
    
}


extension CPCLCommand{
    
    /// 打印图片
    func image(){
        let lifecycle = Lifecycle(connectedDevice: device)
        
        let wroteReporter = CPCL.generic(lifecycle)
            .pageSetup(arg: CPageSetup.build({ n in
                return CRealPageSetup(derived: n, pageWidth: 608, pageHeight: 1040)
            }))
            .image(arg: CImage.build({
                return CRealImage.init(startX: 20, startY: 20, width: 300, height: 300, image: TypeFactory.getImageData() ?? Data(), compress: false)
            }))
            .normalPrint(arg: CNormalPrint())
            .write()

        printMsg(wroteReporter)
        
    }
    
    /// 打印样本
    func sample() {
        let lifecycle = Lifecycle(connectedDevice: device)
        
        let wroteReporter = CPCL.generic(lifecycle)
            .pageSetup(arg: CPageSetup.build({ n in
                return CRealPageSetup(derived: n, pageWidth: 608, pageHeight: 1040)
            }))
            .box(arg: CBox.build({
                return CRealBox(topLeftX: 0, topLeftY: 1, bottomRightX: 598, bottomRightY: 644, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 0, startY: 88, endX: 598, endY: 88, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 0, startY: 88+128, endX: 598, endY: 88+128, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 0, startY: 88+128+80+144, endX: 598-56-16, endY: 88+128+80+144, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 0, startY: 88+128+80+144+128, endX: 598-56-16, endY: 88+128+80+144+128, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 52, startY: 88+128+80, endX: 52, endY: 88+128+80+144+128, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 598-56-16, startY: 88+128+80, endX: 598-56-16, endY: 664, lineWidth: 2)
            }))
            .bar(arg: CBar.build({ n in
                return CRealBar(derived: n, startX: 120, startY: 88+12, content: 1234567890, height: 80, codeType:.CODE128, codeRotation:.ROTATE_0)
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 120+12, textY: 88+20+76, content: "1234567890")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 12, textY: 88+128+80+32, content: "收")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 12, textY: 88+128+80+96, content: "件")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 88+128+80+144+128+16, content: "签收人/签收时间")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 430, textY: 88+128+80+144+128+36, content: "月")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 490, textY: 88+128+80+144+128+36, content: "日")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 88+128+80+24, content: "收姓名 13777777777")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 88+128+80+24+32, content: "南京市浦口区威尼斯水城七街区七街区")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 88+128+80+144+24, content: "名字 13777777777")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 88+128+80+144+24+32, content: "南京市浦口区威尼斯水城七街区七街区")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 598-56-5, textY:88+128+80+104, content: "派")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 598-56-5, textY:88+128+80+160, content: "件")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 598-56-5, textY:88+128+80+208, content: "联")
            }))
            .box(arg: CBox.build({
                return CRealBox(topLeftX: 0, topLeftY: 1, bottomRightX: 598, bottomRightY: 968, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 0, startY: 696+80, endX: 598, endY: 696+80, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 0, startY: 696+80+136, endX: 598-56-16, endY: 696+80+136, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 52, startY: 80, endX: 52, endY: 696+80+136, lineWidth: 2)
            }))
            .line(arg: CLine.build({
                return CRealLine(startX: 598-56-16, startY: 80, endX: 598-56-16, endY: 968, lineWidth: 2)
            }))
            .bar(arg: CBar.build({ n in
                return CRealBar(derived: n, startX: 320, startY: 696-4, content: 1234567890, height: 56, codeType:.CODE128, codeRotation:.ROTATE_0)
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 320+8, textY: 696+54, content: "12345678902222")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 12, textY: 696+80+35, content: "发")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 696+80+84, content: "件")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 696+80+28, content: "名字 13777777777")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 52+20, textY: 696+80+28+32, content: "南京市浦口区威尼斯水城七街区七街区")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 598-56-5, textY: 696+80+50, content: "客")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 598-56-5, textY: 696+80+82, content: "户")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 598-56-5, textY: 696+80+106, content: "联")
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 12+8, textY: 696+80+136+22-5, content: "物品：几个快递 12kg")
            }))
            .box(arg: CBox.build({
                return CRealBox(topLeftX: 598-56-16-120, topLeftY: 696+80+136+11, bottomRightX: 598-56-16-16, bottomRightY: 968-11, lineWidth: 2)
            }))
            .text(arg: CText.build({
                return CRealText(font: CFont.TSS20, rotation: .ROTATE_0, textX: 598-56-16-120+17, textY: 696+80+136+11+6, content: "已验视")
            }))
            .normalPrint(arg: CNormalPrint())
            .write()

        printMsg(wroteReporter)
    }
}
