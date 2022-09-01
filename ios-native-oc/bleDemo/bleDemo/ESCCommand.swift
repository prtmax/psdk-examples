//
//  ESCCommand.swift
//  bleDemo
//
//  Created by 蔡亚超 on 2022/9/1.
//

import UIKit

import adapter
import father

import esc


class ESCCommand : TypeC{
    var device: ConnectedDevice
    
    init(_ device:ConnectedDevice) {
        self.device = device
    }
    
    func commandList() ->Array<EventName>{
        return [.backLineDot,.batteryVolume,.getShutdownTime,.lineDot,.mac,.model,.name,.printerVersion,.SN,.status,.thickness,.line,.image]
    }
    
    func startAction(event:EventName) {
        switch event {
        case .backLineDot:
            backLineDot()
        case .batteryVolume:
            batteryVolume()
        case .getShutdownTime:
            getShutdownTime()
        case .lineDot:
            lineDot()
        case .mac:
            mac()
        case .model:
            model()
        case .name:
            name()
        case .printerVersion:
            printerVersion()
        case .SN:
            SN()
        case .status:
            status()
        case .thickness:
            thickness()
        case .line:
            line()
        case .image:
            image()
        default:
            break
        }
    }
}


extension ESCCommand{
    
    /**
     * 回纸命令
     * @param dot 走纸点行
     * @return
     */
    public func backLineDot(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).backLineDot(dot: 1).write()
        printMsg(wroteReporter)
    }
    
    /**
     * 查询电量
     */
    public func batteryVolume(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).batteryVolume().write()
        printMsg(wroteReporter)
    }
    
    /**
     * 获取关机时间 (单位：分钟，不接受小数)，结果在bleDataReceived中，返回两个字节，高位在前低位在后，单位为分钟
     */
    public func getShutdownTime(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).getShutdownTime().write()
        printMsg(wroteReporter)
    }
    
    
    /**
     * 走纸命令
     * @param dot 走纸点行
     */
    public func lineDot(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).lineDot(dot: 1).write()
        printMsg(wroteReporter)
    }
    
    /**
     *查询MAC
     */
    public func mac() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).mac().write()
        printMsg(wroteReporter)
    }
    
    /**
     *查询打印机型号
     */
    public func model() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).model().write()
        printMsg(wroteReporter)
    }
    
    /**
     *查询蓝牙名称
     */
    public func name() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).name().write()
        printMsg(wroteReporter)
    }
    
    /**
     * 查询打印机固件版本
     */
    public func printerVersion() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).printerVersion().write()
        printMsg(wroteReporter)
    }
    
    /**
     * 设置关机时间(单位：分钟，不接受小数)
     */
    public func setShutdownTime(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).setShutdownTime(time: 1).write()
        printMsg(wroteReporter)
    }
    
    /**
     * 查询打印机SN
     */
    public func SN(){
        
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).SN().write()
        printMsg(wroteReporter)
    }
    
    /**
     *查询打印机状态
     */
    public func status() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).status().write()
        printMsg(wroteReporter)
    }
    
    /**
     * 设置打印机浓度(0-2)
     * @param thickness 0:低浓度 1:中浓度 2:高浓度
     */
    public func thickness() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).thickness(thickness: 2).write()
        printMsg(wroteReporter)
    }
    
    /**
     *查询蓝牙固件版本
     */
    public func version(){
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle).version().write()
        printMsg(wroteReporter)
    }
    
    /**
     *画线
     */
    public func line() {
        let lifecycle = Lifecycle(connectedDevice: device)
        let wroteReporter = ESC.generic(lifecycle)
            .line(arg: ELine.build({
            ERealLine(x: 10, y: 10)
        })).write()
        printMsg(wroteReporter)
    }
  
    /**
     *打印图片
     */
    public func image() {
        let lifecycle = Lifecycle(connectedDevice: device)
        
        let wroteReporter = ESC.generic(lifecycle).paperType(arg: EPaperType.build({
            return ERealPaperType(type: .CONTINUOUS_REEL_PAPER)
        }))
            .image(arg: EImage.build({
                return ERealImage(image: UIImage.init(named: "icon2")!, width: 30, height: 30, compress: true)
            }))
            .write()
        printMsg(wroteReporter)
    }
}
