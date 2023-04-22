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
import { TImage, TPage, TText, TFont } from '@psdk/tspl'

export default {
  name: 'tspl',
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
      this.printer.tspl().raw(Raw.text("SELFTEST")).write()
    },
    async printText() {
      this.printer
      .tspl()
      .cls()
      .page(new TPage({width: 75, height:130 }))
      .text(new TText({
        x: 20,
        y: 10,
        content: "《题西林壁》",
        font: TFont.TSS32
      }))
      .text(new TText({
        x: 10,
        y: 40,
        content: "横看成岭侧成峰，",
        font: TFont.TSS32
      }))
      .text(new TText({
        x: 20,
        y: 80,
        content: "远近高低各不同。",
        font: TFont.TSS32
      }))
      .text(new TText({
        x: 20,
        y: 120,
        content: "不识庐山真面目，",
        font: TFont.TSS32
      }))
      .text(new TText({
        x: 20,
        y: 160,
        content: "只缘身在此山中。",
        font: TFont.TSS32
      }))
      .print()
      .write()
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
      console.log("toDataURL - ", ctx.canvas.toDataURL())

      this.printer
      .tspl()
      .cls()
      .page(new TPage({width: 75, height:130 }))
      .image(
        new TImage({
          x: 80,
          y: 20,
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
  }
}
</script>

<style lang="scss">

</style>
