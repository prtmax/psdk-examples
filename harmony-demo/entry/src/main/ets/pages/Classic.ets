import DevicesPage from '../common/DevicesPage';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import { baseProfile } from '@kit.ConnectivityKit';
import { ConnectedDevice, PSDK } from '@psdk/frame-father';
import CommonUtil from '../common/CommonUtil';
import { OhosBluetoothClassic } from '@psdk/ohos-bluetooth-classic';
import { JluetoothDevice } from '@psdk/device-bluetooth-traits';
import { PrinterUtil } from '../common/PrinterUtil';
import { GenericTSPL } from '@psdk/tspl';
import { GenericCPCL } from '@psdk/cpcl';
import { GenericESC } from '@psdk/esc';
import { util } from '@kit.ArkTS';
import { PaperType } from '@psdk/esc/build/types';
import { ReadMark, ThicknessLevel } from '../common/ReadMark';


@CustomDialog
struct CustomDialogExample {
  @State inputValue: string = ''
  controller?: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: (value: string) => void = () => {
  }

  build() {
    Column() {
      Text('设置关机时间(单位：分钟，不关机传 0)').margin({ top: 30 })
      TextInput({ placeholder: '', text: this.inputValue })
        .margin({ top: 20, bottom: 30 })
        .height(45)
        .width('90%')
        .type(InputType.Number)
        .onChange((value: string) => {
          this.inputValue = value
        })
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button('取消')
          .onClick(() => {
            if (this.controller != undefined) {
              this.cancel();
              this.controller.close()
            }
          })
        Button('确定')
          .onClick(() => {
            if (this.controller != undefined) {
              this.confirm(this.inputValue);
              this.controller.close()
            }
          })
      }
    }
  }
}

@Entry
@Component
struct Index {
  @State discoveredDevices: Array<JluetoothDevice<string>> = [];
  @State connectionState: string = '未连接';
  @State connectedDevice?: ConnectedDevice = undefined;
  private suffix = ['_BLE', '-LE', '-BLE'];
  @State cmdType: string = 'tspl';
  private ohosBluetoothClassic = new OhosBluetoothClassic({ allowNoName: false });
  private isPrint = false
  private readMark?: ReadMark = undefined
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogExample({
      cancel: () => {
        this.onCancel()
      },
      confirm: (value) => {
        this.onConfirm(value)
      }
    }),
    cancel: this.onCancel,
    autoCancel: true,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      console.info("reason=" + JSON.stringify(dismissDialogAction.reason))
      console.log("dialog onWillDismiss")
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss()
      }
      if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss()
      }
    },
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    customStyle: false,
    cornerRadius: 20,
    width: 300,
    height: 200,
    backgroundColor: Color.White,
    shadow: ({
      radius: 20,
      color: Color.Grey,
      offsetX: 50,
      offsetY: 0
    }),
  })

  // 在自定义组件即将析构销毁时将dialogController置空
  // aboutToDisappear() {
  //   this.dialogController = null // 将dialogController置空
  // }
  onCancel() {
    console.info('Callback when the Cancel button is clicked')
  }

  onConfirm(value: string) {
    console.info('Callback when the Confirm button is clicked')
    this.onEscSetting(ReadMark.SetShutTime, Number(value))
  }

  aboutToAppear() {
    this.ohosBluetoothClassic.discovered(async (devices) => {
      devices.forEach(device => {
        const isBle = this.suffix.find((item) => device.name.toUpperCase().endsWith(item));
        if (isBle) {
          return;
        }
        const isDuplicate = this.discoveredDevices.find(item => item.deviceId === device.deviceId);
        if (isDuplicate) {
          return;
        }
        this.discoveredDevices.push(device);
      });
    });
    console.info('IndexComponent aboutToAppear');
  }

  onConnectionStateEvent = (data: baseProfile.StateChangeParam) => {
    console.info('a2dp state = ' + JSON.stringify(data));
  }

  aboutToDisappear() {
    console.info('IndexComponent aboutToDisappear');
  }

  async discovery() {
    this.discoveredDevices = [];
    try {
      await this.ohosBluetoothClassic.startDiscovery();
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: `errCode: ${(err as BusinessError).code} , errMessage: ${(err as BusinessError).message}`,
        duration: 2000
      });
    }
  }

  dataRead = (dataBuffer: ArrayBuffer) => {
    let data = new Uint8Array(dataBuffer);
    console.log('bluetooth data is: ' + data[0]);
  }

  async onConnect(device: JluetoothDevice<string>) {
    try {
      promptAction.showToast({
        message: `连接中。。。。`,
        duration: 2000
      });
      this.connectedDevice = await this.ohosBluetoothClassic.connect(device);
      PrinterUtil.getInstance().init(this.connectedDevice);
      this.connectionState = `${this.connectedDevice.deviceName()}已连接`;
      promptAction.showToast({
        message: `${this.connectedDevice.deviceName()}连接成功`,
        duration: 2000
      });
      console.log("this.connectedDevice: ", this.connectedDevice);
      this.listenNotify();
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      promptAction.showToast({
        message: '连接失败',
        duration: 2000
      });
    }
  }

  listenNotify() {
    if (!this.connectedDevice) {
      return;
    }
    // listen printer data
    this.connectedDevice.notify(async (data: Uint8Array) => {
      const duration = 3000;
      const str = new util.TextDecoder("utf-8", { ignoreBOM: true }).decodeWithStream(data)
      // 主动查询
      if (this.readMark !== undefined) {
        switch (this.readMark) {
          case ReadMark.Info:
            promptAction.showToast({
              message: `打印机信息：${str}`,
              duration: duration
            });
            break;
          case ReadMark.SN:
            promptAction.showToast({
              message: `打印机SN：${str}`,
              duration: duration
            });
            break;
          case ReadMark.Mac:
            promptAction.showToast({
              message: `打印机Mac：${data.toString()}`,
              duration: duration
            });
            break;
          case ReadMark.State:
            switch (this.cmdType) {
              case 'tspl':
                this.handleTSPLStatus(data);
                break;
              case 'cpcl':
                this.handleCPCLStatus(data);
                break;
              case 'esc':
                this.handleESCStatus(data);
                break;
              default:
                break;
            }
            break;
          case ReadMark.Version:
            promptAction.showToast({
              message: `打印机固件版本：${str}`,
              duration: duration
            });
            break;
          case ReadMark.Model:
            promptAction.showToast({
              message: `打印机型号：${data}`,
              duration: duration
            });
            break;
          case ReadMark.BatteryVolume:
            promptAction.showToast({
              message: `打印机电量: ${data[1]}%`,
              duration: duration
            });
            break;
          case ReadMark.GetShutTime:
            promptAction.showToast({
              message: `关机时间: ${data[1]} 分钟`,
              duration: duration
            });
            break;
          case ReadMark.BtName:
            promptAction.showToast({
              message: `蓝牙名称：${str}`,
              duration: duration
            });
            break;
          case ReadMark.Thickness:
            if (str === 'OK') {
              promptAction.showToast({
                message: `打印机浓度设置成功`,
                duration: duration
              });
            } else {
              console.log('设置失败')
            }
            break;
          case ReadMark.SetShutTime:
            if (str === 'OK') {
              promptAction.showToast({
                message: `设置关机时间成功`,
                duration: duration
              });
            } else {
              console.log('设置失败')
            }
            break;
        }
        this.readMark = undefined;
      }
      // 打印机主动上报
      /// 主动上报纸张类型
      if (data.length == 2 && data[0] === 0xFE) {
        switch (data[1]) {
          case 1:
            console.log("onPaperError: 折叠黑标纸")
            break;
          case 2:
            console.log("onPaperError: 连续卷简纸")
            break;
          case 3:
            console.log("onPaperError: 不干胶缝隙纸")
            break;
          default:
            break;
        }
      }

      /// 上报设备状态
      if (data.length == 2 && data[0] === 0xFF) {
        if ((data[1]) == 0) {
          console.log("打印机正常")
        } else {
          if ((data[1] & 0x01) === 0x01) {
            console.log("打印机过热")
          }
          if ((data[1] & 0x02) === 0x02) {
            console.log("打印机开盖")
          }
          if ((data[1] & 0x04) === 0x04) {
            console.log("打印机缺纸")
          }
          if ((data[1] & 0x08) === 0x08) {
            console.log("打印机低压")
          }
          if ((data[1] & 0x10) === 0x10) {
            console.log("请使用PikDik品牌标签，获得更好的打印体验")
          }
        }
      }
      /// 上报中止打印机状态命令
      if (data.length == 2 && data[0] === 0xFD) {
        switch (data[1]) {
          case 1:
            console.log("开始清除当前页面打印任务（中止命令）")
            break;
          case 2:
            console.log("清除当前打印任务结束")
            break;
          default:
            break;
        }
      }
    });
  }

  async doTSPLStatus(data: Uint8Array) {
    const duration = 3000;
    if (data.length == 1) {
      if (data[0] == 0x00) {
        promptAction.showToast({
          message: '状态：打印机正常',
          duration: duration
        });
      }
      if ((data[0] & 0x01) == 0x01) {
        promptAction.showToast({
          message: '状态：打印机开盖',
          duration: duration
        });
      }
      if ((data[0] & 0x02) == 0x02) {
        promptAction.showToast({
          message: '状态：纸张错误',
          duration: duration
        });
      }
      if ((data[0] & 0x04) == 0x04) {
        promptAction.showToast({
          message: '状态：打印机缺纸',
          duration: duration
        });
      }
      if ((data[0] & 0x20) == 0x20) {
        promptAction.showToast({
          message: '状态：打印机打印中',
          duration: duration
        });
      }
      if ((data[0] & 0x10) == 0x10) {
        promptAction.showToast({
          message: '状态：打印机暂停',
          duration: duration
        });
      }
      if ((data[0] & 0x80) == 0x80) {
        promptAction.showToast({
          message: '状态：打印机过热',
          duration: duration
        });
      }
    }
  }

  async handleTSPLStatus(data: Uint8Array) {
    const duration = 3000;
    if (data.length == 1) {
      if (data[0] == 0x00) {
        promptAction.showToast({
          message: '状态：打印机正常',
          duration: duration
        });
      }
      if ((data[0] & 0x01) == 0x01) {
        promptAction.showToast({
          message: '状态：打印机开盖',
          duration: duration
        });
      }
      if ((data[0] & 0x02) == 0x02) {
        promptAction.showToast({
          message: '状态：纸张错误',
          duration: duration
        });
      }
      if ((data[0] & 0x04) == 0x04) {
        promptAction.showToast({
          message: '状态：打印机缺纸',
          duration: duration
        });
      }
      if ((data[0] & 0x20) == 0x20) {
        promptAction.showToast({
          message: '状态：打印机打印中',
          duration: duration
        });
      }
      if ((data[0] & 0x10) == 0x10) {
        promptAction.showToast({
          message: '状态：打印机暂停',
          duration: duration
        });
      }
      if ((data[0] & 0x80) == 0x80) {
        promptAction.showToast({
          message: '状态：打印机过热',
          duration: duration
        });
      }
    }
  }

  async handleCPCLStatus(data: Uint8Array) {
    const duration = 3000;
    if (data[0] == 0x00) {
      promptAction.showToast({
        message: '状态：正常',
        duration: duration
      });
      return;
    }
    if (data.length > 1 && data[0] == 0x4f && data[1] == 0x4b) {
      promptAction.showToast({
        message: '状态：正常',
        duration: duration
      });
      return;
    }
    if ((data[0] & 16) != 0) {
      promptAction.showToast({
        message: '状态：开盖',
        duration: duration
      });
      return;
    }
    if ((data[0] & 1) != 0) {
      promptAction.showToast({
        message: '状态：缺纸',
        duration: duration
      });
      return;
    }
    if ((data[0] & 8) != 0) {
      promptAction.showToast({
        message: '状态：打印中',
        duration: duration
      });
      return;
    }
    if ((data[0] & 4) != 0) {
      promptAction.showToast({
        message: '状态：低电',
        duration: duration
      });
      return;
    }
    promptAction.showToast({
      message: '状态：正常',
      duration: duration
    });
  }

  async handleESCStatus(data: Uint8Array) {
    const duration = 3000;
    let states = ['正常'];
    if ((data[0] & 0x01) == 0x01) {
      states.push("正在打印");
      states = states.filter(item => item !== '正常');
    }
    if ((data[0] & 0x02) == 0x02) {
      states.push("纸舱盖开");
      states = states.filter(item => item !== '正常');
    }
    if ((data[0] & 0x04) == 0x04) {
      states.push("缺纸");
      states = states.filter(item => item !== '正常');
    }
    if ((data[0] & 0x08) == 0x08) {
      states.push("电池电压低");
      states = states.filter(item => item !== '正常');
    }
    if ((data[0] & 0x10) == 0x10) {
      states.push("打印头过热");
      states = states.filter(item => item !== '正常');
    }
    promptAction.showToast({
      message: `打印机状态：${states.join('+')}`,
      duration: duration
    });
  }

  async safeWrite(psdk: PSDK<GenericTSPL> | PSDK<GenericCPCL> | PSDK<GenericESC>) {
    try {
      if (!this.isPrint) {
        this.isPrint = true;
        const report = await psdk.write(); //不分包发送，如果不会丢包可以不分包
        // const report = await psdk.write({
        // 	enableChunkWrite: true,
        // 	chunkSize: 20
        // });//分包发送，chunkSize:分包大小
        console.log(`safeWrite report : ${report}`);
        promptAction.showToast({
          message: '发送成功',
          duration: 1000
        });
        this.isPrint = false;
      }
    } catch (e) {
      this.isPrint = false;
      console.error(e);
      promptAction.showToast({
        message: '打印失败',
      });
    }
  }

  async onPrintTemplate() {
    if (this.connectedDevice === undefined) {
      promptAction.showToast({
        message: '请连接设备！！！',
        duration: 1000
      });
      return;
    }
    let psdk: PSDK<GenericTSPL> | PSDK<GenericCPCL> | PSDK<GenericESC>
    switch (this.cmdType) {
      case 'tspl':
        psdk = CommonUtil.tsplTemplateCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'cpcl':
        psdk = CommonUtil.cpclTemplateCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'esc':
        promptAction.showToast({
          message: 'esc 仅支持图片打印！！！',
          duration: 2000
        });
        return;
      default:
        break;
    }
  }

  async onPrintImage() {
    if (this.connectedDevice === undefined) {
      promptAction.showToast({
        message: '请连接设备！！！',
        duration: 2000
      });
      return;
    }
    let psdk: PSDK<GenericTSPL> | PSDK<GenericCPCL> | PSDK<GenericESC>
    switch (this.cmdType) {
      case 'tspl':
        psdk = CommonUtil.tsplImageCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'cpcl':
        psdk = CommonUtil.cpclImageCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      case 'esc':
        psdk = CommonUtil.escImageCmd();
        await this.safeWrite(psdk);
        console.log(psdk.command().string());
        break;
      default:
        break;
    }
    ;
  }

  async onQueryStatus() {
    if (this.connectedDevice === undefined) {
      promptAction.showToast({
        message: '请连接设备！！！',
        duration: 2000
      });
      return;
    }
    switch (this.cmdType) {
      case 'tspl':
        await this.onTsplQuery(ReadMark.State)
        break;
      case 'cpcl':
        await this.onCpclQuery(ReadMark.State)
        break;
      case 'esc':
        await this.onEscQuery(ReadMark.State)
        break;
      default:
        break;
    }
  }

  async onTsplQuery(queryType: ReadMark) {
    this.readMark = queryType
    const tspl = CommonUtil.tsplQueryCmd(queryType);
    await this.safeWrite(tspl);
  }

  async onCpclQuery(queryType: ReadMark) {
    this.readMark = queryType
    const cpcl = CommonUtil.cpclQueryCmd(queryType);
    await this.safeWrite(cpcl);
  }

  async onEscQuery(queryType: ReadMark) {
    this.readMark = queryType
    const esc = CommonUtil.escQueryCmd(queryType);
    await this.safeWrite(esc);
  }

  async onEscSetting(settingType: ReadMark, value: number) {
    if (settingType != ReadMark.PaperType) {
      this.readMark = settingType
    }
    const esc = CommonUtil.escSettingCmd(settingType, value);
    await this.safeWrite(esc);
  }

  onDisconnect() {
    try {
      if (this.connectedDevice === undefined) {
        promptAction.showToast({
          message: '请连接设备！！！',
          duration: 1000
        });
        return;
      }
      this.connectedDevice.disconnect();
      this.connectionState = '未连接';
      promptAction.showToast({
        message: '断开成功',
        duration: 2000
      });
      this.connectedDevice = undefined;
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  build() {
    Stack() {
      Row() {
        Column({ space: 15 }) {
          Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
            Text('指令：')
            Column() {
              Text('tspl')
              Radio({ value: 'tspl', group: 'radioGroup' })
                .checked(true)
                .radioStyle({
                  checkedBackgroundColor: Color.Blue
                })
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.cmdType = 'tspl';
                  }
                })
            }

            Column() {
              Text('cpcl')
              Radio({ value: 'cpcl', group: 'radioGroup' })
                .checked(false)
                .radioStyle({
                  checkedBackgroundColor: Color.Blue
                })
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.cmdType = 'cpcl';
                  }
                })
            }

            Column() {
              Text('esc')
              Radio({ value: 'esc', group: 'radioGroup' })
                .checked(false)
                .radioStyle({
                  checkedBackgroundColor: Color.Blue
                })
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.cmdType = 'esc';
                  }
                })
            }
          }.padding({ top: 30 })

          Button('开始搜索')
            .width('90%')
            .height(40)
            .onClick(() => this.discovery())
          Button('断开连接')
            .width('90%')
            .height(40)
            .onClick(() => this.onDisconnect())
          Button('打印模版')
            .width('90%')
            .height(40)
            .onClick(() => this.onPrintTemplate())
          Button('打印图片')
            .width('90%')
            .height(40)
            .onClick(() => this.onPrintImage())
          Button('查询状态')
            .width('90%')
            .height(40)
            .onClick(() => this.onQueryStatus())
          if (this.cmdType === 'esc') {
            Row({ space: FlexAlign.SpaceEvenly }) {
              Button('查询')
                .onClick(() => {
                  if (this.connectedDevice === undefined) {
                    promptAction.showToast({
                      message: '请连接设备！！！',
                      duration: 1000
                    });
                    return;
                  }
                  ActionSheet.show({
                    title: '查询',
                    message: '请选择查询内容', //弹窗内容
                    autoCancel: true, //点击遮障层时，是否关闭弹窗
                    alignment: DialogAlignment.Bottom, //弹窗位置
                    height: 300,
                    sheets: [//操作选项列表
                      {
                        title: '\n打印机信息\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.Info)
                        }
                      },
                      {
                        title: '\n打印机 Sn\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.SN)
                        }
                      },
                      {
                        title: '\n打印机 Mac\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.Mac)
                        }
                      },
                      {
                        title: '\n打印机状态\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.State)
                        }
                      },
                      {
                        title: '\n打印机固件版本\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.Version)
                        }
                      },
                      {
                        title: '\n打印机型号\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.Model)
                        }
                      },
                      {
                        title: '\n电量\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.BatteryVolume)
                        }
                      },
                      {
                        title: '\n关机时间\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.GetShutTime)
                        }
                      },
                      {
                        title: '\n蓝牙名称\n',
                        action: async () => {
                          await this.onEscQuery(ReadMark.BtName)
                        }
                      },

                    ]
                  })
                })
              Button('设置').onClick(
                () => {
                  if (this.connectedDevice === undefined) {
                    promptAction.showToast({
                      message: '请连接设备！！！',
                      duration: 1000
                    });
                    return;
                  }
                  ActionSheet.show({
                    title: '设置',
                    message: '请选择设置内容', //弹窗内容
                    autoCancel: true, //点击遮障层时，是否关闭弹窗
                    alignment: DialogAlignment.Bottom, //弹窗位置
                    sheets: [//操作选项列表
                      {
                        title: '\n设置浓度\n',
                        action: async () => {
                          ActionSheet.show({
                            title: '设置浓度',
                            message: '请选择浓度等级',
                            autoCancel: true,
                            alignment: DialogAlignment.Center,
                            sheets: [
                              {
                                title: '\n高浓度\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.Thickness, ThicknessLevel.High)
                                }
                              },
                              {
                                title: '\n中浓度\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.Thickness, ThicknessLevel.Medium)
                                }
                              },
                              {
                                title: '\n低浓度\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.Thickness, ThicknessLevel.Low)
                                }
                              }
                            ]
                          });
                        }
                      },
                      {
                        title: '\n设置关机时间\n',
                        action: async () => {
                          // await this.onEscQuery(EscQueryType.SN)
                          if (this.dialogController != null) {
                            this.dialogController.open()
                          }
                        }
                      },
                      {
                        title: '\n设置纸张类型\n',
                        action: async () => {
                          ActionSheet.show({
                            title: '设置纸张类型',
                            message: '请选择纸张类型',
                            autoCancel: true,
                            alignment: DialogAlignment.Center,
                            sheets: [
                              {
                                title: '\n折叠黑标纸\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.PaperType, PaperType.FOLDED_BLACK_LABEL_PAPER)
                                }
                              },
                              {
                                title: '\n连续卷筒纸\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.PaperType, PaperType.CONTINUOUS_REEL_PAPER)
                                }
                              },
                              {
                                title: '\n不干胶缝隙纸\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.PaperType, PaperType.NO_DRY_ADHESIVE_PAPER)
                                }
                              },
                              {
                                title: '\n打孔纸\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.PaperType, PaperType.HOLE_PAPER)
                                }
                              },
                              {
                                title: '\n纹身纸\n',
                                action: async () => {
                                  await this.onEscSetting(ReadMark.PaperType, PaperType.TATTOO_PAPER)
                                }
                              }
                            ]
                          });

                        }
                      }
                    ]
                  })
                }
              )
            }
          }
          Text(this.connectionState)
            .fontColor(Color.Red)
        }
        .layoutWeight(1)

        DevicesPage({
          devices: $discoveredDevices,
          connect: (device) => {
            this.onConnect(device)
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
    }

  }
}
