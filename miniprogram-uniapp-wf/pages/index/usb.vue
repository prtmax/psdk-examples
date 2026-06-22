<template>
	<view class="center">
		<button @click="openUSB" class="button">打开usb</button>
		<button @click="closeUSB" class="button">关闭usb</button>
		<button @click="queryStatus" class="button">查询打印机状态</button>
		<button @click="writeCpclModel" class="button">打印cpcl模版</button>
		<button @click="writeTsplModel" class="button">打印tspl模版</button>

		<view class="input-container">
			<input v-model="densityValue" type="number" placeholder="请输入浓度值（0-4）" class="density-input" min="0"
				max="4" />
		</view>
		<button @click="setDensity" class="button">A4打印机浓度设置</button>
		<button @click="printTest" class="button">打印危废模版</button>
	</view>

</template>

<script>
	import usbTool from '@/plugins/usbTool.js'
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
		CQRCode,
		CCorrectLevel,
		CSN,
		CStatus,
	} from "@psdk/cpcl";
	import {
		TBar,
		TBarCode,
		TQRCode,
		TBox,
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
				cpcl: null,
				densityValue: 0
			}
		},
		async onLoad() {
			//#ifdef APP-PLUS
			const vm = this;
			usbTool.init({
				listenUSBStatusCallback: (state) => {
					if (state == 'ATTACHED') {
						uni.showToast({ icon: 'none', title: '监测到设备！', duration: 2000 });
					} else if (state == 'DETACHED') {
						uni.showToast({ icon: 'none', title: '设备已移除！', duration: 2000 });
					}
				},
			});
			//#endif
		},
		methods: {
			async openUSB() {
				const vm = this;
				const usbOpen = await usbTool.openUsb();
				if (usbOpen) vm.$printer.init(new FakeConnectedDevice());
				uni.showToast({ icon: 'none', title: usbOpen ? '打开成功' : '打开失败', duration: 2000 });
			},
			closeUSB() {
				usbTool.closeUsb();
				uni.showToast({ icon: 'none', title: '已关闭', duration: 1500 });
			},
			async queryStatus() {
				const vm = this;
				try {
					uni.showToast({ icon: 'loading', title: '查询中...', duration: 5000 });
					const psdk = await vm.$printer.esc().clear().state();
					const cmd = Array.from(vm.uint8ArrayToSignedArray(psdk.command().binary()));
					const data = await usbTool.sendAndRead(cmd, 2000);
					uni.hideToast();
					if (data && data.length > 0) {
						const status = vm.parsePrinterStatus(data[0]);
						uni.showToast({ title: status.statusText, icon: status.isOK ? 'success' : 'none', duration: 3000 });
					} else {
						uni.showToast({ icon: 'none', title: '无返回数据', duration: 2000 });
					}
				} catch (e) {
					uni.hideToast();
					uni.showToast({ icon: 'none', title: '查询失败', duration: 2000 });
				}
			},
			parsePrinterStatus(byteVal) {
				const states = [];
				let isOK = true;
				const byte0 = byteVal & 0xFF;
				if ((byte0 & 0x01) === 0x01) { states.push("正在打印"); isOK = false; }
				if ((byte0 & 0x02) === 0x02) { states.push("纸舱盖开"); isOK = false; }
				if ((byte0 & 0x04) === 0x04) { states.push("缺纸"); isOK = false; }
				if ((byte0 & 0x08) === 0x08) { states.push("电池电压低"); isOK = false; }
				if ((byte0 & 0x10) === 0x10) { states.push("打印头过热"); isOK = false; }
				if (isOK) states.push("状态良好");
				return { statusText: states.join("、"), isOK, states };
			},
			byteArrayToString(bytes) {
				let str = '';
				for (let b of bytes) str += String.fromCharCode(b);
				return str.trim();
			},
			  },
			async sendMessage(cmd) {
				const result = usbTool.sendByteData(cmd);
				uni.showToast({ icon: 'none', title: result ? '已发送' : '发送失败', duration: 1500 });
			},
			async writeModel1() {
				const vm = this;
				for (let i = 0; i < 5; i++) {
					await vm.writeCpclModel();
				}
			},
			//如果自己有字符串或者字节数据 可以按照这个这样传来打印
			async printTest() {
				const vm = this;
				try {
					//字节数据
					const psdk1 = await vm.$printer.tspl()
						.raw(Raw.binary(new Uint8Array([0x10, 0xFF, 0x10, 0x00, this.densityValue])));
					var binary1 = psdk1.command().binary();
					await this.sendMessage(Array.from(this.uint8ArrayToSignedArray(binary1)));
					//字符串
					const psdk = await vm.$printer.tspl()
						.raw(Raw.text("! 0 300 300 2400 1\n" +
							"PAGE-WIDTH 2400\n" +
							"GAP-SENSE\n" +
							"SETBOLD 1\n" +
							"SETMAG 2 2\n" +
							"T 2 0 540 396 废物名称内容\n" +
							"T 2 0 540 528 废物类别内容\n" +
							"T 1 0 540 660 废物代码内容\n" +
							"T 2 0 1260 660 废物形态内容\n" +
							"T 2 0 540 816 主要成分内容\n" +
							"T 2 0 540 1092 有害成分内容\n" +
							"T 2 0 540 1368 注意事项内容\n" +
							"T 1 0 576 1656 数字识别码内容\n" +
							"T 2 0 660 1776 产生/收集单位内容\n" +
							"T 2 0 792 1920 联系人和联系方式内容\n" +
							"T 1 0 480 2064 产生日期内容\n" +
							"T 2 0 1224 2064 废物重量内容\n" +
							"SETBOLD 0\n" +
							"SETMAG 1 1\n" +
							"T 1 3 324 2208 备注内容\n" +
							"BARCODE QR 1776 1776 M 2 U 15\n" +
							"L0, https://wfqr.qrprt.com/id=00000000000000000\n" +
							"ENDQR\n" +
							"PRINT\n"));
					var binary = psdk.command().binary();
					await this.sendMessage(Array.from(this.uint8ArrayToSignedArray(binary)));
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '失败'
					});
				}
			},
			async writeCpclModel() {
				const vm = this;
				try {
					const dot = 8; // 点密度：可切换 12 或 8
					const cpcl = await vm.$printer.cpcl().clear()
					  .page(new CPage({
					    width: 200 * dot,    // 200mm 宽度
					    height: 200 * dot,   // 200mm 高度
					  }))
					  .bold(true)
								
					  // 废物名称
					  .text(new CText({
					    x: 45 * dot,
					    y: 33 * dot,
					    content: "废物名称内容",
					    font: CFont.TSS32
					  }))
					  // 废物类别
					  .text(new CText({
					    x: 45 * dot,
					    y: 44 * dot,
					    content: "废物类别内容",
					    font: CFont.TSS32
					  }))
					  // 废物代码
					  .text(new CText({
					    x: 45 * dot,
					    y: 55 * dot,
					    content: "废物代码内容",
					    font: CFont.TSS24
					  }))
					  // 废物形态
					  .text(new CText({
					    x: 105 * dot,
					    y: 55 * dot,
					    content: "废物形态内容",
					    font: CFont.TSS32
					  }))
					  // 主要成分
					  .text(new CText({
					    x: 45 * dot,
					    y: 68 * dot,
					    content: "主要成分内容",
					    font: CFont.TSS32
					  }))
					  // 有害成分
					  .text(new CText({
					    x: 45 * dot,
					    y: 91 * dot,
					    content: "有害成分内容",
					    font: CFont.TSS32
					  }))
					  // 注意事项
					  .text(new CText({
					    x: 45 * dot,
					    y: 114 * dot,
					    content: "注意事项内容",
					    font: CFont.TSS32
					  }))
					  // 数字识别码
					  .text(new CText({
					    x: 48 * dot,
					    y: 138 * dot,
					    content: "数字识别码内容",
					    font: CFont.TSS24
					  }))
					  // 产生/收集单位
					  .text(new CText({
					    x: 55 * dot,
					    y: 148 * dot,
					    content: "产生/收集单位内容",
					    font: CFont.TSS32
					  }))
					  // 联系人和联系方式
					  .text(new CText({
					    x: 66 * dot,
					    y: 160 * dot,
					    content: "联系人和联系方式内容",
					    font: CFont.TSS32
					  }))
					  // 产生日期
					  .text(new CText({
					    x: 40 * dot,
					    y: 172 * dot,
					    content: "产生日期内容",
					    font: CFont.TSS24
					  }))
					  // 废物重量
					  .text(new CText({
					    x: 102 * dot,
					    y: 172 * dot,
					    content: "废物重量内容",
					    font: CFont.TSS32
					  }))
								
					  // 取消加粗、恢复字号
					  .bold(false)
								
					  // 备注
					  .text(new CText({
					    x: 27 * dot,
					    y: 184 * dot,
					    content: "备注内容",
					    font: CFont.TSS24,
					  }))
								
					  // 二维码
					  .qrcode(new CQRCode({
					    x: 148 * dot,
					    y: 148 * dot,
					    width: 9,
					    content: "https://wfqr.qrprt.com/id=00000000000000000",
					  }))
								
					  .form(new CForm())
					  .print();
					console.log(cpcl.command().string());
					var binary = cpcl.command().binary();
					await this.sendMessage(Array.from(this.uint8ArrayToSignedArray(binary)));
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '失败',
					});
				}
			},
			///转成安卓有符号的
			uint8ArrayToSignedArray(uint8Array) {
				let signedArray = new Array(uint8Array.length);
				for (let i = 0; i < uint8Array.length; i++) {
					if (uint8Array[i] >= 128) {
						signedArray[i] = uint8Array[i] - 256;
					} else {
						signedArray[i] = uint8Array[i];
					}
				}
				return signedArray;
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
					await this.sendMessage(Array.from(this.uint8ArrayToSignedArray(binary)));
				} catch (e) {
					console.error(e);
					usbTool.shortToast(e + "")
				}
			},
			async setDensity() {
				const vm = this;
				try {
					const density = Number(vm.densityValue);
					if (isNaN(density)) {
						uni.showToast({
							title: '请输入有效的数字',
							icon: 'none'
						});
						return;
					}
					if (density < 0 || density > 4) {
						uni.showToast({
							title: '浓度值请输入0-4之间',
							icon: 'none'
						});
						return;
					}

					const esc = await vm.$printer.esc().clear()
						.thickness(density);
					var binary = esc.command().binary();
					await this.sendMessage(Array.from(this.uint8ArrayToSignedArray(binary)));
					uni.showToast({
						title: `浓度已设置为${density}`,
						icon: 'success'
					});
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '设置失败',
						icon: 'none'
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

	.input-container {
		margin: 10rpx;
	}

	.density-input {
		border: 1px solid #ccc;
		border-radius: 8rpx;
		padding: 15rpx;
		font-size: 28rpx;
		width: 100%;
		height: 80rpx;
		box-sizing: border-box;
	}
</style>