<script setup lang="ts">
import {CBar, CBox, CCodeRotation, CCodeType, CFont, CForm, CImage, CLine, CPage, CPCL, CText} from "@psdk/cpcl";
import {FakeConnectedDevice, Lifecycle} from "@psdk/frame-father";
import {ref} from "vue";
import {TBarCode, TBox, TCodeType, TFont, TImage, TLine, TPage, TRotation, TSPL, TText} from "@psdk/tspl";
import {EImage, ESC} from "@psdk/esc";
import {useSnackbar} from "vuetify-use-dialog";

const createSnackbar = useSnackbar()
let characteristic
let connectedDevice
const cmd = ref('tspl');
const dialog = ref(false);
const items = [{type: 'tspl',}, {type: 'cpcl',}, {type: 'esc',}];

// 蓝牙方法
async function discovery() {
  navigator.bluetooth.requestDevice({
    acceptAllDevices: true,
    // 蓝牙uuid
    optionalServices: ['49535343-fe7d-4ae5-8fa9-9fafd205e455'],
  })
      .then(async (device) => {
        dialog.value = true;
        console.log("Name:1 " + device.name, device);
        connectedDevice = device;
        // 连接设备
        let server = await device.gatt.connect();
        console.log(`server2`, server);
        // 获取蓝牙uuid相关内容
        let service = await server.getPrimaryService('49535343-fe7d-4ae5-8fa9-9fafd205e455');
        console.log(`service3`, service);
        // 获取可以读写字符流的服务
        characteristic = await service.getCharacteristic('49535343-8841-43f4-a8d4-ecbe34729bb3');
        console.log(`characteristic4`, characteristic);
        createSnackbar({text: "连接成功"})
        dialog.value = false;
      })
      .catch(function (error) {
        // 监听错误
        console.log("Something went wrong. " + error);
        createSnackbar({text: "连接失败" + error})
        dialog.value = false;
      });
}


function closeBluetooth() {
  try {
    if (connectedDevice != null) {
      connectedDevice.gatt.disconnect();
      connectedDevice = null;
      characteristic = null;
    }

  } catch (e) {
    console.error(e);
  }
}

async function writeModel() {
  if (cmd.value == "tspl") {
    if (characteristic != null) {
      await write(0, writeTsplModel(), characteristic, 20);
    }
  } else if (cmd.value == "cpcl") {
    if (characteristic != null) {
      await write(0, writeCpclModel(), characteristic, 20);
    }
  }
}

function writeCpclModel() {
  try {
    const lifecycle = new Lifecycle(new FakeConnectedDevice());
    const cpcl = CPCL.generic(lifecycle)
        .page(new CPage({
          width: 608,
          height: 1040
        }))
        .box(new CBox({
          topLeftX: 0,
          topLeftY: 1,
          bottomRightX: 598,
          bottomRightY: 664,
          lineWidth: 2
        }))
        .line(new CLine({
          startX: 0,
          startY: 88,
          endX: 598,
          endY: 88,
          width: 2
        }))
        .line(new CLine({
          startX: 0,
          startY: 88 + 128,
          endX: 598,
          endY: 88 + 128,
          width: 2
        }))
        .line(new CLine({
          startX: 0,
          startY: 88 + 128 + 80,
          endX: 598,
          endY: 88 + 128 + 80,
          width: 2
        }))
        .line(new CLine({
          startX: 0,
          startY: 88 + 128 + 80 + 144,
          endX: 598 - 56 - 16,
          endY: 88 + 128 + 80 + 144,
          width: 2
        }))
        .line(new CLine({
          startX: 0,
          startY: 88 + 128 + 80 + 144 + 128,
          endX: 598 - 56 - 16,
          endY: 88 + 128 + 80 + 144 + 128,
          width: 2
        }))
        .line(new CLine({
          startX: 52,
          startY: 88 + 128 + 80,
          endX: 52,
          endY: 88 + 128 + 80 + 144 + 128,
          width: 2
        }))
        .line(new CLine({
          startX: 598 - 56 - 16,
          startY: 88 + 128 + 80,
          endX: 598 - 56 - 16,
          endY: 664,
          width: 2
        }))
        .bar(new CBar({
          x: 120,
          y: 88 + 12,
          lineWidth: 1,
          height: 80,
          content: "1234567890",
          codeRotation: CCodeRotation.ROTATION_0,
          codeType: CCodeType.CODE128
        }))
        .text(new CText({
          x: 120 + 12,
          y: 88 + 20 + 76,
          content: "1234567890",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 12,
          y: 88 + 128 + 80 + 32,
          content: "收",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 12,
          y: 88 + 128 + 80 + 96,
          content: "件",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 12,
          y: 88 + 128 + 80 + 144 + 32,
          content: "发",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 12,
          y: 88 + 128 + 80 + 144 + 80,
          content: "件",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 128 + 16,
          content: "签收人/签收时间",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 430,
          y: 88 + 128 + 80 + 144 + 128 + 36,
          content: "月",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 490,
          y: 88 + 128 + 80 + 144 + 128 + 36,
          content: "日",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 24,
          content: "收姓名" + " " + "13777777777",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 24 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 24,
          content: "名字" + " " + "13777777777",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 24 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 104,
          content: "派",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 160,
          content: "件",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 208,
          content: "联",
          font: CFont.TSS24
        }))
        .box(new CBox({
          topLeftX: 0,
          topLeftY: 1,
          bottomRightX: 598,
          bottomRightY: 968,
          lineWidth: 2
        }))
        .line(new CLine({
          startX: 0,
          startY: 696 + 80,
          endX: 598,
          endY: 696 + 80,
          width: 2
        }))
        .line(new CLine({
          startX: 0,
          startY: 696 + 80 + 136,
          endX: 598 - 56 - 16,
          endY: 696 + 80 + 136,
          width: 2
        }))
        .line(new CLine({
          startX: 52,
          startY: 80,
          endX: 52,
          endY: 696 + 80 + 136,
          width: 2
        }))
        .line(new CLine({
          startX: 598 - 56 - 16,
          startY: 80,
          endX: 598 - 56 - 16,
          endY: 968,
          width: 2
        }))
        .bar(new CBar({
          x: 320,
          y: 696 - 4,
          lineWidth: 1,
          height: 56,
          content: "1234567890",
          codeRotation: CCodeRotation.ROTATION_0,
          codeType: CCodeType.CODE128
        }))
        .text(new CText({
          x: 320 + 8,
          y: 696 + 54,
          content: "1234567890",
          font: CFont.TSS16
        }))
        .text(new CText({
          x: 12,
          y: 696 + 80 + 35,
          content: "发",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 12,
          y: 696 + 80 + 84,
          content: "件",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 52 + 20,
          y: 696 + 80 + 28,
          content: "名字" + " " + "13777777777",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 52 + 20,
          y: 696 + 80 + 28 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 50,
          content: "客",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 82,
          content: "户",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 106,
          content: "联",
          font: CFont.TSS24
        }))
        .text(new CText({
          x: 12 + 8,
          y: 696 + 80 + 136 + 22 - 5,
          content: "物品：" + "几个快递" + " " + "12kg",
          font: CFont.TSS24
        }))
        .box(new CBox({
          topLeftX: 598 - 56 - 16 - 120,
          topLeftY: 696 + 80 + 136 + 11,
          bottomRightX: 598 - 56 - 16 - 16,
          bottomRightY: 968 - 11,
          lineWidth: 2
        }))
        .text(new CText({
          x: 598 - 56 - 16 - 120 + 17,
          y: 696 + 80 + 136 + 11 + 6,
          content: "已验视",
          font: CFont.TSS24
        }))
        .form(new CForm())
        .print();
    console.log(cpcl.command().string());
    return cpcl.command().binary();
  } catch (e) {
    console.error(e);
  }
}

function writeTsplModel() {
  try {
    const lifecycle = new Lifecycle(new FakeConnectedDevice());
    const tspl = TSPL.generic(lifecycle)
        .page(new TPage({
          width: 76,
          height: 130
        }))
        .box(new TBox({
          startX: 0,
          startY: 1,
          endX: 598,
          endY: 664,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88,
          endX: 598,
          endY: 88,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128,
          endX: 598,
          endY: 88 + 128,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128 + 80,
          endX: 598,
          endY: 88 + 128 + 80,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128 + 80 + 144,
          endX: 598 - 56 - 16,
          endY: 88 + 128 + 80 + 144,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 88 + 128 + 80 + 144 + 128,
          endX: 598 - 56 - 16,
          endY: 88 + 128 + 80 + 144 + 128,
          width: 2
        }))
        .line(new TLine({
          startX: 52,
          startY: 88 + 128 + 80,
          endX: 52,
          endY: 88 + 128 + 80 + 144 + 128,
          width: 2
        }))
        .line(new TLine({
          startX: 598 - 56 - 16,
          startY: 88 + 128 + 80,
          endX: 598 - 56 - 16,
          endY: 664,
          width: 2
        }))
        .barcode(new TBarCode({
          x: 120,
          y: 88 + 12,
          cellWidth: 2,
          height: 80,
          content: "1234567890",
          rotation: TRotation.ROTATION_0,
          codeType: TCodeType.CODE_128
        }))
        .text(new TText({
          x: 120 + 12,
          y: 88 + 20 + 76,
          content: "1234567890",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 32,
          content: "收",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 96,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 144 + 32,
          content: "发",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 88 + 128 + 80 + 144 + 80,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 128 + 16,
          content: "签收人/签收时间",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 430,
          y: 88 + 128 + 80 + 144 + 128 + 36,
          content: "月",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 490,
          y: 88 + 128 + 80 + 144 + 128 + 36,
          content: "日",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 24,
          content: "收姓名" + " " + "13777777777",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 24 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 24,
          content: "名字" + " " + "13777777777",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 88 + 128 + 80 + 144 + 24 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 104,
          content: "派",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 160,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 88 + 128 + 80 + 208,
          content: "联",
          font: TFont.TSS24
        }))
        .box(new TBox({
          startX: 0,
          startY: 1,
          endX: 598,
          endY: 968,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 696 + 80,
          endX: 598,
          endY: 696 + 80,
          width: 2
        }))
        .line(new TLine({
          startX: 0,
          startY: 696 + 80 + 136,
          endX: 598 - 56 - 16,
          endY: 696 + 80 + 136,
          width: 2
        }))
        .line(new TLine({
          startX: 52,
          startY: 80,
          endX: 52,
          endY: 696 + 80 + 136,
          width: 2
        }))
        .line(new TLine({
          startX: 598 - 56 - 16,
          startY: 80,
          endX: 598 - 56 - 16,
          endY: 968,
          width: 2
        }))
        .barcode(new TBarCode({
          x: 320,
          y: 696 - 4,
          cellWidth: 2,
          height: 56,
          content: "1234567890",
          rotation: TRotation.ROTATION_0,
          codeType: TCodeType.CODE_128
        }))
        .text(new TText({
          x: 320 + 8,
          y: 696 + 54,
          content: "1234567890",
          font: TFont.TSS16
        }))
        .text(new TText({
          x: 12,
          y: 696 + 80 + 35,
          content: "发",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12,
          y: 696 + 80 + 84,
          content: "件",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 696 + 80 + 28,
          content: "名字" + " " + "13777777777",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 52 + 20,
          y: 696 + 80 + 28 + 32,
          content: "南京市浦口区威尼斯水城七街区七街区",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 50,
          content: "客",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 82,
          content: "户",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 598 - 56 - 5,
          y: 696 + 80 + 106,
          content: "联",
          font: TFont.TSS24
        }))
        .text(new TText({
          x: 12 + 8,
          y: 696 + 80 + 136 + 22 - 5,
          content: "物品：" + "几个快递" + " " + "12kg",
          font: TFont.TSS24
        }))
        .box(new TBox({
          startX: 598 - 56 - 16 - 120,
          startY: 696 + 80 + 136 + 11,
          endX: 598 - 56 - 16 - 16,
          endY: 968 - 11,
          width: 2
        }))
        .text(new TText({
          x: 598 - 56 - 16 - 120 + 17,
          y: 696 + 80 + 136 + 11 + 6,
          content: "已验视",
          font: TFont.TSS24
        }))
        .print();
    console.log(tspl.command().string());
    return tspl.command().binary();
  } catch (e) {
    console.error(e);
  }
}

function createOffScreenCanvas(image) {
  const offscreenCanvas = document.createElement("canvas");
  const offscreenContext = offscreenCanvas.getContext("2d");
  // 这里可以是动态宽高
  offscreenCanvas.width = 608;
  offscreenCanvas.height = 1040;
  offscreenContext.drawImage(
      image,
      0,
      0,
      offscreenCanvas.width,
      offscreenCanvas.height
  );
  return offscreenCanvas;
}

async function printImage() {
  // 创建一个图片
  const image = new Image();
  // 等待图片加载
  await new Promise(resolve => {
    image.onload = resolve;
    image.src = "/static/yunda.png";
  });
  const canvas = createOffScreenCanvas(image);
  console.log("toDataURL - ", canvas.toDataURL()) // 输出的图片
  if (cmd.value == "tspl") {
    const lifecycle = new Lifecycle(new FakeConnectedDevice());
    const tspl = TSPL.generic(lifecycle)
        .page(new TPage({
          width: 76,
          height: 130
        }))
        .gap(true)
        .image(
            new TImage({
              x: 0,
              y: 0,
              compress: true,
              image: canvas
            })
        )
        .print();

    await write(0, tspl.command().binary(), characteristic, 20);
  } else if (cmd.value == "cpcl") {
    const lifecycle = new Lifecycle(new FakeConnectedDevice());
    const cpcl = CPCL.generic(lifecycle)
        .page(new CPage({
          width: 608,
          height: 1040
        }))
        .image(
            new CImage({
              x: 0,
              y: 0,
              compress: true,
              image: canvas
            })
        )
        .print();
    await write(0, cpcl.command().binary(), characteristic, 20);
  } else {
    const lifecycle = new Lifecycle(new FakeConnectedDevice());
    const esc = ESC.generic(lifecycle)
        .enable()
        .wakeup()
        .image(
            new EImage({
              image: canvas,
              compress: true,
            })
        )
        .lineDot(40)
        .stopJob();
    await write(0, esc.command().binary(), characteristic, 20);
  }
}

async function write(index, data, printCharacteristic, size) {
  if (index + size < data.length) {
    await printCharacteristic.writeValue(data.slice(index, index + size));
    index += size;
    await write(index, data, printCharacteristic, size);
  } else {
// Send the last bytes
    if (index < data.length) {
      await printCharacteristic.writeValue(data.slice(index, data.length));
    }
  }
}


</script>

<template>
  <v-dialog v-model="dialog" :scrim="false" persistent width="auto">
    <v-card color="primary">
      <v-card-text>
        正在连接
        <v-progress-linear
            indeterminate
            color="white"
            class="mb-0"
        ></v-progress-linear>
      </v-card-text>
    </v-card>
  </v-dialog>
  <view>指令选择：</view>
  <label v-for="item in items" :key="item.type">
    <input type="radio" :value="item.type" v-model="cmd"/>
    <span>{{ item.type }}</span>
  </label>

  <button @click="discovery" class="button">开始搜索</button>
  <button @click="closeBluetooth" class="button">断开连接</button>
  <button @click="writeModel" class="button">打印76*130模版</button>
  <button @click="printImage" class="button">打印图片</button>
</template>
