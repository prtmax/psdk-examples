<template>
	<view class="center">
		<view class="uni-list">
			<view class="uni-title ">指令选择:</view>
			<radio-group class="uni-list" @change="radioChange">
				<label class="uni-list-cell-pd" v-for="(item, index) in items" :key="item.type">
					<view>
						<radio :value="item.type" :checked="index === current" style="transform:scale(0.8)" />
					</view>
					<view>{{item.type}}</view>
				</label>
			</radio-group>
		</view>
		<button @click="discovery" class="button">开始搜索</button>
		<button @click="closeBluetooth" class="button">断开连接</button>
		<button @click="writeModel" class="button">打印76*130模版</button>
		<button @click="printImage" class="button">打印图片</button>
		<button @click="writeTsplRibbonModel" class="button">打印热转印测试</button>
		<scroll-view class="canvas-buttons" scroll-y="true">
			<block v-for="(item, index) in discoveredDevices" :key="item.deviceId">
				<text class="status">设备名称:{{item.name}}</text>
				<text class="status">设备ID:{{item.deviceId}}</text>
				<text class="status">连接状态:{{connectedDeviceId == item.deviceId?"已连接":"未连接"}}</text>
				<button type="warn" class="button" @click="connectDevice(item)">连接</button>
			</block>
		</scroll-view>
	</view>

</template>

<script>
	import {
		UniappBleBluetooth
	} from "@psdk/device-ble-uniapp";
	import Timeout from 'await-timeout';
	import {
		ConnectedDevice,
		Lifecycle,
		Raw,
		FakeConnectedDevice,
		WriteOptions,
	} from '@psdk/frame-father';
	import {
		CBar,
		CBox,
		CForm,
		CImage,
		CLine,
		CCodeRotation,
		CCodeType,
		CPage,
		CText,
		CFont,
		CBold,
		CRotation,
		CInverse,
		CMag,
	} from "@psdk/cpcl";
	import {
		TBar,
		TBarCode,
		TQRCode,
		TBox,
		TImage,
		TPage,
		TRotation,
		TCodeType,
		TLine,
		TText,
		TFont,
		TTLine,
	} from "@psdk/tspl";
	import {
		EImage
	} from "@psdk/esc";
	async function initState(vm) {
		//uniapp自带的蓝牙方法只支持ble蓝牙(发送数据效率慢)，开发者如果只需要运行成安卓app可以参考classic.vue页面(是通过经典蓝牙的插件调用原生的方法实现的，打印速度比较快)
		vm.bluetooth = new UniappBleBluetooth({
			allowedWriteCharacteristic: '49535343-8841-43F4-A8D4-ECBE34729BB3',
			allowedReadCharacteristic: '49535343-1e4d-4bd9-ba61-23c647249616',
			allowNoName: false,
		});
		vm.bluetooth.discovered((devices) => {
			vm.discoveredDevices.push(...devices);

		});
	}
	async function discoveryDevices(vm) {
		await vm.bluetooth.startDiscovery();
	}


	export default {
		data() {
			return {
				discoveredDevices: [],
				connectedDeviceId: "",
				cpcl: null,
				connectedDevice: null,
				items: [{
						type: 'tspl',
						checked: 'true',
					},
					{
						type: 'cpcl',
					},
					{
						type: 'esc',
					},
				],
				current: 0,
			}
		},
		async onLoad() {
			await initState(this);
		},
		methods: {
			radioChange(evt) {
				console.log(evt.detail.value);
				for (let i = 0; i < this.items.length; i++) {
					if (this.items[i].type === evt.detail.value) {
						this.current = i;
						console.log(i);
						break;
					}
				}
			},
			async discovery() {
				const vm = this;
				try {
					console.log('start discovery devices');
					vm.discoveredDevices = [];
					await discoveryDevices(vm);
				} catch (e) {
					console.error(e);
				}
			},
			async closeBluetooth() {
				const vm = this;
				try {
					console.log('closeBluetooth');
					if (vm.connectedDevice != null) {
						vm.connectedDevice.disconnect();
						vm.connectedDevice = null;
						vm.connectedDeviceId = "";
					}

				} catch (e) {
					console.error(e);
				}
			},
			async connectDevice(device) {
				const vm = this;
				try {
					uni.showLoading({
						title: '连接中'
					});
					vm.connectedDevice = await vm.bluetooth.connect(device);
					console.log(vm.connectedDevice);
					vm.$printer.init(vm.connectedDevice);
					await Timeout.set(500);
					//监听打印机返回的数据
					// vm.connectedDevice.notify((res) => {
					// 	console.log(res.characteristicId);
					// 	console.log(res);
					// 	console.log("Length:" + res.value.byteLength)
					// 	console.log("hexvalue:" + this.ab2hex(res.value))
					// 	const hex = this.ab2hex(res.value)
					// 	console.log("strvalue:" + this.hexCharCodeToStr(hex));
					// });
					uni.showToast({
						title: '成功',
					});
					vm.connectedDeviceId = device.deviceId;
					await Timeout.set(500);
					uni.hideToast();
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '失败',
					});
				}
			},
			async printImage() {
				console.log("printImage")
				const vm = this;

				// 把图片画到离屏 canvas 上
				const canvas = uni.createOffscreenCanvas({
					type: '2d',
					width: 608,
					height: 1040
				});
				const ctx = canvas.getContext('2d');
				// 创建一个图片
				const image = canvas.createImage();
				// 等待图片加载
				await new Promise(resolve => {
					image.onload = resolve;
					image.src = "/static/yunda.png"; // 要加载的图片 url, 可以是base64
				});
				ctx.drawImage(image, 0, 0, 608, 1040);
				console.log("toDataURL - ", ctx.canvas.toDataURL()) // 输出的图片
				if (this.items[this.current].type == "tspl") {
					const report = await vm.$printer.tspl()
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
						.print()
						.write()
					console.log(report);
				} else if (this.items[this.current].type == "cpcl") {
					const report = await vm.$printer.cpcl()
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
						.print()
						.write()
					console.log(report);
				} else {
					// vm.$printer.init(new FakeConnectedDevice());
					const report = await vm.$printer.esc()
						.enable()
						.wakeup()
						.image(
							new EImage({
								image: canvas,
								compress: true,
							})
						)
						.lineDot(40)
						.stopJob()
						.write()
					console.log(report);
				}

			},
			// ArrayBuffer转16进度字符串示例
			ab2hex(buffer) {
				const hexArr = Array.prototype.map.call(
					new Uint8Array(buffer),
					function(bit) {
						return ('00' + bit.toString(16)).slice(-2)
					}
				)
				return hexArr.join('')
			},

			// 将16进制的内容转成我们看得懂的字符串内容
			hexCharCodeToStr(hexCharCodeStr) {
				var trimedStr = hexCharCodeStr.trim();
				var rawStr = trimedStr.substr(0, 2).toLowerCase() === "0x" ? trimedStr.substr(2) : trimedStr;
				var len = rawStr.length;
				if (len % 2 !== 0) {
					alert("存在非法字符!");
					return "";
				}
				var curCharCode;
				var resultStr = [];
				for (var i = 0; i < len; i = i + 2) {
					curCharCode = parseInt(rawStr.substr(i, 2), 16);
					resultStr.push(String.fromCharCode(curCharCode));
				}
				return resultStr.join("");
			},
			async writeModel() {
				const vm = this;
				if (this.items[this.current].type == "tspl") {
					vm.writeTsplModel();
				} else if (this.items[this.current].type == "cpcl") {
					vm.writeCpclModel();
				}
			},
			async writeCpclModel() {
				const vm = this;
				try {
					const cpcl = await vm.$printer.cpcl()
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
						.form(new CForm()) //标签纸需要加定位指令
						.print();
					console.log(cpcl.command().string());
					const report = await cpcl.write({
						enableChunkWrite: true,
						chunkSize: 100
					});
					// const report = await cpcl.write({enableChunkWrite:true,chunkSize:100});///uniapp运行成app需要分包发送，小程序不需要
					console.log(report);
					uni.showToast({
						title: '成功',
					});
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '失败',
					});
				}
			},
			async writeTsplModel() {
				const vm = this;
				try {
					const tspl = await vm.$printer.tspl()
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
						.bar(new TBar({
							x: 120,
							y: 88 + 12,
							width: 500,
							height: 2,
							line: TTLine.DOTTED_LINE,
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
							content: "",
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
							codeType: TCodeType.CODE128
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
					// const report = await tspl.write();
					const report = await tspl.write({
						enableChunkWrite: true,
						chunkSize: 100
					}); ///uniapp运行成app需要分包发送，小程序不需要
					console.log(report);
					uni.showToast({
						title: '成功',
					});
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '失败',
					});
				}
			},
			async writeTsplRibbonModel() {
				const vm = this;
				try {
					const tspl = await vm.$printer.tspl()
						.page(new TPage({
							width: 76,
							height: 130
						}))
						//注释的为热转印机器指令
						.label() //标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
						// .bline() //黑标纸打印
						// .continuous() //连续纸打印
						// .offset(0) //进纸
						// .ribbon(false) //热敏模式
						// .shift(0) //垂直偏移
						// .reference(0, 0) //相对偏移
						.qrcode(new TQRCode({
							x: 20,
							y: 20,
							content: "发发发发发",
							cellWidth: 2
						}))
						///使用自定义矢量字体SIMHEI.TTF放大倍数mulX,mulY计算方式想打多大(mm)/0.35取整，例如想打5mm字体：5/0.35=14
						.text(new TText({
							x: 320 + 8,
							y: 696 + 54,
							content: "发发发发发",
							rawFont: "SIMHEI.TTF",
							mulX: 14,
							mulY: 14
						}))
						.text(new TText({
							x: 12,
							y: 696 + 80 + 35,
							content: "发发发发发",
							rawFont: "SIMHEI.TTF",
							mulX: 14,
							mulY: 14
						}))
						.print();
					console.log(tspl.command().string());
					// const report = await tspl.write();
					const report = await tspl.write({
						enableChunkWrite: true,
						chunkSize: 100
					}); ///uniapp运行成app需要分包发送，小程序不需要
					console.log(report);
					uni.showToast({
						title: '成功',
					});
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '失败',
					});
				}
			},
		}
	}
</script>

<style>
	.button {
		margin: 10rpx;
	}

	.logo {
		height: 200rpx;
		width: 200rpx;
		margin-top: 200rpx;
		margin-left: auto;
		margin-right: auto;
		margin-bottom: 50rpx;
	}

	.text-area {
		display: flex;
		justify-content: center;
	}

	.title {
		font-size: 36rpx;
		color: #8f8f94;
	}

	.status {
		display: block;
		line-height: 35rpx;
		margin: 10rpx;
	}

	.uni-title {
		max-lines: 1;
		font-size: 30rpx;
		font-weight: 500;
		padding: 20rpx 0;
		line-height: 1.5;
	}


	.uni-list {
		background-color: #FFFFFF;
		position: relative;
		display: flex;
		flex-direction: row;
	}

	.uni-list-cell-pd {
		padding: 22rpx 30rpx;
	}
</style>