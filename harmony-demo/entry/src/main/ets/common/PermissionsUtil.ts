import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';

export class PermissionsUtil {
  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      console.error(`Failed to get bundle info for self, error is ${JSON.stringify(error)}`);
    }

    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
    } catch (error) {
      console.error(`Failed to check access token ${JSON.stringify(error)}`);
    }
    return grantStatus;
  }
  /**
   * 检查是否授予权限
   * @param permissions
   * @param successCallBack
   * @param failedCallBack
   * @returns
   */
  async checkPermissions(permissions: Array<Permissions>, successCallBack: () => void, failedCallBack: () => void): Promise<void> {
    let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // 已经授权，可以继续访问目标操作
      successCallBack()
    } else {
      failedCallBack()
    }
  }
  /**
   * 动态向用户申请授权。
   * @param context
   * @param permissions
   * @param successCallBack
   * @param failedCallBack
   */
  requestPermissions(context, permissions, successCallBack?: () => void, failedCallBack?: () => void) {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, permissions).then((data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          // 授权成功用户授权，可以继续访问目标操作
          successCallBack()
        } else {
          // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
          failedCallBack()
          return;
        }
      }
    }).catch((err) => {
      console.error(`Failed to request permissions from user. error is ${JSON.stringify(err)}`);
    })
  }
}

let permissionsUtil = new PermissionsUtil()

export default permissionsUtil as PermissionsUtil