//
//  OCDetailViewController.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/8/31.
//

import Foundation
import UIKit
import CoreBluetooth

import adapter
import ocBle


class OCDetailViewController: UIViewController {

    public var connectDevice:BLEDevice?
    
    public var type:CommandType?
    
    private var typeFactory: TypeFactory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.title = connectDevice?.deviceName()
        
        typeFactory = TypeFactory(type!, device: connectDevice!)
        
        
        // 监听
        connectDevice?.read(options: nil, callBack: { data, error in
            print("收到了\(data),error=\(error)")
        })
    }
    
    @IBAction func write(_ sender: Any) {
    }
    
    @IBAction func read(_ sender: Any) {
    }
}




