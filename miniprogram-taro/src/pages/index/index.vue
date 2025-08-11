<template>
  <view class="container">
    <nut-button type="info"
                class="searchBtn"
                @click="discoveryDevices">
      搜索
    </nut-button>

    <nut-cell-group title="打印机列表">
      <nut-cell v-for="device in source.devices"
                :key="device.deviceId"
                :title="device.name"
                @click="connectDevice(device)">
        <template v-slot:link>
          <rect-right></rect-right>
        </template>
      </nut-cell>
    </nut-cell-group>

    <nut-popup position="bottom"
              closeable round
              :style="{ height: '30%' }"
              v-model:visible="showRound">
      <div>
        <h2 class="popup-title">请选择打印机指令</h2>
        <button v-for="(item, index) in cmds"
                :key="index"
                @click="cmdBtnClick(item)">
          {{ item }}
        </button>
      </div>
    </nut-popup>

  </view>
</template>

<script>
import { RectRight } from '@nutui/icons-vue-taro';
import Taro from '@tarojs/taro';
import { TaroBleBluetooth } from '@psdk/device-ble-taro'
import kfc from '../../assets/F.png'
import logo from '../../assets/logo.png'
import waybill from '../../assets/waybill-usps.png'


export default {
  name: 'Index',
  components: {
    RectRight,
  },
  inject: ["printer"],
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
      bluetooth: new TaroBleBluetooth({
        allowedWriteCharacteristic: '49535343-8841-43F4-A8D4-ECBE34729BB3',
        allowedReadCharacteristic: '49535343-1e4d-4bd9-ba61-23c647249616', 
        allowNoName: false
      }),
      showRound: false,
      cmds: ["tspl", "cpcl", "esc"],
      connectDevice: null,
      images: [kfc, logo, waybill]
    }
  },
  methods: {
    cmdBtnClick(item) {
      if(this.connectDevice === null) return
      this.showRound = false
      this.printer.init(this.connectDevice)
      const deviceName = this.bluetooth.connectedDevice.deviceName()
      switch (item) {
        case "tspl":
          Taro.navigateTo({ url: `/pages/tspl-function/index?deviceName=${deviceName}` })
          break;
        case "cpcl":
          Taro.navigateTo({ url: `/pages/cpcl-function/index?deviceName=${deviceName}` })
          break;
        case "esc":
          Taro.navigateTo({ url: `/pages/esc-function/index?deviceName=${deviceName}` })
          break;

        default:
          break;
      }
    },
    async discoveryDevices() {
      try {
        await this.bluetooth.startDiscovery()
      } catch (error) {
        console.log("discovery error: ", error)
        if(error.errCode === 10001) {
          Taro.showToast({
            title: "请开启手机蓝牙!",
            icon: "error"
          })
        }
      }
    },
    async connectDevice(device) {
      await this.bluetooth.stopDiscovery()
      if(this.connectDevice != null) {
        await this.bluetooth.connectedDevice.disconnect()
      }
      try {
        Taro.showLoading({
          title: "连接中...",
          mask: true
        })
        const connectDevice = await this.bluetooth.connect(device)
        if (!connectDevice.canRead) {
          Taro.showToast({
            title: '你的打印机不支持读取数据. 部分功能将不可用',
            icon: "error",
          })
        }

        Taro.showToast({
          title: '连接成功!'
        })
        this.showRound = true
        this.connectDevice = connectDevice
        console.log("连接设备: ", this.bluetooth.connectedDevice)

      } catch (error) {
        console.log("connect error: ", error)
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
.popup-title {
  margin-top: 2rem;
  margin-bottom: 1rem;
  text-align: center;
}

</style>
