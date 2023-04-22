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
import { CPage, CImage, CText, Font } from '@psdk/cpcl'

definePageConfig({
  navigationBarTitleText: "打印机"
})

export default {
  name: 'cpcl',
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
      this.printer
      .cpcl()
      .raw(Raw.binary(Uint8Array.from([0x10, 0xff, 0xbf])))
      .write()
    },
    async printText() {
      this.printer
      .cpcl()
      .page(new CPage({width: 75 * 8, height: 130 * 8 }))
      .text(new CText({
        x: 20,
        y: 10,
        content: "《惠州一绝》",
        font: Font.TSS24_MAX1
      }))
      .text(new CText({
        x: 10,
        y: 40,
        content: "罗浮山下四时春，",
        font: Font.TSS24_MAX1
      }))
      .text(new CText({
        x: 10,
        y: 80,
        content: "卢橘杨梅次第新。",
        font: Font.TSS24_MAX1
      }))
      .text(new CText({
        x: 10,
        y: 120,
        content: "日啖荔枝三百颗，",
        font: Font.TSS24_MAX1
      }))
      .text(new CText({
        x: 10,
        y: 160,
        content: "不辞长作岭南人。",
        font: Font.TSS24_MAX1
      }))
      .print()
      .write()
    },
    async printImage() {
      console.log("printImage...", this.printer.cpcl())
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
      this.printer
      .cpcl()
      .page(new CPage({width: 608, height: 1040 }))
      .image(
        new CImage({
          x: 0,
          y: 0,
          compress: true,
          image: canvas
        })
      )
      .print()
      .write()
    },
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
