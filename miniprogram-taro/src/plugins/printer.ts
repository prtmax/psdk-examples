
import {ConnectedDevice, Lifecycle} from '@psdk/frame-father';
import {UpgradeCallback, UpdatePrinter} from "@psdk/frame-ota";
import { GenericTSPL, TSPL } from '@psdk/tspl';
import { GenericCPCL, CPCL } from '@psdk/cpcl';
import { GenericESC, ESC } from '@psdk/esc';

class Printer {
  private _connectedDevice?: ConnectedDevice;
  private _cpcl?: GenericCPCL;
  private _tspl?: GenericTSPL;
  private _esc?: GenericESC;

  init(connectedDevice: ConnectedDevice) {
    this._connectedDevice = connectedDevice;
    const lifecycle = new Lifecycle(connectedDevice);
      // @ts-ignore
    this._cpcl = CPCL.generic(lifecycle);
      // @ts-ignore
    this._tspl = TSPL.generic(lifecycle);
    this._esc = ESC.generic(lifecycle)
  }

  isConnected(): boolean {
    return this._connectedDevice != null;
  }

  connectedDevice(): ConnectedDevice | undefined {
    return this._connectedDevice;
  }

  upgrade(options: {
    upgradeData: Uint8Array,
    startAddress?: number,
    callback?: UpgradeCallback,
  }): UpdatePrinter {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return new UpdatePrinter({
      connectedDevice: this._connectedDevice,
      upgradeData: options.upgradeData,
      startAddress: options.startAddress,
      callback: options.callback,
    });
  }

  cpcl(): GenericCPCL {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return this._cpcl!;
  }

  tspl(): GenericTSPL {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return this._tspl!;
  }

  esc(): GenericESC {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return this._esc!;
  }
}

export default {
  // @ts-ignore
  install: (app, options) => {
    app.provide("printer", new Printer());
  },
};