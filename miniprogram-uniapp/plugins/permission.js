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
  getPermissionList(permissionID) {
    const id = androidPermissions[permissionID];
    const list = [];
    if (typeof id == "string") {
      list[0] = id;
    } else {
      for (let key in id) {
        list.push(id[key]);
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
          function (result) {
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