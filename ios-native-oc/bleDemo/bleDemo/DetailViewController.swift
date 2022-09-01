//
//  DetailViewController.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/8/26.
//

import Foundation
import UIKit
import CoreBluetooth

import adapter
import appleBle


class DetailViewController: UIViewController {

    public var connectDevice:BLEDevice?
    
    public var type:CommandType?
    
    private var typeFactory: TypeFactory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.title = connectDevice?.deviceName()
        // 设置特征
        connectDevice?.connectedCharacteristic = getWriteByYourSelf()
        // 写入类型的工厂方法
        typeFactory = TypeFactory(type!, device: connectDevice!)
        
        
        // 监听
        connectDevice?.read(options: nil, callBack: { data, error in
            print("收到了\(data),error=\(error)")
        })
    }
    
    @IBAction func write(_ sender: Any) {
        writeAction()
    }
    
    @IBAction func read(_ sender: Any) {
        readAction()
    }
}


extension DetailViewController{
    
    func writeAction() {
        //
        typeFactory?.commonWrite()
    }
    
    
    func readAction() {
        typeFactory?.commonRead()
    }
    
    
    // 根据自己的需要选择对应的特征
    func getWriteByYourSelf() -> CBCharacteristic?{

        var char : CBCharacteristic?
        for service in connectDevice?.perpheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                if characteristic.properties.contains(.write){
                    char = characteristic
                    return char
                }
            }
        }
        return nil
    }
    
    
    func getReadByYourSelf() -> CBCharacteristic?{

        var char : CBCharacteristic?
        for service in connectDevice?.perpheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                if characteristic.properties.contains(.read)&&characteristic.properties.contains(.write){
                    char = characteristic
                    return char
                }
            }
        }
        return nil
    }
}


