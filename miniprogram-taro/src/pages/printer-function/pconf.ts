import {GenericCPCL} from "@psdk/cpcl";
import {WroteReporter, Raw} from '@psdk/frame-father';
import { GenericTSPL } from "@psdk/tspl";

export interface PrinterConfTraits {
  selftest(): Promise<WroteReporter>;
}

export class CPCLPrinterConf implements PrinterConfTraits{

  private readonly cpcl: GenericCPCL;

  constructor(cpcl: GenericCPCL) {
    this.cpcl = cpcl;
  }

  async selftest(): Promise<WroteReporter> {
    return await this.cpcl
      // @ts-ignore
      .raw(Raw.binary(Uint8Array.from([0x10, 0xff, 0xbf])))
      .write();
  }

}

export class TSPLPrinterConf implements PrinterConfTraits {

  private readonly tspl: GenericTSPL;

  constructor(tspl: GenericTSPL) {
    this.tspl = tspl;
  }

  async selftest(): Promise<WroteReporter> {
    return await this.tspl
      // @ts-ignore
      .raw(Raw.text("SELFTEST"))
      .write();
  }

}
