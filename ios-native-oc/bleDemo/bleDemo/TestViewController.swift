//
//  TestViewController.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/9/1.
//

import Foundation
import CoreBluetooth

import ocBle




class TestViewController: UIViewController {

    private var tableView: UITableView!
    
    private var typeFactory: TypeFactory?

    public var connectDevice:BLEDevice?
        
    public var type:CommandType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.navigationItem.title = connectDevice?.deviceName()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "暂无", style: .done, target: self, action:#selector(rightBarButtonClick))
        
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        
        typeFactory = TypeFactory(type!, device: connectDevice!)
        
        // 监听
        connectDevice?.read(options: nil, callBack: { data, error in
            
            let errorString = String(describing: error)
            let dataString = String(data:data ?? Data(), encoding: String.Encoding.utf8)
            
            print("收到了打印机回调信息：\nData===>:\n\(dataString),error===>\n\(errorString)")
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
        
        typeFactory?.startAction(event: event)
    }
}

