import Vue from 'vue'
import { ConnectedDevice, Lifecycle } from '@psdk/frame-father';
import { CPCL, GenericCPCL } from '@psdk/cpcl';
import { GenericTSPL, TSPL } from '@psdk/tspl';
import { ESC, GenericESC } from '@psdk/esc';

class Printer {
	private _connectedDevice ?: ConnectedDevice;
	private _cpcl ?: GenericCPCL;
	private _tspl ?: GenericTSPL;
	private _esc ?: GenericESC;
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

export default {
	install: function () {
		Vue.prototype.$printer = new Printer();
	}
}