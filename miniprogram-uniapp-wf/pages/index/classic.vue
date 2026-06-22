<template>
	<view class="center">
		<button @click="discovery" class="button">开始搜索</button>
		<button @click="closeBluetooth" class="button">断开连接</button>
		<button @click="writeCpclModel" class="button">打印cpcl模版</button>
		<button @click="writeTsplModel" class="button">打印tspl模版</button>

		<view class="input-container">
			<input v-model="densityValue" type="number" placeholder="请输入浓度值（0-4）" class="density-input" min="0"
				max="4" />
		</view>
		<button @click="setDensity" class="button">A4打印机浓度设置</button>
		<button @click="getDensity" class="button">A4打印机浓度查询</button>
		<button @click="queryPrinterStatus" class="button">查询打印机状态</button>
		<button @click="printTest" class="button">打印危废模版</button>
		<scroll-view class="canvas-buttons" scroll-y="true">
			<block v-for="(item, index) in discoveredDevices" :key="item.address">
				<text class="status">设备名称:{{item.name}}</text>
				<text class="status">设备ID:{{item.address}}</text>
				<text class="status">连接状态:{{connectedDeviceId == item.address?"已连接":"未连接"}}</text>
				<button type="warn" class="button" @click="connectBT(item)">连接</button>
			</block>
		</scroll-view>
	</view>

</template>

<script>
	import bluetoothTool from '@/plugins/BluetoothTool.js'
	import permission from '@/plugins/permission.js'
	import {
		InputImage
	} from '@psdk/frame-imageb';
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
		EImage,
		EPaperTypeQ3,
		PaperTypeQ3
	} from "@psdk/esc";
	import {
		PaperType
	} from '@psdk/esc/build/types';

	export default {
		data() {
			return {
				discoveredDevices: [],
				connectedDeviceId: "",
				cpcl: null,
				current: 0,
				densityValue: 0
			}
		},
		async onLoad() {
			//#ifdef APP-PLUS
			// 蓝牙
			bluetoothTool.init({
				listenBTStatusCallback: (state) => {
					if (state == 'STATE_ON') {
						console.log(state);
					}
				},
				discoveryDeviceCallback: this.onDevice,
				discoveryFinishedCallback: function() {
					console.log("搜索完成");
				},
				readDataCallback: async (dataByteArr) => {
				  const vm = this;
				  console.log("收到打印机数据：", dataByteArr);
				  
				  // 状态查询的返回数据解析
				  if (dataByteArr.length === 1) {
				    const states = [];
				    let isOK = true;
				    const byte0 = dataByteArr[0] & 0xFF; // 确保是无符号字节
				    
				    if ((byte0 & 0x01) === 0x01) {
				      states.push("正在打印");
				      isOK = false;
				    }
				    if ((byte0 & 0x02) === 0x02) {
				      states.push("纸舱盖开");
				      isOK = false;
				    }
				    if ((byte0 & 0x04) === 0x04) {
				      states.push("缺纸");
				      isOK = false;
				    }
				    if ((byte0 & 0x08) === 0x08) {
				      states.push("电池电压低");
				      isOK = false;
				    }
				    if ((byte0 & 0x10) === 0x10) {
				      states.push("打印头过热");
				      isOK = false;
				    }
				    if (isOK) {
				      states.push("状态良好");
				    }
				
				    const statusText = states.join("、");
				    console.log("打印机状态解析结果：", statusText);
				    uni.showToast({
				      title: statusText,
				      icon: isOK ? 'success' : 'none',
				      duration: 3000
				    });
				  }
				},
				connExceptionCallback: function(e) {
					console.log(e);
				}
			});
			//#endif
		},
		methods: {
			async checkPermission() {
				try {
					let checkResult = await permission.androidPermissionCheck("bluetooth");
					console.log("检测信息：", checkResult);
					if (checkResult.code == 1) {
						let result = checkResult.data;
						if (result == 1) {
							console.log("授权成功!");
						}
						if (result == 0) {
							console.log("授权已拒绝!");
						}
						if (result == -1) {
							console.log("您已永久拒绝权限，请在应用设置中手动打开!");
						}
					}
				} catch (err) {
					console.log("授权失败：", err);
				}
			},
			async discovery() {
				var that = this
				// 使用openBluetoothAdapter 接口，免去主动申请权限的麻烦
				uni.openBluetoothAdapter({
					success: async (res) => {
						await this.checkPermission();
						console.log('start discovery devices');
						this.discoveredDevices = [];
						console.log(res)
						bluetoothTool.discoveryNewDevice();
					}
				})
			},
			onDevice(device) {
				console.log("监听寻找到新设备的事件---------------")
				console.log(device)
				if (typeof device === 'undefined') return;
				if (typeof device.name === 'undefined') return;
				console.log(device.name);
				if (device.name === '') return;
				if (device.name === null) return;
				if (device.name.toUpperCase().endsWith('_BLE') ||
					device.name.toUpperCase().endsWith('-LE') ||
					device.name.toUpperCase().endsWith('-BLE')) return;
				const isDuplicate = this.discoveredDevices.find(item => item.address === device.address);
				if (isDuplicate) return;
				this.discoveredDevices.push(device);
			},
			connectBT(device) {
				const vm = this;
				uni.showLoading({
					title: '连接中'
				});

				bluetoothTool.connDevice(device.address, (result) => {
					uni.hideLoading()
					if (result) {
						console.log(result);
						bluetoothTool.cancelDiscovery();
						vm.$printer.init(new FakeConnectedDevice());
						vm.connectedDeviceId = device.address;
						uni.showToast({
							icon: 'none',
							title: '连接成功'
						})
					} else {
						uni.showToast({
							icon: 'none',
							title: '连接失败'
						})
					}
				});
			},
			async requestLocation() {
				return new Promise((resolve, reject) => {
					uni.getLocation({
						success: () => resolve(),
						// @ts-ignore
						fail: (e) => reject(e),
					});
				});
			},
			stopSearchBT() {
				console.log("停止搜寻附近的蓝牙外围设备---------------")
				bluetoothTool.cancelDiscovery();
			},
			closeBluetooth() {
				const vm = this;
				if (vm.connectedDeviceId != '') {
					bluetoothTool.closeBtSocket();
					vm.connectedDeviceId = "";
				}
			},
			async sendMessage(cmd) {
				const vm = this;
				console.log(cmd);
				const result = bluetoothTool.sendByteData(Array.from(vm.uint8ArrayToSignedArray(cmd)));
				uni.showToast({
					icon: 'none',
					title: result ? '发送成功！' : '发送失败...'
				})
			},
			async queryPrinterStatus() {
			  const vm = this;
			  try {
			    // 发送状态查询指令
			    const psdk = await vm.$printer.esc().clear().state();
			    const binary = psdk.command().binary();
			    await this.sendMessage(binary);
			
			    uni.showToast({ title: '状态查询指令已发送', icon: 'none' });
			  } catch (e) {
			    console.error(e);
			    uni.showToast({ title: '状态查询失败' });
			  }
			},
			//如果自己有字符串或者字节数据 可以按照这个这样传来打印
			async printTest() {
				const vm = this;
				try {
					//字节数据
					// const psdk1 = await vm.$printer.tspl()
					// 	.raw(Raw.binary(new Uint8Array([0x10, 0xFF, 0x10, 0x00, this.densityValue])));
					// var binary1 = psdk1.command().binary();
					// await this.sendMessage(Array.from(this.uint8ArrayToSignedArray(binary1)));
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
							"FORM\n" +
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
			async writeModel1() {
				const vm = this;
				for (let i = 0; i < 5; i++) {
					await vm.writeCpclModel();
				}
			},

			async writeModel() {
				const vm = this;
				if (this.items[this.current].type == "tspl") {
					await vm.writeTsplModel();
				} else if (this.items[this.current].type == "cpcl") {
					await vm.writeCpclModel();
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
			    const binary = cpcl.command().binary();
			    await this.sendMessage(binary);
			
			    uni.showToast({ title: '打印成功', icon: 'success' });
			  } catch (e) {
			    console.error(e);
			    uni.showToast({ title: '打印失败' });
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
						.cls()
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
					uni.showToast({
						title: '失败',
					});
				}
			},
			async writeTsplRibbonModel() {
				const vm = this;
				try {
					const tspl = await vm.$printer.tspl().clear()
						.page(new TPage({
							width: 76,
							height: 130
						}))
						// .raw(Raw.text('CODEPAGE UTF-8'))
						//注释的为热转印机器指令
						// .label() //标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
						// .bline() //黑标纸打印
						.continuous() //连续纸打印
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
						// .text(
						// 	new TText({
						// 		x: 250,
						// 		y: 50,
						// 		mulX: 20,
						// 		mulY: 20,
						// 		rotation: 90,
						// 		content: '收货人姓名,总件数,电话',
						// 		rawFont: 'SIMHEI.TTF',
						// 		charset: 'utf-8'
						// 	})
						// )
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
					var binary = tspl.command().binary();
					await this.sendMessage(binary);
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '失败',
					});
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
			async getDensity() {
				const vm = this;
				try {
					const psdk1 = await vm.$printer.tspl()
						.raw(Raw.binary(new Uint8Array([0x10, 0xFF, 0x11])));
					var binary1 = psdk1.command().binary();
					await this.sendMessage(Array.from(this.uint8ArrayToSignedArray(binary1)));
				} catch (e) {
					console.error(e);
					uni.showToast({
						title: '获取失败',
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