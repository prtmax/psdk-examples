//
//  CommandType.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/9/1.
//

import Foundation
import adapter
import father

protocol TypeC{

    var device : ConnectedDevice   {set get}
    
    func commandList() -> Array<EventName>
    
    func startAction(event:EventName)
    
    func printMsg(_ reporter: WroteReporter)
}

extension TypeC{
    func commandList() -> Array<EventName> {
        return Array()
    }
    
    func printMsg(_ reporter: WroteReporter) {
        if reporter.ok {
            print("reporter信息:\n")
            print("=====>返回成功\n")
            let str = String(data:reporter.binary, encoding: String.Encoding.utf8)
            print(str ?? "")
        }else{
            print("reporter信息:\n")
            print("=====>返回失败\n")
            let str = reporter.exception.debugDescription
            print(str)
        }
    }
}

enum EventName:String{
    case backLineDot = "回纸命令"
    case batteryVolume = "查询电量"
    case getShutdownTime = "获取关机时间"
    case lineDot = "走纸命令"
    case mac = "查询MAC"
    case model = "查询打印机型号"
    case name = "查询蓝牙名称"
    case printerVersion = "查询打印机固件版本"
    case SN = "查询打印机SN"
    case status = "查询打印机状态"
    case thickness = "设置打印机浓度"
    
    case barCode = "条形码"
    case qrcode = "二维码"
    case box = "画线(只能画横竖线)"
    case cycle = "画圆"
    case line = "画线"
    
    case image = "打印图片"
    case sample = "综合案例"
    
}



