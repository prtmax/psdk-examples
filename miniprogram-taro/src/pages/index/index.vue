<!-- 
  {"pages":["pages/index/index","pages/printer-function/index"],"permission":{"scope.userLocation":{"desc":"你的位置信息将用于小程序位置接口的效果展示"}},"window":{"backgroundTextStyle":"light","navigationBarBackgroundColor":"#fff","navigationBarTitleText":"WeChat","navigationBarTextStyle":"black"},"requiredPrivateInfos": [
    "getLocation"
  ]} 
-->
<template>
  <view class="container">
    <nut-button type="info"  class="searchBtn" @click="discoveryDevices">
      搜索
    </nut-button>

    <nut-cell-group title="打印机列表">
      <nut-cell v-for="device in source.devices" :key="device.deviceId"         
                :title="device.name"
                @click="connectDevice(device)">
        <template v-slot:link>
          <rect-right></rect-right>
        </template>
      </nut-cell>
    </nut-cell-group>

  </view>
</template>

<script>
import { RectRight } from '@nutui/icons-vue-taro';
import Taro from '@tarojs/taro';
import { TaroBleBluetooth } from '@psdk/device-ble-taro'


export default {
  name: 'Index',
  components: {
    RectRight,
  },
  inject: [
      "printer"
  ],
  created() {
    this.bluetooth.discovered((devices) => {
      console.log("discoveryDevices ...", devices);
      this.source.devices.push(...devices);
    });
  },
  data() {
    return {
      source: {
        devices: [],
        showBluetoothError: null,
      },
      cond: {
        showBluetoothError: false,
      },
      bluetooth: new TaroBleBluetooth({
        allowNoName: false
      }),
    }
  },
  methods: {
    gotoPrinter() {
      console.log("gotoPrinter: ", Taro);
      Taro.navigateTo({ url: '/pages/printer/index' });
    },
    async discoveryDevices() {
      await this.bluetooth.startDiscovery()
      
    },
    async connectDevice(device) {
      console.log("connectDevice... ", device);
      await this.bluetooth.connect(device)

      try {
        Taro.showLoading({
          title: "连接中...",
          mask: true
        })

        const connectDevice = await this.bluetooth.connect(device)
        if (!connectDevice.canRead) {
          Taro.showToast({
            title: '你的打印机不支持读取数据. 部分功能将不可用',
            icon: "error"
          })
        }
      
        Taro.showToast({
          title: '连接成功!'
        })

        this.printer.init(connectDevice)
        Taro.navigateTo({ url: "/pages/printer-function/index" });

      } catch (error) { 
        console.log(error)
      }
    }
  }, 
  computed: {
    deviceName() {
      return '未连接打印机';
    }
  }
}
</script>

<style lang="scss">
.index {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  // text-align: center;
}

.title {
  background-color: red;
  padding: 1rem 0;
  font-size: 1rem;
  font-weight: 700;
}

.searchBtn {
  position: fixed;
  z-index: 10;
  bottom: 8rem;
  right: 1rem;
}

</style>
