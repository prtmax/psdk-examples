<template>
  <div>
    <button v-for="(item, index) in functions" :key="index"  @click="item.fun">
      {{ item.title }}
    </button>
  </div>
</template>

<script>
import Taro from '@tarojs/taro'
import { Raw } from '@psdk/frame-father'
import { TBarCode, TImage, TPage } from '@psdk/tspl'
import { CodeType } from '@psdk/tspl/build/types/codetype'
import kfc from '../../assets/FFF.png'
import logo from '../../assets/logo.png'
import waybill from '../../assets/waybill-usps.png'

definePageConfig({
  navigationBarTitleText: "打印机"
})

export default {
  name: 'Printer',
  components: {
  },
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
      images: [logo, waybill, kfc]
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
      .barcoce(new TBarCode({
        x: 100,
        y: 100,
        height: 120,
        content: "12345678",
        cellWidth: 2,
        codeType: CodeType.CODE_128
      }))
      .print()
      .write()
    },
    async printImage() {
      // 把图片画到离屏 canvas 上
      const canvas = Taro.createOffscreenCanvas({type: '2d', width: 20, height: 35});
      const ctx = canvas.getContext('2d');
      // 创建一个图片
      const image = canvas.createImage();
      // 等待图片加载
      await new Promise(resolve => {
        image.onload = resolve;
        image.src = "../../assets/F.png"; // 要加载的图片 url, 可以是base64
      });
      ctx.drawImage(image, 0, 0, 20, 35);
      console.log("toDataURL - ", ctx.canvas.toDataURL()) // 输出的图片
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
    this.images.forEach(element => {
      console.log(element)
    });
  },
}
</script>

<style lang="scss">

</style>