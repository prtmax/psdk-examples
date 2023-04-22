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
import { EImage } from '@psdk/esc'

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
      console.log("printImage...")
      // 把图片画到离屏 canvas 上
      const canvas = Taro.createOffscreenCanvas({type: '2d', width: 717, height: 1040});
      const ctx = canvas.getContext('2d');
      // 创建一个图片
      const image = canvas.createImage();
      // 等待图片加载
      await new Promise(resolve => {
        image.onload = resolve;
        image.src = "../../assets/waybill-usps.png"; // 要加载的图片 url, 可以是base64
      });
      ctx.drawImage(image, 0, 0, 717, 1040);
      console.log("toDataURL - ", ctx.canvas.toDataURL()) // 输出的图片

      var repo = await this.printer
      .esc()
      .enable()
      .wakeup()
      .image(
        new EImage({
          image: canvas,
          compress: true
        })
      )
      .lineDot({dot: 40})
      .stopJob()
      .write()

      console.log("repo: ", repo)
      // const receive = await this.printer.esc().connectedDevice().read()
      // console.log("receive: ", receive)
    }
  },
  created() {
    const deviceName = getCurrentInstance().router.params.deviceName
    Taro.setNavigationBarTitle({
      title: deviceName
    })
  },
}
</script>

<style lang="scss">

</style>
