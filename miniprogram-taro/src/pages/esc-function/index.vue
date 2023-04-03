<template>
  <div>
    <button v-for="(item, index) in functions" :key="index"  @click="item.fun">
      {{ item.title }}
    </button>
  </div>
</template>

<script>
import Taro, { getCurrentInstance } from '@tarojs/taro'
import { Raw } from '@psdk/frame-father'

definePageConfig({
  navigationBarTitleText: "打印机"
})

export default {
  name: 'esc',
  inject: ["printer"],
  data() {
    return {
      functions:[
        {
          title: "打印自测页",
          fun: this.seftTest
        },
        {
          title: "打印文字",
          fun: this.printText
        },
        {
          title: "打印图片",
          fun: this.printImage
        },
      ],
    }
  },
  methods: {
    async seftTest() {
      console.log("this.printer.esc() ->", this.printer.esc())
    },
    async printText() {
      console.log("this.printer.esc() ->", this.printer.esc())
    },
    async printImage() {
      console.log("this.printer.esc() ->", this.printer.esc())
      this.printer
      .esc()
      .mac()
      .write()

      const receive = await this.printer.esc().connectedDevice().read()
      console.log("receive: ", receive)
    }
  },
  created() {
    const deviceName = getCurrentInstance().router.params.deviceName
    Taro.setNavigationBarTitle({
      title: deviceName
    }) 
  }
}
</script>

<style lang="scss">

</style>