/**
 * 初始化参数
 */
//#ifdef APP-PLUS
let UsbManager = plus.android.importClass("android.hardware.usb.UsbManager");
let IntentFilter = plus.android.importClass("android.content.IntentFilter");
let PendingIntent = plus.android.importClass("android.app.PendingIntent");
let UsbConstants = plus.android.importClass("android.hardware.usb.UsbConstants");
let UsbInterface = plus.android.importClass("android.hardware.usb.UsbInterface");
let Intent = plus.android.importClass("android.content.Intent");
let Context = plus.android.importClass("android.content.Context");
let HashMap = plus.android.importClass("java.util.HashMap");
let Toast = plus.android.importClass("android.widget.Toast");

let invoke = plus.android.invoke;
let activity = plus.android.runtimeMainActivity();
const VIDQR = 0x09C5;
const VIDMY = 0x09C6;
const VIDIP = 0x353D;
const deviceList = []
let mPermissionIntent = null
let mUsbManager = null
let currentDevice = null
let mUsbDeviceConnection = null
let mUsbInterface = null
let mUsbEndpointIn = null
let mUsbEndpointOut = null
let usbStatusReceiver = null; //usb状态监听广播
let isOpen = false;
//#endif
/**
 * 构造对象
 */
var usbTool = {
	state: {
		USBState: "",
		readThreadState: false, //数据读取线程状态
	},
	options: {
		/**
		 * 监听USB状态回调
		 * @param {String} state
		 */
		listenUSBStatusCallback: function(state) {},
		/**
		 * 接收到数据回调
		 * @param {Array} dataByteArr
		 */
		readDataCallback: function(dataByteArr) {},
	},
	init(setOptions) {
		Object.assign(this.options, setOptions);
		this.listenUsbStatus();
		mUsbManager = activity.getSystemService(Context.USB_SERVICE)
		mPermissionIntent = PendingIntent.getBroadcast(activity, 0, new Intent(
				'com.application.usbhost.USB_PERMISSION'), PendingIntent
			.FLAG_IMMUTABLE);
	},
	shortToast(msg) {
		Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show();
	},
	// 打开设备
	async openUsb() {
		let mDevices = new HashMap();
		mDevices = mUsbManager.getDeviceList();
		if (mDevices === null) return false;
		const devicesSize = invoke(mDevices, "size"); //获取几个长度
		if (devicesSize === 0) return false;
		const values = invoke(mDevices, "values")
		const iterator = invoke(values, "iterator");
		while (invoke(iterator, "hasNext")) {
			const device = invoke(iterator, "next");
			const vendorId = invoke(device, "getVendorId"); // 获取vendorId
			if ((vendorId == VIDQR) || (vendorId == VIDMY) || (vendorId == VIDIP)) {
				currentDevice = device;
				if (!mUsbManager.hasPermission(currentDevice)) {
					// 获取权限弹框
					mUsbManager.requestPermission(currentDevice, mPermissionIntent)
					for (let i = 10; i > 0; i--) {
						await this.delay(1000);
						if (i == 1 && !mUsbManager.hasPermission(currentDevice)) {
							return false;
						}
						if (mUsbManager.hasPermission(currentDevice)) {
							break;
						}
					}
				}
				if (this.initCommunication(currentDevice, UsbConstants.USB_CLASS_PRINTER)) {
					return true;
				}
			}
		}
		return false;
	},
	delay(ms) {
		return new Promise(resolve => setTimeout(resolve, ms));
	},
	initCommunication(device, type) {
		const interfaceCount = invoke(device, "getInterfaceCount"); //获取接口数量
		for (let interfaceIndex = 0; interfaceIndex < interfaceCount; interfaceIndex++) {
			const usbInterface = invoke(device, "getInterface", interfaceIndex); // 遍历获取接口
			const interfaceClass = invoke(usbInterface, "getInterfaceClass");
			if (type != interfaceClass) {
				continue;
			}
			mUsbInterface = usbInterface;
			for (let i = 0; i < invoke(usbInterface, "getEndpointCount"); i++) {
				const ep = invoke(usbInterface, "getEndpoint", i);
				if (invoke(ep, "getType") == UsbConstants.USB_ENDPOINT_XFER_BULK) {
					if (invoke(ep, "getDirection") == UsbConstants.USB_DIR_OUT) {
						mUsbEndpointOut = ep;
					} else if (invoke(ep, "getDirection") == UsbConstants.USB_DIR_IN) {
						mUsbEndpointIn = ep;
					}
				}
			}
			if ((null == mUsbEndpointIn) || (null == mUsbEndpointOut)) {
				mUsbEndpointIn = null;
				mUsbEndpointOut = null;
				isOpen = false;
				return false;
			} else {
				if (!mUsbManager.hasPermission(currentDevice)) {
					isOpen = false;
					return false;
				} else {
					isOpen = true;
					return true;
				}
			}
		}
		return false;
	},
	/**
	 * usb状态监听
	 * @param {Activity} activity
	 */
	listenUsbStatus() {
		if (usbStatusReceiver != null) {
			try {
				activity.unregisterReceiver(usbStatusReceiver);
			} catch (e) {
				console.error(e);
			}
			usbStatusReceiver = null;
		}
		usbStatusReceiver = plus.android.implements("io.dcloud.android.content.BroadcastReceiver", {
			"onReceive": (context, intent) => {
				plus.android.importClass(context);
				plus.android.importClass(intent);

				let action = intent.getAction();
				switch (action) {
					case UsbManager.ACTION_USB_DEVICE_ATTACHED:
						this.options.listenUSBStatusCallback && this.options.listenUSBStatusCallback(
							'ACTION_USB_DEVICE_ATTACHED');
						break;
					case UsbManager.ACTION_USB_DEVICE_DETACHED:
						isOpen = false;
						this.options.listenUSBStatusCallback && this.options.listenUSBStatusCallback(
							'ACTION_USB_DEVICE_DETACHED');
						break;
				}
			}
		});
		let filter = new IntentFilter();
		filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
		filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
		activity.registerReceiver(usbStatusReceiver, filter);
	},
	/**
	 * 关闭usb
	 */
	closeUsb() {
		mUsbEndpointIn = null;
		mUsbEndpointOut = null;
		if (mUsbDeviceConnection != null) {
			mUsbDeviceConnection.releaseInterface(mUsbInterface);
			mUsbDeviceConnection.close();
			mUsbDeviceConnection = null;
			isOpen = false;
		}
	},
	/**
	 * 获得usb打开状态
	 *
	 * @return true:USB打开 false:USB关闭
	 */
	isOpened() {
		return isOpen;
	},
	sendByteData(byteData) {
		if (currentDevice == null) {
			console.log("未检测到打印机设备");
			return false;
		}
		if (mUsbDeviceConnection == null) {
			mUsbManager.requestPermission(currentDevice, mPermissionIntent);
			mUsbDeviceConnection = mUsbManager.openDevice(currentDevice);
			const ret = invoke(mUsbDeviceConnection, "claimInterface", mUsbInterface, true);
		}
		if (mUsbEndpointOut == null) {
			return false;
		}
		const result = invoke(mUsbDeviceConnection, "bulkTransfer", mUsbEndpointOut, byteData, byteData.length,
			1500);
		if (result == -1) {
			return false;
		} else {
			return true;
		}
	}
}

module.exports = usbTool