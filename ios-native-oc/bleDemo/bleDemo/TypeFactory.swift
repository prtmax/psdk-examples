//
//  TypeFactory.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/8/29.
//

import UIKit

import cpcl
import esc
import tspl


import adapter
import father


enum CommandType {
    case ESC
    case TSPL
    case CPCL
}


class TypeFactory{
    
    private var type:CommandType = .ESC
    private var device:ConnectedDevice
    
    private var innerCommand: TypeC?

    
    init(_ type: CommandType,device:ConnectedDevice) {
        self.type = type
        self.device = device
        
        creatInnerCommand()
    }
    
    func creatInnerCommand(){
        switch type {
        case .ESC:
            innerCommand = ESCCommand(device)
        case .TSPL:
            innerCommand = TSPLCommand(device)
        case .CPCL:
            innerCommand = CPCLCommand(device)
        }
    }

    func startAction(event:EventName){
        innerCommand?.startAction(event: event)
    }
    
    func commandList() -> Array<EventName> {
        innerCommand?.commandList() ?? []
    }

}

extension TypeFactory{
    
    func escWrite() -> Void {
        let lifecycle = Lifecycle(connectedDevice: device)
        
        let wroteReporter = ESC.generic(lifecycle).paperType(arg: EPaperType.build({
            return ERealPaperType(type: .CONTINUOUS_REEL_PAPER)
        }))
            .line(arg: ELine.build({
                return ERealLine(x: 0, y: 100)
            }))
            .line(arg: ELine.build({
                return ERealLine(x: 50, y: 50)
            }))
            .lineDot(dot: 5)
//            .image(arg: EImage.build({
//                return ERealImage(image: UIImage.init(named: "icon2")!, width: 30, height: 30, compress: true)
//            }))
            .write()
        
        if wroteReporter.ok {
            let str = String(data: wroteReporter.binary, encoding: String.Encoding.utf8)
            print(str ?? "")
        }
    }
    
    
    func escRead() {
        
        let lifecycle = Lifecycle(connectedDevice: device)
        
        let string = ESC.generic(lifecycle).mac().command()
            .hex(output: HexOutput(format: true))
        print(string)

        let wroteReporter = ESC.generic(lifecycle).mac().write()
        
        if wroteReporter.ok {
            let str = String(data: Data(wroteReporter.binary), encoding: String.Encoding.utf8)
            print(str ?? "")
        }
    }
}


extension TypeFactory{
    
    static func getImageData() -> Data? {
        let image = UIImage.init(named: "icon2")
        let data = image?.jpegData(compressionQuality: 0.02)
        return data ?? nil
    }
}


extension Data {
    func dataToString() -> String {
        return String(data: self, encoding: String.Encoding.utf8) ?? ""
    }
    
    func dataToHexString() -> String {
        return map { String(format: "%02x", $0) }
            .joined(separator: "")
    }
}
