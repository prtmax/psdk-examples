const androidPermissions = {
	camera: "android.permission.CAMERA", // 摄像头权限
	bluetooth: {
		coarse: "android.permission.ACCESS_COARSE_LOCATION", // 位置权限
		fine: "android.permission.ACCESS_FINE_LOCATION",
		extra: "android.permission.ACCESS_LOCATION_EXTRA_COMMANDS",
		scan: "android.permission.BLUETOOTH_SCAN",
		connect: "android.permission.BLUETOOTH_CONNECT",
	},
	storage: {
		read: "android.permission.READ_EXTERNAL_STORAGE", // 存储读取权限
		write: "android.permission.WRITE_EXTERNAL_STORAGE", // 存储写入权限
	},
};

const permissionCheck = {
	getAndroidVersionCode() {
		try {
			// 方法1: 通过plus.os获取（优先尝试）
			if (plus && plus.os && typeof plus.os.versionCode === 'number') {
				return plus.os.versionCode;
			}

			// 方法2: 通过Android原生API获取（兼容旧版本运行时）
			if (plus && plus.android) {
				const Build = plus.android.importClass('android.os.Build');
				return Build.VERSION.SDK_INT; // 这是Android原生获取API级别的方式
			}

			// 方法3: 无法获取时返回默认值（低版本）
			return 21; // 默认最低支持的API级别（Android 5.0）
		} catch (e) {
			console.warn('获取Android版本号失败:', e);
			return 21; // 异常时返回默认低版本
		}
	},
	getPermissionList(permissionID) {
		const id = androidPermissions[permissionID];
		const list = [];

		const androidVersion = this.getAndroidVersionCode();
		console.log("androidVersion：", androidVersion);
		if (typeof id === "string") {
			list.push(id);
		} else {
			for (let key in id) {
				// 对于蓝牙权限，Android11以下不需要BLUETOOTH_SCAN和BLUETOOTH_CONNECT
				if (permissionID === 'bluetooth' && androidVersion < 31) {
					if (key !== 'scan' && key !== 'connect') {
						list.push(id[key]);
					}
				} else {
					list.push(id[key]);
				}
			}
		}
		return list;
	},
	androidPermissionCheck(permissionID) {
		return new Promise((resolve, reject) => {
			if (plus) {
				let ids = this.getPermissionList(permissionID);
				plus.android.requestPermissions(
					ids,
					function(result) {
						let res = 0;
						for (let i = 0; i < result.granted.length; i++) {
							let permission = result.granted[i];
							console.log("已获取的权限：", permission);
							res = 1;
						}
						for (let i = 0; i < result.deniedPresent.length; i++) {
							let permission = result.deniedPresent[i];
							console.log("本次已拒绝的权限：", permission);
							res = 0;
						}
						for (let i = 0; i < result.deniedAlways.length; i++) {
							let permission = result.deniedAlways[i];
							console.log("永久拒绝的权限：", permission);
							res = -1;
						}
						resolve({
							code: 1,
							data: res,
						});
					},
					(error) => {
						reject({
							code: 2,
							data: `code:${error.code},msg:${error.message}!`,
						});
					}
				);
			}
		});
	}
};

export default permissionCheck;