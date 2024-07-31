import { CPCL, GenericCPCL } from '@psdk/cpcl';
import { ESC, GenericESC } from '@psdk/esc';
import { ConnectedDevice, Lifecycle } from '@psdk/frame-father';
import { GenericTSPL, TSPL } from '@psdk/tspl';

export class PrinterUtil {
  static instance: PrinterUtil | null = null

  private _connectedDevice ?: ConnectedDevice;
  private _cpcl ?: GenericCPCL;
  private _tspl ?: GenericTSPL;
  private _esc ?: GenericESC;
  static getInstance() {
    if (!PrinterUtil.instance) {
      PrinterUtil.instance = new PrinterUtil()
    }
    return PrinterUtil.instance
  }

  // 设置方法为私有
  private  constructor() {
  }

  init(connectedDevice : ConnectedDevice) {
    this._connectedDevice = connectedDevice;
    const lifecycle = new Lifecycle(connectedDevice);
    this._cpcl = CPCL.generic(lifecycle);
    this._tspl = TSPL.generic(lifecycle);
    this._esc = ESC.generic(lifecycle);
  }

  isConnected() : boolean {
    return this._connectedDevice != null;
  }

  connectedDevice() : ConnectedDevice | undefined {
    return this._connectedDevice;
  }


  cpcl() : GenericCPCL {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return this._cpcl!;
  }
  tspl() : GenericTSPL {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return this._tspl!;
  }
  esc() : GenericESC {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return this._esc!;
  }
}

