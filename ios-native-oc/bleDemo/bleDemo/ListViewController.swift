//
//  ListViewController.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/8/31.
//

import Foundation

import CoreBluetooth

import ocBle
import adapter
import ocBle


enum ButtonTitle: String{
    case start = "开始扫描"
    case stop = "停止扫描"
    case reStart = "重新扫描"
}


class ListViewController: UIViewController {

    private var tableView: UITableView!
    
    private var bleArray = Array<CBPeripheral>()
        
    private var buttonTitle: ButtonTitle = .start{
        willSet{
            self.navigationItem.rightBarButtonItem?.title = newValue.rawValue
        }
    }
    
    private var bleManager: BLEIntent = BLEIntent.shared
    
    private var connectDevice:BLEDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.navigationItem.title = "蓝牙列表"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: buttonTitle.rawValue, style: .done, target: self, action:#selector(rightBarButtonClick))
        
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        
        bleManager.delegate = self

    }
}

extension ListViewController{
    
    @objc func rightBarButtonClick() {
        
        switch buttonTitle{
        case .start:
            
            bleManager.startScan()
            buttonTitle = .stop
            
        case .stop:
            
            bleManager.stopScan()
            buttonTitle = .reStart
            
        case .reStart:
            
            bleArray.removeAll()
            bleManager.startScan()
            buttonTitle = .stop
        }
    }

}


extension ListViewController: BLEIntentDelegate {
    func didUpdate(_ state: BLEState) {
        print("\(state)")
    }
    
    func didDiscover(for peripheral: CBPeripheral) {
        update(peripheral)
    }
    
    func didConnect(for device: ConnectedDevice) {
        connectDevice = device as! BLEDevice
        print("连接成功")

        let isOn = bleManager.startService("FF00", peripheral: connectDevice!.perpheral)
        print("\(isOn)")
    }
    
    func didFail(toConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败")
    }
    
    func didDisconnect(for peripheral: CBPeripheral, error: Error?) {
        print("连接断开")
    }
    
    func didServicesFound(_ peripheral: CBPeripheral, services: Array<CBService>?) {
        print("发现服务")

    }
    
    func bleGattService(_ service: BLEGATTService, didStart result: Bool) {
        if result{
            print("开启服务成功")
            
            self.navigationItem.title = "蓝牙列表"
            let alert = UIAlertController.init(title: "连接成功", message: "请选择打印机类型", preferredStyle: .actionSheet)
            
            let escAction = UIAlertAction.init(title: "ESC", style: .destructive, handler: { action in
                self.goToDetailVC(.ESC)
            })
            let tsplAction = UIAlertAction.init(title: "TSPL", style: .destructive, handler: { action in
                self.goToDetailVC(.TSPL)
            })
            
            let cpclAction = UIAlertAction.init(title: "CPCL", style: .destructive, handler: { action in
                self.goToDetailVC(.CPCL)
            })
            
            alert.addAction(escAction)
            alert.addAction(tsplAction)
            alert.addAction(cpclAction)

            self.present(alert, animated: true)
            
        }else{
            print("开启服务失败")
        }
    }
    
    func bleGattService(_ service: BLEGATTService, didFlowControl credit: Int32, withMtu mtu: Int32) {
        
    }
    

    
    
    func goToDetailVC(_ type: CommandType) -> Void {
//        let sb = UIStoryboard.init(name: "Main", bundle: nil)
//
//        let detailVC = sb.instantiateViewController(identifier: "OCDetailViewController") as! OCDetailViewController
//        detailVC.connectDevice = self.connectDevice
//        detailVC.type = type
//
//        self.navigationController?.pushViewController(detailVC, animated: true)
        
        let testVc = TestViewController()
        testVc.connectDevice = self.connectDevice
        testVc.type = type
        self.navigationController?.pushViewController(testVc, animated: true)
        
    }
}



extension ListViewController: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil{
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
        }

        let device = bleArray[indexPath.row]

        cell?.textLabel?.text = device.name
        cell?.detailTextLabel?.text = device.identifier.uuidString
        
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = bleArray[indexPath.row]

        bleManager.stopScan()
        

        bleManager.connect(device)
        
        self.navigationItem.title = "正在连接...";
        
    }
}


extension ListViewController{
    
    
    
    func update(_ peripheral:CBPeripheral) -> Void {
        
        if bleArray.contains(peripheral){
            return
        }
        bleArray.append(peripheral)
        tableView.reloadData()
    }
    

}
