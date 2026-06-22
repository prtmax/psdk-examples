/**
 * USB 打印机工具
 */
//#ifdef APP-PLUS
let UsbManager = plus.android.importClass("android.hardware.usb.UsbManager");
let IntentFilter = plus.android.importClass("android.content.IntentFilter");
let PendingIntent = plus.android.importClass("android.app.PendingIntent");
let UsbConstants = plus.android.importClass("android.hardware.usb.UsbConstants");
let Intent = plus.android.importClass("android.content.Intent");
let Context = plus.android.importClass("android.content.Context");
let Toast = plus.android.importClass("android.widget.Toast");
let UsbRequest = plus.android.importClass("android.hardware.usb.UsbRequest");
let ByteBuffer = plus.android.importClass("java.nio.ByteBuffer");

let invoke = plus.android.invoke;
let activity = plus.android.runtimeMainActivity();

const SUPPORTED_VIDS = [0x09C5, 0x09C6, 0x353D];
const USB_PERMISSION_ACTION = 'com.application.usbhost.USB_PERMISSION';

let mPermissionIntent = null;
let mUsbManager = null;
let currentDevice = null;
let mUsbDeviceConnection = null;
let mUsbInterface = null;
let mUsbEndpointIn = null;
let mUsbEndpointOut = null;
let usbStatusReceiver = null;
let isOpen = false;
//#endif

var usbTool = {
	state: {
		USBState: "",
	},
	options: {
		listenUSBStatusCallback: function(state) {},
	},

	init(setOptions) {
		Object.assign(this.options, setOptions);
		this.listenUsbStatus();
		mUsbManager = activity.getSystemService(Context.USB_SERVICE);
		mPermissionIntent = PendingIntent.getBroadcast(
			activity, 0,
			new Intent(USB_PERMISSION_ACTION),
			PendingIntent.FLAG_IMMUTABLE
		);
	},

	shortToast(msg) {
		Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show();
	},

	delay(ms) {
		return new Promise(resolve => setTimeout(resolve, ms));
	},

	async openUsb() {
		let mDevices = mUsbManager.getDeviceList();
		if (mDevices === null) return false;
		if (invoke(mDevices, "size") === 0) return false;

		const values = invoke(mDevices, "values");
		const iterator = invoke(values, "iterator");
		while (invoke(iterator, "hasNext")) {
			const device = invoke(iterator, "next");
			const vendorId = invoke(device, "getVendorId");
			if (!SUPPORTED_VIDS.includes(vendorId)) continue;

			currentDevice = device;

			if (!mUsbManager.hasPermission(currentDevice)) {
				mUsbManager.requestPermission(currentDevice, mPermissionIntent);
				for (let i = 10; i > 0; i--) {
					await this.delay(1000);
					if (i == 1 && !mUsbManager.hasPermission(currentDevice)) return false;
					if (mUsbManager.hasPermission(currentDevice)) break;
				}
			}

			if (this.initCommunication(currentDevice, UsbConstants.USB_CLASS_PRINTER) ||
				this.initCommunication(currentDevice, UsbConstants.USB_CLASS_VENDOR_SPEC)) {
				return true;
			}
		}
		return false;
	},

	initCommunication(device, type) {
		const interfaceCount = invoke(device, "getInterfaceCount");
		for (let i = 0; i < interfaceCount; i++) {
			const usbInterface = invoke(device, "getInterface", i);
			if (type != invoke(usbInterface, "getInterfaceClass")) continue;

			mUsbInterface = usbInterface;
			mUsbEndpointIn = null;
			mUsbEndpointOut = null;

			const endpointCount = invoke(usbInterface, "getEndpointCount");
			for (let j = 0; j < endpointCount; j++) {
				const ep = invoke(usbInterface, "getEndpoint", j);
				if (invoke(ep, "getType") != UsbConstants.USB_ENDPOINT_XFER_BULK) continue;
				if (invoke(ep, "getDirection") == UsbConstants.USB_DIR_OUT) {
					mUsbEndpointOut = ep;
				} else if (invoke(ep, "getDirection") == UsbConstants.USB_DIR_IN) {
					mUsbEndpointIn = ep;
				}
			}

			if (mUsbEndpointIn && mUsbEndpointOut) {
				mUsbDeviceConnection = mUsbManager.openDevice(device);
				if (mUsbDeviceConnection) {
					invoke(mUsbDeviceConnection, "claimInterface", mUsbInterface, true);
					isOpen = true;
					return true;
				}
			}
		}
		isOpen = false;
		return false;
	},

	_readWithUsbRequest(timeoutMillis) {
		if (!isOpen || !mUsbDeviceConnection || !mUsbEndpointIn) return null;

		const maxPacketSize = invoke(mUsbEndpointIn, "getMaxPacketSize") || 64;
		const PER_READ_TIMEOUT = 200;
		const chunks = [];
		let totalRead = 0;
		const startTime = Date.now();

		while (true) {
			if (Date.now() - startTime > timeoutMillis) break;

			const byteBuf = ByteBuffer.allocate(maxPacketSize);
			const request = new UsbRequest();
			invoke(request, "initialize", mUsbDeviceConnection, mUsbEndpointIn);

			if (!invoke(request, "queue", byteBuf, maxPacketSize)) {
				invoke(request, "close");
				break;
			}

			const result = invoke(mUsbDeviceConnection, "requestWait", PER_READ_TIMEOUT);
			invoke(request, "close");

			if (result) {
				const bytesRead = invoke(byteBuf, "position");
				if (bytesRead > 0) {
					const data = [];
					for (let i = 0; i < bytesRead; i++) {
						const b = invoke(byteBuf, "get", i);
						data.push(b < 0 ? b + 256 : b);
					}
					chunks.push(data);
					totalRead += bytesRead;
					if (bytesRead < maxPacketSize) break;
				}
			}
		}

		if (totalRead <= 0) return null;

		const result = new Array(totalRead);
		let off = 0;
		for (const c of chunks) {
			for (let i = 0; i < c.length; i++) result[off + i] = c[i];
			off += c.length;
		}
		return result;
	},

	listenUsbStatus() {
		if (usbStatusReceiver != null) {
			try { activity.unregisterReceiver(usbStatusReceiver); } catch (e) {}
			usbStatusReceiver = null;
		}

		try {
			usbStatusReceiver = plus.android.implements("io.dcloud.android.content.BroadcastReceiver", {
				"onReceive": (context, intent) => {
					try {
						plus.android.importClass(context);
						plus.android.importClass(intent);
						const action = intent.getAction();

						switch (action) {
							case UsbManager.ACTION_USB_DEVICE_ATTACHED:
								this.options.listenUSBStatusCallback &&
									this.options.listenUSBStatusCallback('ATTACHED');
								break;
							case UsbManager.ACTION_USB_DEVICE_DETACHED:
								isOpen = false;
								this.closeUsb();
								this.options.listenUSBStatusCallback &&
									this.options.listenUSBStatusCallback('DETACHED');
								break;
						}
					} catch (e) {
						console.error("[USB] onReceive 异常:", e);
					}
				}
			});

			const filter = new IntentFilter();
			filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
			filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
			filter.addAction(USB_PERMISSION_ACTION);
			activity.registerReceiver(usbStatusReceiver, filter);
		} catch (e) {
			console.error("[USB] 注册广播失败:", e);
		}
	},

	closeUsb() {
		mUsbEndpointIn = null;
		mUsbEndpointOut = null;
		if (mUsbDeviceConnection != null) {
			try {
				mUsbDeviceConnection.releaseInterface(mUsbInterface);
				mUsbDeviceConnection.close();
			} catch (e) {}
			mUsbDeviceConnection = null;
		}
		currentDevice = null;
		mUsbInterface = null;
		isOpen = false;
	},

	isOpened() {
		return isOpen;
	},

	getDeviceInfo() {
		if (!currentDevice) return null;
		return {
			name: invoke(currentDevice, "getDeviceName") || null,
			vendorId: invoke(currentDevice, "getVendorId"),
			productId: invoke(currentDevice, "getProductId"),
			deviceId: invoke(currentDevice, "getDeviceId"),
		};
	},

	sendByteData(byteData) {
		if (!currentDevice || !mUsbDeviceConnection || !mUsbEndpointOut) return false;
		try {
			const result = invoke(mUsbDeviceConnection, "bulkTransfer",
				mUsbEndpointOut, byteData, byteData.length, 1500);
			return result >= 0;
		} catch (e) {
			console.error("[USB] 发送失败:", e);
			return false;
		}
	},

	async sendAndRead(cmd, timeout = 2000) {
		if (!currentDevice || !mUsbDeviceConnection || !mUsbEndpointOut || !mUsbEndpointIn) return null;

		if (!this.sendByteData(cmd)) return null;
		await this.delay(50);
		if (!isOpen || !mUsbDeviceConnection || !mUsbEndpointIn) return null;
		return this._readWithUsbRequest(timeout);
	},

	async readOnce(timeout = 2000) {
		if (!isOpen || !mUsbDeviceConnection || !mUsbEndpointIn) return null;
		await this.delay(0);
		return this._readWithUsbRequest(timeout);
	}
};

module.exports = usbTool;