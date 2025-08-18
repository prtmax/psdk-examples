package main

import (
	"fmt"
	"log"
	"time"

	"psdk/frame/device/adapter/basic"
	"psdk/frame/device/bluetooth/manager"
	"psdk/frame/device/bluetooth/types"
	"psdk/fruits/tspl"

	tsplTypes "psdk/fruits/tspl/types"
)

func main() {
	fmt.Println("🚀 开始PSDK Go Demo - TSPL蓝牙打印测试")
	fmt.Println("===========================================")

	// 1. 初始化蓝牙管理器
	fmt.Println("📱 初始化蓝牙管理器...")
	bm := manager.GetInstance()
	err := bm.Initialize()
	if err != nil {
		log.Fatalf("❌ 蓝牙管理器初始化失败: %v", err)
	}
	fmt.Println("✅ 蓝牙管理器初始化成功")

	// 2. 设置目标打印机设备
	targetDevice := &types.BluetoothDevice{
		Address: "E0:6E:41:81:98:6D", // 请替换为实际的打印机MAC地址
	}
	fmt.Printf("📱 目标设备: %s\n", targetDevice.Address)

	// 3. 创建简单的连接监听器
	var connected bool
	listener := &SimpleListener{connected: &connected}

	// 4. 创建蓝牙连接
	fmt.Println("🔗 创建蓝牙连接...")
	conn, err := bm.CreateConnection(targetDevice, listener)
	if err != nil {
		log.Printf("⚠️  创建连接失败，继续演示命令生成: %v", err)
	} else {
		fmt.Println("✅ 连接对象创建成功")

		// 5. 尝试连接到设备
		fmt.Println("🔗 尝试连接到打印机...")
		err = conn.Connect(types.ServiceUUID)
		if err != nil {
			fmt.Printf("⚠️  连接失败，但继续演示命令生成: %v\n", err)
		} else {
			time.Sleep(time.Second * 2) // 等待连接建立
			if connected {
				fmt.Println("✅ 蓝牙连接成功！")
			}
		}
	}

	// 6. 创建TSPL打印实例
	fmt.Println("🖨️  创建TSPL打印实例...")
	tsplPrinter := tspl.Generic(conn)
	fmt.Println("✅ TSPL打印实例创建成功")

	// 7. 构建TSPL打印命令（使用快捷方法）
	fmt.Println("📝 构建TSPL打印命令（使用快捷方法）...")

	// 清理指令缓存
	tsplPrinter.Clear()

	tsplPrinter.
		SetSize(4, 6).     // 设定页面大小
		SetDirection(0).   // 设定打印方向
		SetGap(0.08, 0.0). // 设定标签间距
		SetSpeed(6).       // 设定打印速度
		SetDensity(6)      // 设定打印浓度

	tsplPrinter.
		AddBarCode(10, 10, "128", "1234567890", 90).                    // 添加条码
		AddTextWithMulti(10, 160, "TEST PRINT", tsplTypes.TSS24, 3, 3). // 添加文字（带放大）
		AddCircle(10, 260, 60, 6).                                      // 添加圆形
		AddQRCodeWithLevel(10, 330, "www.qrprt.com", 4, "H").           // 添加二维码（带纠错等级）
		PrintSingle().                                                  // 打印单份
		Cut()                                                           // 切纸

	fmt.Println("✅ TSPL命令构建完成")

	// 8. 显示生成的命令
	fmt.Println("📋 生成的TSPL命令:")
	fmt.Println("=====================================")
	commandString := tsplPrinter.String()
	fmt.Println(commandString)
	fmt.Println("=====================================")

	// 显示十六进制数据
	hexString := tsplPrinter.Hex()
	fmt.Printf("🔢 十六进制数据: %s\n", hexString)

	// 显示二进制数据长度
	binaryData := tsplPrinter.Binary()
	fmt.Printf("📦 二进制数据长度: %d bytes\n", len(binaryData))

	// 9. 执行打印
	fmt.Println("🖨️  执行打印命令...")
	err = tsplPrinter.Execute()
	if err != nil {
		fmt.Printf("⚠️  打印执行失败（如果设备未连接这是正常的）: %v\n", err)
	} else {
		fmt.Println("✅ 打印命令执行成功！")
		fmt.Println("📄 请检查打印机是否输出了测试标签")

		// 10. 读取打印机返回数据
		fmt.Println("📖 读取打印机返回数据...")
		time.Sleep(200 * time.Millisecond) // 等待打印机处理

		if conn != nil {
			data, err := conn.Read()
			if err != nil {
				fmt.Printf("⚠️  读取数据失败: %v\n", err)
			} else if len(data) == 0 {
				fmt.Println("📭 没有接收到打印机返回数据")
			} else {
				// 转换为十六进制显示（对应Java的HexOutput.simple().format(bytes)）
				hexOutput := fmt.Sprintf("%X", data)
				fmt.Printf("📨 打印机返回数据 (hex): %s\n", hexOutput)
			}
		}
	}

	// 11. 清理资源
	fmt.Println("🧹 清理资源...")
	if conn != nil {
		err = conn.Release()
		if err != nil {
			fmt.Printf("⚠️  释放连接失败: %v\n", err)
		}
	}
	fmt.Println("✅ 资源清理完成")

	fmt.Println("🎉 PSDK Go Demo 完成！")
}

// SimpleListener 简单的连接监听器
type SimpleListener struct {
	connected *bool
}

// OnConnectSuccess 连接成功回调
func (l *SimpleListener) OnConnectSuccess(device basic.ConnectedDevice) {
	*l.connected = true
	fmt.Printf("✅ 蓝牙连接成功: %s\n", device.DeviceName())
}

// OnConnectFail 连接失败回调
func (l *SimpleListener) OnConnectFail(message string, err error) {
	*l.connected = false
	fmt.Printf("❌ 蓝牙连接失败: %s, 错误: %v\n", message, err)
}

// OnConnectionStateChanged 连接状态变更回调
func (l *SimpleListener) OnConnectionStateChanged(device *types.BluetoothDevice, state types.ConnectionState) {
	fmt.Printf("🔄 连接状态变更: %s -> %s\n", device.Name, state.String())
}
