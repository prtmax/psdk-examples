import Vue from 'vue'
import {ConnectedDevice, Lifecycle} from '@psdk/frame-father';
import {CPCL, GenericCPCL} from '@psdk/cpcl';

class Printer {
  private _connectedDevice?: ConnectedDevice;
  private _cpcl?: GenericCPCL;

  init(connectedDevice: ConnectedDevice) {
    this._connectedDevice = connectedDevice;
    const lifecycle = new Lifecycle(connectedDevice);
    this._cpcl = CPCL.generic(lifecycle);
  }

  isConnected(): boolean {
    return this._connectedDevice != null;
  }

  connectedDevice(): ConnectedDevice | undefined {
    return this._connectedDevice;
  }


  cpcl(): GenericCPCL {
    if (!this._connectedDevice)
      throw Error('The device is not connected');
    return this._cpcl!;
  }
}

export default {
  install: function () {
    Vue.prototype.$printer = new Printer();
  }
}

