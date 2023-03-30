export default defineAppConfig({
  pages: [
    'pages/index/index',
    'pages/printer-function/index',
  ],
  permission: {
    'scope.userLocation': {
      desc: '你的位置信息将用于小程序位置接口的效果展示',
    }
  },
  "requiredPrivateInfos": [
    "getLocation"
  ],
  window: {
    backgroundTextStyle: 'light',
    navigationBarBackgroundColor: '#fff',
    navigationBarTitleText: 'WeChat',
    navigationBarTextStyle: 'black'
  }
})
