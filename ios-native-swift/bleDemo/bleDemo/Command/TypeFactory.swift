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
import toolkit


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
    
    static func getImageData() -> Data? {
        let image = UIImage.init(named: "icon2")
        
//        let data = ImagePlus.processImage4(image: image!)
        let data = image?.pngData()
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
