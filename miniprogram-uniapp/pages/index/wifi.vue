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
		<view>
			<text>机器码:</text>
			<input v-model="sn" placeholder="请输入机器码" />
		</view>
		<button @click="writeModel" class="button">云打印模版</button>
		<button @click="printImage" class="button">云打印图片</button>
		<canvas :style="'width: ' + canvasWidth + 'px; height: ' + canvasHeight + 'px; position: fixed; left: 8888px'":canvas-id="canvasId"></canvas>
	</view>
</template>

<script>
	import Timeout from 'await-timeout';
	import {
		ConnectedDevice,
		Lifecycle,
		Raw,
		FakeConnectedDevice,
		WriteOptions,
	} from '@psdk/frame-father';
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
	export default {
		data() {
			return {
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
				sn: 'SW244100075',
				canvasId: 'myCanvas',
				canvasWidth: 240,
				canvasHeight: 240,
			}
		},
		async onLoad() {
			const vm = this;
			vm.$printer.init(new FakeConnectedDevice());
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
			async printImage() {
				const vm = this;
				const ctx = uni.createCanvasContext(vm.canvasId, this);
				const imgWidth = vm.canvasWidth; // 每张图片的宽度跟画布宽度一样
				const imgHeight = vm.canvasWidth; // 每张图片的高度跟画布高度一样
				ctx.drawImage('/static/logo.png', 0, 0, imgWidth, imgHeight);
				await new Promise((resolve) => {
					ctx.draw(false, resolve);
				});
				const res = await new Promise((resolve, reject) => {
					uni.canvasGetImageData({
						canvasId: vm.canvasId,
						x: 0,
						y: 0,
						width: imgWidth,
						height: imgHeight,
						success: resolve,
						fail: reject
					});
				});
				const input = new InputImage({
					data: res.data,
					width: res.width,
					height: res.height,
				});
				if (this.items[this.current].type === "tspl") {
					const tspl = await vm.$printer.tspl().clear()
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
								image: input
							})
						)
						.print();
					const binary = tspl.command().binary();
					await vm.sendMessage(binary);
				} else if (this.items[this.current].type === "cpcl") {
					const cpcl = await vm.$printer.cpcl().clear()
						.page(new CPage({
							width: 608,
							height: 1040
						}))
						.image(
							new CImage({
								x: 0,
								y: 0,
								compress: false,
								image: input
							})
						)
						.print();
					const binary = cpcl.command().binary();
					await vm.sendMessage(binary);
				} else {
					const esc = await vm.$printer.esc().clear()
						.enable()
						.wakeup()
						.image(
							new EImage({
								image: input,
								compress: true,
							})
						)
						.lineDot(40)
						.stopJob();
					const binary = esc.command().binary();
					await vm.sendMessage(binary);
				}
			},
			async sendMessage(cmd) {
				const vm = this;
				console.log(cmd);
				const base64 = uni.arrayBufferToBase64(cmd.buffer);
				console.log(`data:image/png;base64,`+base64);
				base64ToPath(`data:image/png;base64,`+base64)
				  .then(path => {
				    console.log(path)
					const url = 'https://wiot.iprtapp.com/sw/files/ptFile';
					uni.uploadFile({
						url: url, // 上传地址
						filePath: path,
						name: 'file', // 后端接收文件的字段名
						formData: {
							devid: vm.sn,
							type: 1,// type必须用1
							width: 100,
							height: 100,
						},
						success: (res) => {
							console.log('上传成功', res);
						},
						fail: (err) => {
							console.error('上传失败', err);
						},
						complete: () => {}
					});
				  })
				  .catch(err => {
				    console.error('上传失败', err);
				  })
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
					const cpcl = await vm.$printer.cpcl().clear()
						.page(new CPage({
							width: 608,
							height: 1040
						}))
						.qrcode(new CQRCode({
							x: 54,
							y: 480,
							width: 10,
							content: "PDDZDA00017106",
							codeRotation: CCodeRotation.ROTATION_0,
							level: CCorrectLevel.L
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
						.mag(new CMag({
							font: CFont.TSS24_MAX2
						})) //字号有用到MAX的或者使用MAX后要恢复成没有MAX的需要加个mag指令
						.text(new CText({
							x: 598 - 56 - 16 - 120 + 17,
							y: 696 + 80 + 136 + 11 + 6,
							content: "已验视",
							font: CFont.TSS24_MAX2
						}))
						.mag(new CMag({
							font: CFont.TSS24
						}))
						.form(new CForm()) //标签纸需要加定位指令
						.print();
					console.log(cpcl.command().string());
					var binary = cpcl.command().binary();
					await this.sendMessage(binary);
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
					const tspl = await vm.$printer.tspl().clear()
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
					var binary = tspl.command().binary();
					await this.sendMessage(binary);
				} catch (e) {
					console.error(e);
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
					var binary = cpcl.command().binary();
					await this.sendMessage(binary);
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
	.container {
		padding: 20px;
	}

	input {
		margin: 5px 0;
	}

	button {
		margin: 10px 0;
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