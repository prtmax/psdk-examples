<template>
	<view class="center">
		<button @click="discovery" class="button">开始搜索</button>
		<button @click="closeBluetooth" class="button">关闭蓝牙适配器</button>
		<button @click="write160Model" class="button">打印160模版</button>
		<button @click="printImage" class="button">打印Logo</button>
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
		Raw
	} from '@psdk/frame-father';
	import {
		CBar,
		CBox,
		CForm,
		CImage,
		CLine,
		CodeRotation,
		CodeType,
		CPage,
		CText,
		Font
	} from "@psdk/cpcl";
	async function initState(vm) {
		vm.bluetooth = new UniappBleBluetooth({
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
			}
		},
		async onLoad() {
			await initState(this);
		},
		methods: {
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
			async connectDevice(device) {
				const vm = this;
				try {
					uni.showLoading({
						title: '连接中'
					});
					const connectDevice = await vm.bluetooth.connect(device);
					console.log(connectDevice);
					if (!connectDevice.canRead()) {
						uni.showToast({
							title: '你的打印机不支持读取数据. 部分功能将不可用'
						});
					}
					vm.$printer.init(connectDevice);
					await Timeout.set(500);

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
					width: 20,
					height: 35
				});
				const ctx = canvas.getContext('2d');
				// 创建一个图片
				const image = canvas.createImage();
				// 等待图片加载
				await new Promise(resolve => {
					image.onload = resolve;
					image.src = "/static/xxx.png"; // 要加载的图片 url, 可以是base64
				});
				ctx.drawImage(image, 0, 0, 20, 35);
				console.log("toDataURL - ", ctx.canvas.toDataURL()) // 输出的图片
				const report = await vm.$printer.cpcl()
					.page(new CPage({
						width: 608,
						height: 1040
					}))
					.image(
						new CImage({
							x: 80,
							y: 20,
							compress: false,
							image: canvas
						})
					)
					.print()
					.write()
				console.log(report);
			},
			async write160Model() {
				const vm = this;
				try {
					const report = await vm.$printer.cpcl()
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
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 0,
							startY: 88 + 128,
							endX: 598,
							endY: 88 + 128,
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 0,
							startY: 88 + 128 + 80,
							endX: 598,
							endY: 88 + 128 + 80,
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 0,
							startY: 88 + 128 + 80 + 144,
							endX: 598 - 56 - 16,
							endY: 88 + 128 + 80 + 144,
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 0,
							startY: 88 + 128 + 80 + 144 + 128,
							endX: 598 - 56 - 16,
							endY: 88 + 128 + 80 + 144 + 128,
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 52,
							startY: 88 + 128 + 80,
							endX: 52,
							endY: 88 + 128 + 80 + 144 + 128,
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 598 - 56 - 16,
							startY: 88 + 128 + 80,
							endX: 598 - 56 - 16,
							endY: 664,
							lineWidth: 2
						}))
						.bar(new CBar({
							x: 120,
							y: 88 + 12,
							lineWidth: 1,
							height: 80,
							content: "1234567890",
							codeRotation: CodeRotation.ROTATION_0,
							codeType: CodeType.CODE128
						}))
						.text(new CText({
							x: 120 + 12,
							y: 88 + 20 + 76,
							content: "1234567890",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 12,
							y: 88 + 128 + 80 + 32,
							content: "收",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 12,
							y: 88 + 128 + 80 + 96,
							content: "件",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 12,
							y: 88 + 128 + 80 + 144 + 32,
							content: "发",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 12,
							y: 88 + 128 + 80 + 144 + 80,
							content: "件",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 52 + 20,
							y: 88 + 128 + 80 + 144 + 128 + 16,
							content: "签收人/签收时间",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 430,
							y: 88 + 128 + 80 + 144 + 128 + 36,
							content: "月",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 490,
							y: 88 + 128 + 80 + 144 + 128 + 36,
							content: "日",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 52 + 20,
							y: 88 + 128 + 80 + 24,
							content: "收姓名" + " " + "13777777777",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 52 + 20,
							y: 88 + 128 + 80 + 24 + 32,
							content: "南京市浦口区威尼斯水城七街区七街区",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 52 + 20,
							y: 88 + 128 + 80 + 144 + 24,
							content: "名字" + " " + "13777777777",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 52 + 20,
							y: 88 + 128 + 80 + 144 + 24 + 32,
							content: "南京市浦口区威尼斯水城七街区七街区",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 598 - 56 - 5,
							y: 88 + 128 + 80 + 104,
							content: "派",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 598 - 56 - 5,
							y: 88 + 128 + 80 + 160,
							content: "件",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 598 - 56 - 5,
							y: 88 + 128 + 80 + 208,
							content: "联",
							font: Font.TSS24
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
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 0,
							startY: 696 + 80 + 136,
							endX: 598 - 56 - 16,
							endY: 696 + 80 + 136,
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 52,
							startY: 80,
							endX: 52,
							endY: 696 + 80 + 136,
							lineWidth: 2
						}))
						.line(new CLine({
							startX: 598 - 56 - 16,
							startY: 80,
							endX: 598 - 56 - 16,
							endY: 968,
							lineWidth: 2
						}))
						.bar(new CBar({
							x: 320,
							y: 696 - 4,
							lineWidth: 1,
							height: 56,
							content: "1234567890",
							codeRotation: CodeRotation.ROTATION_0,
							codeType: CodeType.CODE128
						}))
						.text(new CText({
							x: 320 + 8,
							y: 696 + 54,
							content: "1234567890",
							font: Font.TSS16
						}))
						.text(new CText({
							x: 12,
							y: 696 + 80 + 35,
							content: "发",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 12,
							y: 696 + 80 + 84,
							content: "件",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 52 + 20,
							y: 696 + 80 + 28,
							content: "名字" + " " + "13777777777",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 52 + 20,
							y: 696 + 80 + 28 + 32,
							content: "南京市浦口区威尼斯水城七街区七街区",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 598 - 56 - 5,
							y: 696 + 80 + 50,
							content: "客",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 598 - 56 - 5,
							y: 696 + 80 + 82,
							content: "户",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 598 - 56 - 5,
							y: 696 + 80 + 106,
							content: "联",
							font: Font.TSS24
						}))
						.text(new CText({
							x: 12 + 8,
							y: 696 + 80 + 136 + 22 - 5,
							content: "物品：" + "几个快递" + " " + "12kg",
							font: Font.TSS24
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
							font: Font.TSS24
						}))
						.form(new CForm())
						.print()
						.write();
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

	
</style>