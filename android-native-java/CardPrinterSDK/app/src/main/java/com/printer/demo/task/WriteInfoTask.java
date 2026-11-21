package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;

import com.printer.demo.R;
import com.printer.demo.entity.InfoItem;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.SetOp;
import com.printer.sdk.operate.CardSetting;
import com.printer.sdk.operate.ConsumablesSetting;
import com.printer.sdk.operate.ImageSetting;
import com.printer.sdk.operate.InterfaceSetting;
import com.printer.sdk.operate.PrinterSetting;

import java.util.ArrayList;
import java.util.List;

public class WriteInfoTask implements Runnable {
    public static final int WRITE_INFO = 11;
    private final Context context;
    private final CardPrinterAPI api;
    private final Handler handler;
    private final List<InfoItem> infoItems;

    public WriteInfoTask(Context context, Handler handler, CardPrinterAPI api, List<InfoItem> infoItems) {
        this.context = context;
        this.handler = handler;
        this.api = api;
        this.infoItems = infoItems == null ? null : new ArrayList<>(infoItems);
    }

    private void fillCardSetting(CardSetting cardSetting, List<InfoItem.Property> properties) {
        int index = 0;
        if (cardSetting.getFeedingCardMode() != null) {
            cardSetting.setFeedingCardMode(properties.get(index++).index);
        }
        if (cardSetting.getStdCardExit() != null) {
            cardSetting.setStdCardExit(properties.get(index++).index);
        }
        if (cardSetting.getErrCardExit() != null) {
            cardSetting.setErrCardExit(properties.get(index++).index);
        }
        if (cardSetting.getFeedingBoxEmptyDetect() != null) {
            cardSetting.setFeedingBoxEmptyDetect(properties.get(index++).index == 1);
        }
        if (cardSetting.getRecyclingBoxFullDetect() != null) {
            cardSetting.setRecyclingBoxFullDetect(properties.get(index++).index == 1);
        }
        if (cardSetting.getCardType() != null) {
            cardSetting.setCardType(properties.get(index++).index);
        }
        if (cardSetting.getCardEjectSide() != null) {
            cardSetting.setCardEjectSide(properties.get(index++).index);
        }
        if (cardSetting.getExactTempControl() != null) {
            cardSetting.setExactTempControl(properties.get(index++).index == 1);
        }
        if (cardSetting.getThickness() != null) {
            cardSetting.setThickness(properties.get(index++).index);
        }
        if (cardSetting.getHoldCardWhenEject() != null) {
            cardSetting.setHoldCardWhenEject(properties.get(index).index == 1);
        }
    }

    private void fillConsumablesSetting(ConsumablesSetting consumablesSetting, List<InfoItem.Property> properties) {
        int index = 0;
        if (consumablesSetting.getRibbonNearEndAlert() != null) {
            consumablesSetting.setRibbonNearEndAlert(Integer.valueOf(properties.get(index++).value));
        }
        if (consumablesSetting.getFilmNearEndAlert() != null) {
            consumablesSetting.setFilmNearEndAlert(Integer.valueOf(properties.get(index++).value));
        }
        if (consumablesSetting.getEncryptionRetryTimes() != null) {
            consumablesSetting.setEncryptionRetryTimes(Integer.valueOf(properties.get(index++).value));
        }
        if (consumablesSetting.getEncryptionRetryOffset() != null) {
            consumablesSetting.setEncryptionRetryOffset(Integer.valueOf(properties.get(index).value));
        }
    }

    private void fillImageSetting(ImageSetting imageSetting1, ImageSetting imageSetting2, List<InfoItem.Property> properties) {
        int index = 0;
        if (imageSetting1.getColorBrightness() != null) {
            imageSetting1.setColorBrightness(properties.get(index++).index);
        }
        if (imageSetting1.getYellowBalance() != null) {
            imageSetting1.setYellowBalance(Integer.valueOf(properties.get(index++).value));
        }
        if (imageSetting1.getMagentaBalance() != null) {
            imageSetting1.setMagentaBalance(Integer.valueOf(properties.get(index++).value));
        }
        if (imageSetting1.getCyanBalance() != null) {
            imageSetting1.setCyanBalance(Integer.valueOf(properties.get(index++).value));
        }
        if (imageSetting1.getBlackBalance() != null) {
            imageSetting1.setBlackBalance(Integer.valueOf(properties.get(index++).value));
        }
        if (imageSetting1.getOverlayBalance() != null) {
            imageSetting1.setOverlayBalance(Integer.valueOf(properties.get(index++).value));
        }


        if (imageSetting2 != null) {
            imageSetting2.setColorBrightness(null);
            if (imageSetting2.getYellowBalance() != null) {
                imageSetting2.setYellowBalance(Integer.valueOf(properties.get(index++).value));
            }
            if (imageSetting2.getMagentaBalance() != null) {
                imageSetting2.setMagentaBalance(Integer.valueOf(properties.get(index++).value));
            }
            if (imageSetting2.getCyanBalance() != null) {
                imageSetting2.setCyanBalance(Integer.valueOf(properties.get(index++).value));
            }
            if (imageSetting2.getBlackBalance() != null) {
                imageSetting2.setBlackBalance(Integer.valueOf(properties.get(index++).value));
            }
            if (imageSetting2.getOverlayBalance() != null) {
                imageSetting2.setOverlayBalance(Integer.valueOf(properties.get(index).value));
            }
        }
    }

    private void fillInterfaceSetting(InterfaceSetting interfaceSetting, List<InfoItem.Property> properties) {
        int index = 0;
        if (interfaceSetting.getIp() != null) {
            interfaceSetting.setIp(properties.get(index++).value);
        }
        // if (interfaceSetting.getMacAddress() != null) {
        //     interfaceSetting.setMacAddress(properties.get(index++).value);
        // }
        if (interfaceSetting.getSubnetMask() != null) {
            interfaceSetting.setSubnetMask(properties.get(index++).value);
        }
        if (interfaceSetting.getGateway() != null) {
            interfaceSetting.setGateway(properties.get(index++).value);
        }
        if (interfaceSetting.getUseStaticIp() != null) {
            interfaceSetting.setUseStaticIp(properties.get(index++).index == 1);
        }
        if (interfaceSetting.getTimeout() != null) {
            interfaceSetting.setTimeout(Long.valueOf(properties.get(index++).value));
        }
        if (interfaceSetting.getPrinterId() != null) {
            interfaceSetting.setPrinterId(Integer.valueOf(properties.get(index++).value));
        }
        if (interfaceSetting.getUseUsbId() != null) {
            interfaceSetting.setUseUsbId(properties.get(index).index == 1);
        }
    }

    private void fillPrinterSetting(PrinterSetting printerSetting, List<InfoItem.Property> properties) {
        int index = 0;
        if (printerSetting.getLanguage() != null) {
            printerSetting.setLanguage(properties.get(index++).index);
        }
        if (printerSetting.getBuzzerEnabled() != null) {
            printerSetting.setBuzzerEnabled(properties.get(index++).index == 1);
        }
        if (printerSetting.getLcdEnabled() != null) {
            printerSetting.setLcdEnabled(properties.get(index++).index == 1);
        }
        if (printerSetting.getLcdBrightness() != null) {
            printerSetting.setLcdBrightness(Integer.valueOf(properties.get(index++).value));
        }
        if (printerSetting.getLcdContrast() != null) {
            printerSetting.setLcdContrast(Integer.valueOf(properties.get(index++).value));
        }
        if (printerSetting.getAutoShutDownTime() != null) {
            printerSetting.setAutoShutDownTime(Integer.valueOf(properties.get(index++).value));
        }
        if (printerSetting.getPrintMode() != null) {
            printerSetting.setPrintMode(properties.get(index++).index);
        }
        if (printerSetting.getIgnoreRibbonWhenInit() != null) {
            printerSetting.setIgnoreRibbonWhenInit(properties.get(index++).index == 1);
        }
        if (printerSetting.getNotEjectCardWhenInit() != null) {
            printerSetting.setNotEjectCardWhenInit(properties.get(index).index == 1);
        }
    }

    private List<SetOp> fillBack(SetOp op1, SetOp op2, List<InfoItem.Property> properties) {
        if (op1 instanceof CardSetting) {
            fillCardSetting((CardSetting) op1, properties);
        } else if (op1 instanceof ConsumablesSetting) {
            fillConsumablesSetting((ConsumablesSetting) op1, properties);
        } else if (op1 instanceof ImageSetting) {
            fillImageSetting((ImageSetting) op1, (ImageSetting) op2, properties);
        } else if (op1 instanceof InterfaceSetting) {
            fillInterfaceSetting((InterfaceSetting) op1, properties);
        } else if (op1 instanceof PrinterSetting) {
            fillPrinterSetting((PrinterSetting) op1, properties);
        }
        List<SetOp> setOps = new ArrayList<>();
        setOps.add(op1);
        setOps.add(op2);
        return setOps;
    }

    @Override
    public void run() {
        if (infoItems == null) {
            handler.obtainMessage(0, context.getString(R.string.read_setting_first)).sendToTarget();
            return;
        }
        try {
            ArrayList<SetOp> setOps = new ArrayList<>();
            SetOp setOp1 = null, setOp2 = null;
            final List<InfoItem.Property> writableProperties = new ArrayList<>();
            for (final InfoItem item : infoItems) {
                if (item instanceof InfoItem.Title) {
                    if (setOp1 != null) {
                        setOps.addAll(fillBack(setOp1, setOp2, writableProperties));
                        writableProperties.clear();
                    }
                    setOp1 = null;
                    InfoItem.Title title = (InfoItem.Title) item;
                    if (title.setOp1 != null) {
                        setOp1 = title.setOp1;
                    }
                    if (title.setOp2 != null) {
                        setOp2 = title.setOp2;
                    }
                } else if (item instanceof InfoItem.Property) {
                    InfoItem.Property property = (InfoItem.Property) item;
                    if (property.writable) {
                        writableProperties.add(property);
                    }
                }
            }
            if (setOp1 != null) {
                setOps.addAll(fillBack(setOp1, setOp2, writableProperties));
            }
            for (final SetOp op : setOps) {
                if (op != null) {
                    api.setDataOp(op);
                }
            }
            handler.obtainMessage(0, context.getString(R.string.op_successfully, context.getString(R.string.write_setting))).sendToTarget();
        } catch (OperationException e) {
            handler.obtainMessage(0, e.getMessage()).sendToTarget();
        }
    }
}
