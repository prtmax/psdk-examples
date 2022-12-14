//
//  TestViewController.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/9/1.
//

import UIKit
import CoreBluetooth

import appleBle




class TestViewController: UIViewController {

    private var textView: UITextView!
    
    private var selectItem: EventName = .name

    private var tableView: UITableView!
    
    private var typeFactory: TypeFactory?

    public var connectDevice:BLEDevice?
        
    public var type:CommandType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.navigationItem.title = connectDevice?.deviceName()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "暂无", style: .done, target: self, action:#selector(rightBarButtonClick))
        
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 100), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        textView = UITextView.init(frame: CGRect(x:0 , y: UIScreen.main.bounds.size.height - 100, width: UIScreen.main.bounds.size.width, height: 100))
        textView.backgroundColor = UIColor.lightGray
        textView.isUserInteractionEnabled = false
        textView.font = UIFont.systemFont(ofSize: 20)
        self.view.addSubview(textView)
        
        
        typeFactory = TypeFactory(type!, device: connectDevice!)
        connectDevice?.connectedCharacteristic = BLEManager.shared.writeCh

        // 监听
        connectDevice?.read(options: nil, callBack: { data, error in
            
            guard let data = data else {
                return
            }
            
            let bytes = [UInt8](data)
            
            let str = data.dataToString()
            switch self.selectItem {

            case .status:
                // * 0:打印机正常
                // * 其他（根据"位"判断打印机状态）
                // * 第0位：1：正在打印
                // * 第1位：1：纸舱盖开
                // * 第2位：1：缺纸
                // * 第3位：1：电池电压低
                // * 第4位：1：打印头过热
                // * 第5位：缺省（默认0）
                // * 第6位：缺省（默认0）
                // * 第7位：缺省（默认0）
                self.textView.text = "状态: \(bytes[0])"
                print("查询打印机状态")
            case .batteryVolume:
                self.textView.text = "电量: \(bytes[1])"
                print("查询电量")
            case .name:
                self.textView.text = "蓝牙名称: \(str)"
                print("蓝牙名称")
            case .mac:
                self.textView.text = "蓝牙mac地址: \(data.dataToHexString())"
                print("查询MAC地址")
            case .printerVersion:
                self.textView.text = "打印机固件版本: \(str)"
                print("打印机固件版本")
            case .SN:
                self.textView.text = "打印机SN: \(str)"
                print("查询打印机SN")
            case .model:
                self.textView.text = "打印机型号: \(str)"
                print("查询打印机型号")
            case .thickness:
                self.textView.text = "设置浓度: \(str)"
                print("设置浓度")
            case .getShutdownTime:
                self.textView.text = "获取成功: \(str)"
                print("获取关机时间的标志")
            default: break
            }
        })
    }
}

extension TestViewController{
    
    @objc func rightBarButtonClick() {
        

    }
}


extension TestViewController: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typeFactory?.commandList().count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil{
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
        }

        let array = typeFactory?.commandList()
        
        let event = array![indexPath.row]
        
        cell?.textLabel?.text = event.rawValue
        
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let array = typeFactory?.commandList()
        
        let event = array![indexPath.row]
        
        selectItem = event
        
        typeFactory?.startAction(event: event)
    }

}
