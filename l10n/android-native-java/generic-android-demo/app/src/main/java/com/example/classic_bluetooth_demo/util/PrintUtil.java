package com.example.classic_bluetooth_demo.util;

import com.printer.psdk.cpcl.CPCL;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;

public class PrintUtil {
  private ConnectedDevice _connectedDevice;

  private GenericCPCL _cpcl;

  private GenericESC _esc;

  private GenericTSPL _tspl;

  private PrintUtil() {}

  public static PrintUtil getInstance() {
    return InstanceHolder.instance;
  }

  public ConnectedDevice connectedDevice() {
    return this._connectedDevice;
  }

  public GenericCPCL cpcl() {
    return this._cpcl;
  }

  public GenericESC esc() {
    return this._esc;
  }

  public GenericTSPL tspl() {
    return this._tspl;
  }

  public GenericTSPL rawTspl() {
    return TSPL.generic(ConnectedDevice.NONE);
  }

  public void init(ConnectedDevice paramConnectedDevice) {
    this._connectedDevice = paramConnectedDevice;
    this._cpcl = CPCL.generic(paramConnectedDevice);
    this._tspl = TSPL.generic(paramConnectedDevice);
    this._esc = ESC.generic(paramConnectedDevice);
  }

  private static final class InstanceHolder {
    static final PrintUtil instance = new PrintUtil();
  }
}
