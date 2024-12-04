<template>
	<view class="container">
		<view>
			<text>机器码:</text>
			<input v-model="sn" placeholder="请输入机器码" />
		</view>
		<button @click="writeModel" class="button">云打印模版</button>
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
				sn: 'SW244100075',
			}
		},
		async onLoad() {
			const vm = this;
			vm.$printer.init(new FakeConnectedDevice());
		},
		methods: {
			async sendMessage(cmd) {
				console.log(cmd,);
				// uni.getStorageSync('tempFilePath')
				// const fsm = uni.getFileSystemManager();
				// const filePath = `${uni.env.USER_DATA_PATH}/myfile.txt`; // 设置文件路径
				// fsm.writeFile({
				// 　　　　filePath,
				// 　　　　data: cmd,
				// 　　　　encoding: 'binary',
				// 　　　　success() {
				// 　　　　　　console.log('File成功');
				// 　　　　},
				// 　　　　fail() {
				// 　　　　　　return (new Error('ERROR_BASE64SRC_WRITE'));
				// 　　　　},
				// 　　});
				const url = 'https://wiot.iprtapp.com/sw/api/message/printMsg';
				uni.request({
				  url: url,
				  method: 'POST',
				  data: {
				    devid: 'SW244100075',
				    reqid: 'e970e65af9bd4dfb9400d896607bc812',
				    message: cmd,
				    type: 3,
				    orderid: '30220191208161723852129466170919',
				    pcopy: 1,
				    pwidth: 76,
				    ptype: 2,
				    vtype: -1,
				    vmessage: '0'
				  },
				  success: function(res) {
				    console.log('请求成功', res.data);
				  },
				  fail: function(err) {
				    console.error('请求失败', err);
				  }
				});
				// uni.uploadFile({
				// 	url: url, // 上传地址
				// 	filePath: file,
				// 	name: 'file', // 后端接收文件的字段名
				// 	header: {
				// 		'Content-Type': 'multipart/form-data'
				// 	},
				// 	formData: {
				// 		devid: this.sn,
				// 		type: 1,
				// 		width: 100,
				// 		height: 100,
				// 	},
				// 	success: (res) => {
				// 		console.log('上传成功', res);
				// 	},
				// 	fail: (err) => {
				// 		console.error('上传失败', err);
				// 	},
				// 	complete: () => {
				// 	}
				// });
			},
			async writeModel() {
				const vm = this;
				await vm.writeTsplModel();
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
					await this.sendMessage(tspl.command().string());
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
					await this.sendMessage(binary.buffer);
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
</style>