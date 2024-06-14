const androidPermissions = {
  camera: "android.permission.CAMERA", // 摄像头权限
  location: "android.permission.ACCESS_FINE_LOCATION", // 位置权限
  calendar: {
    read: "android.permission.READ_CALENDAR", // // 日历读取权限
    write: "android.permission.WRITE_CALENDAR", // // 日历写入权限
  },
  storage: {
    read: "android.permission.READ_EXTERNAL_STORAGE", // 存储读取权限
    write: "android.permission.WRITE_EXTERNAL_STORAGE", // 存储写入权限
  },
  record: "android.permission.RECORD_AUDIO", // 麦克风权限
  contact: {
    read: "android.permission.READ_CONTACTS", // 联系人读取权限
    write: "android.permission.WRITE_CONTACTS", // 联系人写入权限
  },
  sms: {
    read: "android.permission.READ_SMS", // 短信读取权限
    send: "android.permission.SEND_SMS", //短信发送权限
    receive: "android.permission.RECEIVE_SMS", // 短信接收权限
  },
  state: "android.permission.READ_PHONE_STATE", // 手机识别码权限
  phone: "android.permission.CALL_PHONE", // 拨打电话权限
  log: "android.permission.READ_CALL_LOG", // 通话记录权限
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