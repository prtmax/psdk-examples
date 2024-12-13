//#ifdef APP-PLUS
let BluetoothAdapter = plus.android.importClass("android.bluetooth.BluetoothAdapter");
let Intent = plus.android.importClass("android.content.Intent");
let IntentFilter = plus.android.importClass("android.content.IntentFilter");
let BluetoothDevice = plus.android.importClass("android.bluetooth.BluetoothDevice");
let UUID = plus.android.importClass("java.util.UUID");
let Toast = plus.android.importClass("android.widget.Toast");
//连接串口设备的 UUID
let MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

let invoke = plus.android.invoke;
let btAdapter = BluetoothAdapter.getDefaultAdapter();
let activity = plus.android.runtimeMainActivity();

let btSocket = null;
let btInStream = null;
let btOutStream = null;
let setIntervalId = 0;

let btFindReceiver = null; //蓝牙搜索广播接收器
let btStatusReceiver = null; //蓝牙状态监听广播
//#endif
/**
 * 构造对象
 */ 
var blueToothTool = {
	state : {
		bluetoothEnable: false, //蓝牙是否开启
		bluetoothState: "", //当前蓝牙状态
		discoveryDeviceState: false, //是否正在搜索蓝牙设备
		readThreadState: false, //数据读取线程状态
	},
	options : {
		/**
		 * 监听蓝牙状态回调
		 * @param {String} state
		 */
		listenBTStatusCallback: function(state) {},
		/**
		 * 搜索到新的蓝牙设备回调
		 * @param {Device} newDevice
		 */
		discoveryDeviceCallback: function(newDevice) {},
		/**
		 * 蓝牙搜索完成回调
		 */
		discoveryFinishedCallback: function() {},
		/**
		 * 接收到数据回调
		 * @param {Array} dataByteArr
		 */
		readDataCallback: function(dataByteArr) {},
		/**
		 * 蓝牙连接中断回调
		 * @param {Exception} e
		 */
		connExceptionCallback: function(e) {}
	},
	init(setOptions) {
		Object.assign(this.options, setOptions);
		this.state.bluetoothEnable = this.getBluetoothStatus();
		this.listenBluetoothStatus();
	},
	shortToast(msg) {
		Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show();
	},
	/**
	 * 是否支持蓝牙
	 * @return {boolean}
	 */
	isSupportBluetooth() {
		if(btAdapter != null) {
			return true;
		}
		return false;
	},
	/**
	 * 获取蓝牙的状态
	 * @return {boolean} 是否已开启
	 */
	getBluetoothStatus() {
		if(btAdapter != null) {
			return btAdapter.isEnabled();
		}
		return false;
	},
	/**
	 * 打开蓝牙
	 * @param activity
	 * @param requestCode
	 */
	turnOnBluetooth() {
		if(btAdapter == null) {
			shortToast("没有蓝牙");
			return;
		}
		if(!btAdapter.isEnabled()) {
			if(activity == null) {
				shortToast("未获取到activity");
				return;
			} else {
				let intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
				let requestCode = 1;
				activity.startActivityForResult(intent, requestCode);
				return;
			}
		} else {
			shortToast("蓝牙已经打开");
		}
	},
	/**
	 * 关闭蓝牙
	 */
	turnOffBluetooth() {
		if(btAdapter != null && btAdapter.isEnabled()) {
			btAdapter.disable();
		}
		if(btFindReceiver != null) {
			try {
				activity.unregisterReceiver(btFindReceiver);
			} catch(e) {

			}
			btFindReceiver = null;
		}
		this.state.bluetoothEnable = false;
		this.cancelDiscovery();
		closeBtSocket();

		if(btAdapter != null && btAdapter.isEnabled()) {
			btAdapter.disable();
			shortToast("蓝牙关闭成功");
		} else {
			shortToast("蓝牙已经关闭");
		}
	},
	/**
	 * 获取已经配对的设备
	 * @return {Array} connetedDevices
	 */
	getPairedDevices() {
		let pairedDevices = [];

		//蓝牙连接android原生对象，是一个set集合
		let pairedDevicesAndroid = null;
		if(btAdapter != null && btAdapter.isEnabled()) {
			pairedDevicesAndroid = btAdapter.getBondedDevices();
		} else {
			shortToast("蓝牙未开启");
		}

		if(!pairedDevicesAndroid) {
			return pairedDevices;
		}

		//遍历连接设备的set集合，转换为js数组
		let it = invoke(pairedDevicesAndroid, "iterator");
		while(invoke(it, "hasNext")) {
			let device = invoke(it, "next");
			pairedDevices.push({
				"name": invoke(device, "getName"),
				"address": invoke(device, "getAddress")
			});
		}
		return pairedDevices;
	},
	/**
	 * 发现设备
	 */
	discoveryNewDevice() {
		if(btFindReceiver != null) {
			try {
				activity.unregisterReceiver(btFindReceiver);
			} catch(e) {
				console.error(e);
			}
			btFindReceiver = null;
			this.cancelDiscovery();
		}
		let Build = plus.android.importClass("android.os.Build");
		
		 //6.0以后的如果需要利用本机查找周围的wifi和蓝牙设备, 申请权限
        if(Build.VERSION.SDK_INT >= 6.0){
			
        }
		let options = this.options
		btFindReceiver = plus.android.implements("io.dcloud.android.content.BroadcastReceiver", {
			"onReceive": function(context, intent) {
				plus.android.importClass(context);
				plus.android.importClass(intent);
				let action = intent.getAction();

				if(BluetoothDevice.ACTION_FOUND == action) { // 找到设备
					let device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
					let newDevice = {
						"name": plus.android.invoke(device, "getName"),
						"address": plus.android.invoke(device, "getAddress")
					}
					options.discoveryDeviceCallback && options.discoveryDeviceCallback(newDevice);
				}
				if(BluetoothAdapter.ACTION_DISCOVERY_FINISHED == action) { // 搜索完成
					cancelDiscovery();
					options.discoveryFinishedCallback && options.discoveryFinishedCallback();
				}
			}
		});
		let filter = new IntentFilter();
		filter.addAction(BluetoothDevice.ACTION_FOUND);
		filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
		activity.registerReceiver(btFindReceiver, filter);
		btAdapter.startDiscovery(); //开启搜索
		this.state.discoveryDeviceState = true;
	},
	/**
	 * 蓝牙状态监听
	 * @param {Activity} activity
	 */
	listenBluetoothStatus() {
		if(btStatusReceiver != null) {
			try {
				activity.unregisterReceiver(btStatusReceiver);
			} catch(e) {
				console.error(e);
			}
			btStatusReceiver = null;
		}
		btStatusReceiver = plus.android.implements("io.dcloud.android.content.BroadcastReceiver", {
			"onReceive": (context, intent)=> {
				plus.android.importClass(context);
				plus.android.importClass(intent);

				let action = intent.getAction();
				switch(action) {
					case BluetoothAdapter.ACTION_STATE_CHANGED:
						let blueState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, 0);
						let stateStr = "";
						switch(blueState) {
							case BluetoothAdapter.STATE_TURNING_ON:
								stateStr = "STATE_TURNING_ON";
								break;
							case BluetoothAdapter.STATE_ON:
								this.state.bluetoothEnable = true;
								stateStr = "STATE_ON";
								break;
							case BluetoothAdapter.STATE_TURNING_OFF:
								stateStr = "STATE_TURNING_OFF";
								break;
							case BluetoothAdapter.STATE_OFF:
								stateStr = "STATE_OFF";
								this.state.bluetoothEnable = false;
								break;
						}
						this.state.bluetoothState = stateStr;
						this.options.listenBTStatusCallback && this.options.listenBTStatusCallback(stateStr);
						break;
				}
			}
		});
		let filter = new IntentFilter();
		filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
		activity.registerReceiver(btStatusReceiver, filter);
		// 首次连接 状态回调
		if(this.state.bluetoothEnable) {
			this.options.listenBTStatusCallback && this.options.listenBTStatusCallback('STATE_ON');
		}
	},
	/**
	 * 根据蓝牙地址，连接设备
	 * @param {Stirng} address
	 * @return {Boolean}
	 */
	connDevice(address, callback) {
		let InputStream = plus.android.importClass("java.io.InputStream");
		let OutputStream = plus.android.importClass("java.io.OutputStream");
		let BluetoothSocket = plus.android.importClass("android.bluetooth.BluetoothSocket");

		this.cancelDiscovery();
		if(btSocket != null) {
			this.closeBtSocket();
		}
		this.state.readThreadState = false;

		try {
			let device = invoke(btAdapter, "getRemoteDevice", address);
			btSocket = invoke(device, "createRfcommSocketToServiceRecord", MY_UUID);
		} catch(e) {
			console.error(e);
			shortToast("连接失败，获取Socket失败！");
			callback(false)
			return false;
		}
		try {
			invoke(btSocket, "connect");
			if(!btSocket.isConnected()){
				this.shortToast("连接失败");
				callback(false)
				try {
					btSocket.close();
					btSocket = null;
				} catch(e1) {
					console.error(e1);
				}
				return false;
			}
			this.readData(); //读数据
			this.shortToast("连接成功");
			callback(true)
		} catch(e) {
			console.error(e);
			this.shortToast("连接失败");
			callback(false)
			try {
				btSocket.close();
				btSocket = null;
			} catch(e1) {
				console.error(e1);
			}
			return false;
		}
		return true;
	},
	/**
	 * 断开连接设备
	 * @param {Object} address
	 * @return {Boolean}
	 */
	disConnDevice() {
		if(btSocket != null) {
			this.closeBtSocket();
		}
		this.state.readThreadState = false;
		this.shortToast("断开连接成功");
	},
	/**
	 * 断开连接设备
	 * @param {Object} address
	 * @return {Boolean}
	 */
	closeBtSocket() {
		this.state.readThreadState = false;
		if(!btSocket) {
			return;
		}
		try {
			btSocket.close();
		} catch(e) {
			console.error(e);
			btSocket = null;
		}
	},
	/**
	 * 取消发现
	 */
	cancelDiscovery() {
		if(btAdapter.isDiscovering()) {
			btAdapter.cancelDiscovery();
		}
		if(btFindReceiver != null) {
			activity.unregisterReceiver(btFindReceiver);
			btFindReceiver = null;
		}
		this.state.discoveryDeviceState = false;
	},
	/**
	 * 读取数据
	 * @param {Object} activity
	 * @param {Function} callback
	 * @return {Boolean}
	 */
	readData() {
		if(!btSocket) {
			this.shortToast("请先连接蓝牙设备！");
			return false;
		}
		try {
			btInStream = invoke(btSocket, "getInputStream");
			btOutStream = invoke(btSocket, "getOutputStream");
		} catch(e) {
			console.error(e);
			this.shortToast("创建输入输出流失败！");
			this.closeBtSocket();
			return false;
		}
		this.read();
		this.state.readThreadState = true;
		return true;
	},
	/**
	 * 模拟java多线程读取数据
	 */
	read() {
		let setTimeCount = 0;
		clearInterval(setIntervalId);
		setIntervalId = setInterval(()=> {
			setTimeCount++;
			if(this.state.readThreadState) {
				let t = new Date().getTime();
				//心跳检测
				if(setTimeCount % 20 == 0) {
					try {
						btOutStream.write([0b00]);
					} catch(e) {
						this.state.readThreadState = false;
						this.options.connExceptionCallback && this.options.connExceptionCallback(e);
					}
				}
				let dataArr = [];
				while(invoke(btInStream, "available") !== 0) {
					let data = invoke(btInStream, "read");
					dataArr.push(data);
					let ct = new Date().getTime();
					if(ct - t > 100) {
						break;
					}
				}
				if(dataArr.length > 0) {
					this.options.readDataCallback && this.options.readDataCallback(dataArr);
				}
			}
		}, 40);
	},
	/**
	 * 发送数据
	 * @param {String} dataStr
	 * @return {Boolean}
	 */
	sendData(dataStr) {
		if(!btOutStream) {
			this.shortToast("创建输出流失败！");
			return;
		}
		let bytes = invoke(dataStr, 'getBytes', 'gbk');
		try {
			btOutStream.write(bytes);
		} catch(e) {
			return false;
		}
		return true;
	},
	sendByteData(byteData) {
		if(!btOutStream) {
			this.shortToast("创建输出流失败！");
			return;
		}
		try {
			btOutStream.write(byteData);
		} catch(e) {
			return false;
		}
		return true;
	}
}

module.exports = blueToothTool