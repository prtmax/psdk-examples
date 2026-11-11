package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;

import com.printer.demo.R;
import com.printer.demo.entity.InfoItem;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.AddonInfo;
import com.printer.sdk.operate.AddonType;
import com.printer.sdk.operate.CardBoxStatus;
import com.printer.sdk.operate.CardSetting;
import com.printer.sdk.operate.ConsumablesInfo;
import com.printer.sdk.operate.ConsumablesSetting;
import com.printer.sdk.operate.ImageSetting;
import com.printer.sdk.operate.InterfaceSetting;
import com.printer.sdk.operate.PrintHeadInfo;
import com.printer.sdk.operate.PrinterInfo;
import com.printer.sdk.operate.PrinterSetting;
import com.printer.sdk.operate.VersionInfo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ReadInfoTask implements Runnable {
    public static final int READ_INFO = 10;
    private final Context context;
    private final CardPrinterAPI api;
    private final Printer.Serial serial;
    private final Handler handler;

    public ReadInfoTask(Context context, Handler handler, CardPrinterAPI api) {
        this.context = context;
        this.handler = handler;
        this.api = api;
        this.serial = api.getPrinterSerial();
    }

    private ArrayList<InfoItem> getInfos() throws OperationException {
        ArrayList<InfoItem> infoItems = new ArrayList<>();
        addonInfoToItems(infoItems);
        cardBoxInfoToItems(infoItems);
        consumablesInfoToItems(infoItems);
        printerInfoToItems(infoItems);
        printHeadInfoToItems(infoItems);
        versionInfoToItems(infoItems);
        cardSettingToItems(infoItems);
        consumablesSettingToItems(infoItems);
        imageSettingToItems(infoItems);
        interfaceSettingToItems(infoItems);
        printerSettingToItems(infoItems);
        return infoItems;
    }

    private void addonInfoToItems(ArrayList<InfoItem> infoItems) {
        String[] name = context.getResources().getStringArray(R.array.addon_name);
        AddonInfo addonInfo = new AddonInfo();
        api.getDataOp(addonInfo);
        infoItems.add(new InfoItem.Title(context.getString(R.string.addon_info_linked)));
        for (final AddonType type : addonInfo.getLinked()) {
            infoItems.add(new InfoItem.Property(name[type.ordinal()], "ON"));
        }
    }

    private void cardBoxInfoToItems(ArrayList<InfoItem> infoItems) {
        String[] name = context.getResources().getStringArray(R.array.addon_name);
        CardBoxStatus cardBoxStatus = new CardBoxStatus();
        api.getDataOp(cardBoxStatus);
        HashMap<AddonType, Boolean> feedingBoxStatus = cardBoxStatus.getFeedingBoxStatus();
        if (feedingBoxStatus != null) {
            infoItems.add(new InfoItem.Title(context.getString(R.string.paper_box_info)));
            for (final Map.Entry<AddonType, Boolean> entry : feedingBoxStatus.entrySet()) {
                infoItems.add(new InfoItem.Property(name[entry.getKey().ordinal()], entry.getValue() ? context.getString(R.string.has_paper) : context.getString(R.string.empty)));
            }
        }
        HashMap<AddonType, Boolean> recyclingBoxStatus = cardBoxStatus.getRecyclingBoxStatus();
        if (recyclingBoxStatus != null) {
            for (final Map.Entry<AddonType, Boolean> entry : recyclingBoxStatus.entrySet()) {
                infoItems.add(new InfoItem.Property(name[entry.getKey().ordinal()], entry.getValue() ? context.getString(R.string.full) : context.getString(R.string.not_full)));
            }
        }
    }

    private void consumablesInfoToItems(ArrayList<InfoItem> infoItems) {
        infoItems.add(new InfoItem.Title(context.getString(R.string.consumables_info)));
        ConsumablesInfo consumablesInfo = new ConsumablesInfo();
        api.getDataOp(consumablesInfo);
        if (consumablesInfo.getRibbonType() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.ribbon_type), consumablesInfo.getRibbonTypeName()));
        }
//        if (consumablesInfo.getRibbonRemaining() != null) {
//            infoItems.add(new InfoItem.Property(context.getString(R.string.ribbon_remaining), consumablesInfo.getRibbonRemaining().toString(), "%"));
//        }
        if (consumablesInfo.getRibbonThickness() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.ribbon_thickness), consumablesInfo.getRibbonThickness() == 0 ? "Thin" : "Thick"));
        }
        if (consumablesInfo.getFilmType() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.film_type), consumablesInfo.getFilmTypeName()));
        }
        if (consumablesInfo.getFilmRemaining() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.film_remaining), consumablesInfo.getFilmRemaining().toString(), "%"));
        }
    }

    private void printerInfoToItems(ArrayList<InfoItem> infoItems) {
        infoItems.add(new InfoItem.Title(context.getString(R.string.printer_info)));
        PrinterInfo printerInfo = new PrinterInfo();
        api.getDataOp(printerInfo);
        if (printerInfo.getModel() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_model), printerInfo.getModel()));
        }
        if (printerInfo.getModelId() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_model_id), printerInfo.getModelId()));
        }
        if (printerInfo.getManufacturer() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_manufacturer), printerInfo.getManufacturer()));
        }
        if (printerInfo.getDate() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_date), printerInfo.getDate()));
        }
        if (printerInfo.getPnpId() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_pnp_id), printerInfo.getPnpId()));
        }
        if (printerInfo.getSerialNumber() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_sn), printerInfo.getSerialNumber()));
        }
        if (printerInfo.getDuplexPrintingEnabled() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.double_side_print), printerInfo.getDuplexPrintingEnabled() ? "ON" : "OFF"));
        }
        if (printerInfo.getCardIssuedCount() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.paper_issued_count), printerInfo.getCardIssuedCount().toString()));
        }
        if (printerInfo.getContactReadWriteCount() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.contact_read_write_count), printerInfo.getContactReadWriteCount().toString()));
        }
        if (printerInfo.getPrintTotalCount() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.print_total_count), printerInfo.getPrintTotalCount().toString()));
        }
        if (printerInfo.getPrintSpeed() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.print_speed), printerInfo.getPrintSpeed() == 0 ? "Fast" : "Slow"));
        }
        if (printerInfo.getUcl() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.ucl), printerInfo.getUcl()));
        }
        if (printerInfo.getCurrentPrinterResolution() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_resolution), printerInfo.getCurrentPrinterResolution() == 0 ? "High Quality" : "Low Quality"));
        }
    }

    private void printHeadInfoToItems(ArrayList<InfoItem> infoItems) {
        infoItems.add(new InfoItem.Title(context.getString(R.string.print_head_info)));
        PrintHeadInfo printHeadInfo = new PrintHeadInfo();
        api.getDataOp(printHeadInfo);
        if (printHeadInfo.getPrintCount() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.print_count), printHeadInfo.getPrintCount().toString()));
        }
        if (printHeadInfo.getSerialNumber() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.serial_number), printHeadInfo.getSerialNumber()));
        }
    }

    private void versionInfoToItems(ArrayList<InfoItem> infoItems) {
        infoItems.add(new InfoItem.Title(context.getString(R.string.version_info)));
        VersionInfo versionInfo = new VersionInfo();
        api.getDataOp(versionInfo);
        if (versionInfo.getFirmwareVersion() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.firmware_version), versionInfo.getFirmwareVersion()));
        }
        if (versionInfo.getBootVersion() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.boot_version), versionInfo.getBootVersion()));
        }
        if (versionInfo.getFpgaVersion() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.fpga_version), versionInfo.getFpgaVersion()));
        }
        if (versionInfo.getLcdVersion() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.lcd_version), versionInfo.getLcdVersion()));
        }
    }

    private void cardSettingToItems(ArrayList<InfoItem> infoItems) {
        String[] offOn = {"OFF", "ON"};
        CardSetting cardSetting = new CardSetting();
        api.getDataOp(cardSetting);
        infoItems.add(new InfoItem.Title(context.getString(R.string.paper_setting), cardSetting));
        if (cardSetting.getFeedingCardMode() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.feeding_paper_mode), cardSetting.getFeedingCardMode(), feedingModeName(serial)));
        }
        if (cardSetting.getStdCardExit() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.std_paper_exit), cardSetting.getStdCardExit(), cardExitName(serial)));
        }
        if (cardSetting.getErrCardExit() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.err_paper_exit), cardSetting.getErrCardExit(), cardExitName(serial)));
        }
        if (cardSetting.getFeedingBoxEmptyDetect() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.feeding_box_empty_detect), cardSetting.getFeedingBoxEmptyDetect() ? 1 : 0, offOn));
        }
        if (cardSetting.getRecyclingBoxFullDetect() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.recycling_box_full_detect), cardSetting.getRecyclingBoxFullDetect() ? 1 : 0, offOn));
        }
        if (cardSetting.getCardType() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.paper_type), cardSetting.getCardType(), cardTypeName(serial)));
        }
        if (cardSetting.getCardEjectSide() != null) {
            String[] cardEjectSide = context.getResources().getStringArray(R.array.arr_paper_eject_side);
            infoItems.add(new InfoItem.Property(context.getString(R.string.paper_eject_side), cardSetting.getCardEjectSide(), cardEjectSide));
        }
        if (cardSetting.getExactTempControl() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.exact_temp_control), cardSetting.getExactTempControl() ? 1 : 0, offOn));
        }
        if (cardSetting.getThickness() != null) {
            String[] thickness = context.getResources().getStringArray(R.array.arr_thickness);
            infoItems.add(new InfoItem.Property(context.getString(R.string.paper_thickness), cardSetting.getThickness(), thickness));
        }
        if (cardSetting.getHoldCardWhenEject() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.hold_paper_when_eject), cardSetting.getHoldCardWhenEject() ? 1 : 0, offOn));
        }
    }

    private String[] cardTypeName(Printer.Serial serial) {
        return serial == Printer.Serial.DC8600 || serial == Printer.Serial.R600 ?
                new String[]{"PVC", "PET", "PET-G", "Card1", "Card2", "Card3"} :
                new String[]{"PVC", "PET", "PET-G", "PC"};
    }

    private String[] cardExitName(Printer.Serial serial) {
        String[] exit;
        if (serial == Printer.Serial.DC8600) {
            exit = context.getResources().getStringArray(R.array.dc8600_paper_exit);
        } else if (serial == Printer.Serial.R600) {
            exit = context.getResources().getStringArray(R.array.r600_paper_exit);
        } else {
            exit = context.getResources().getStringArray(R.array.d300kp_paper_exit);
        }
        return exit;
    }

    private String[] feedingModeName(Printer.Serial serial) {
        String[] feedingCardMode;
        if (serial == Printer.Serial.DC8600) {
            feedingCardMode = context.getResources().getStringArray(R.array.dc8600_feeding_mode);
        } else if (serial == Printer.Serial.R600) {
            feedingCardMode = context.getResources().getStringArray(R.array.r600_feeding_mode);
        } else {
            feedingCardMode = context.getResources().getStringArray(R.array.d300kp_feeding_mode);
        }
        return feedingCardMode;
    }

    private void consumablesSettingToItems(ArrayList<InfoItem> infoItems) {
        ConsumablesSetting consumablesSetting = new ConsumablesSetting();
        api.getDataOp(consumablesSetting);
        infoItems.add(new InfoItem.Title(context.getString(R.string.consumables_setting), consumablesSetting));
        if (consumablesSetting.getRibbonNearEndAlert() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.ribbon_near_end_alert), consumablesSetting.getRibbonNearEndAlert().toString(), "%", "0", "100", Integer.class, true));
        }
        if (consumablesSetting.getFilmNearEndAlert() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.film_near_end_alert), consumablesSetting.getFilmNearEndAlert().toString(), "%", "0", "100", Integer.class, true));
        }
        if (consumablesSetting.getEncryptionRetryTimes() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.encryption_retry_tiems), consumablesSetting.getEncryptionRetryTimes().toString(), "0", "5", Integer.class, true));
        }
        if (consumablesSetting.getEncryptionRetryOffset() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.encryption_retry_offset), consumablesSetting.getEncryptionRetryOffset().toString(), "0", "100", Integer.class, true));
        }
    }

    private void imageSettingToItems(ArrayList<InfoItem> infoItems) {
        if (serial == Printer.Serial.D300Kp) {
            ImageSetting imageSetting1 = new ImageSetting(true);
            ImageSetting imageSetting2 = new ImageSetting(false);
            api.getDataOp(imageSetting1);
            api.getDataOp(imageSetting2);
            infoItems.add(new InfoItem.Title(context.getString(R.string.image_setting), imageSetting1, imageSetting2));
            if (imageSetting1.getColorBrightness() != null) {
                String[] colorBrightness = context.getResources().getStringArray(R.array.d300kp_color_brightness);
                infoItems.add(new InfoItem.Property(context.getString(R.string.color_brightness), imageSetting1.getColorBrightness(), colorBrightness));
            }
            if (imageSetting1.getYellowBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.front_yellow_balance), imageSetting1.getYellowBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting1.getMagentaBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.front_magenta_balance), imageSetting1.getMagentaBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting1.getCyanBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.front_cyan_balance), imageSetting1.getCyanBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting1.getBlackBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.front_black_balance), imageSetting1.getBlackBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting1.getOverlayBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.front_overlay_balance), imageSetting1.getOverlayBalance().toString(), "-32", "32", Integer.class, true));
            }

            if (imageSetting2.getYellowBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.back_yellow_balance), imageSetting2.getYellowBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting2.getMagentaBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.back_magenta_balance), imageSetting2.getMagentaBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting2.getCyanBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.back_cyan_balance), imageSetting2.getCyanBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting2.getBlackBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.back_black_balance), imageSetting2.getBlackBalance().toString(), "-32", "32", Integer.class, true));
            }
            if (imageSetting2.getOverlayBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.back_overlay_balance), imageSetting2.getOverlayBalance().toString(), "-32", "32", Integer.class, true));
            }
        } else {
            ImageSetting imageSetting = new ImageSetting();
            api.getDataOp(imageSetting);
            infoItems.add(new InfoItem.Title(context.getString(R.string.image_setting), imageSetting));
            if (imageSetting.getColorBrightness() != null) {
                String[] colorBrightness = context.getResources().getStringArray(R.array.r600_color_brightness);
                infoItems.add(new InfoItem.Property(context.getString(R.string.color_brightness), imageSetting.getColorBrightness(), colorBrightness));
            }
            if (imageSetting.getYellowBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.yellow_balance), imageSetting.getYellowBalance().toString(), "-64", "64", Integer.class, true));
            }
            if (imageSetting.getMagentaBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.magenta_balance), imageSetting.getMagentaBalance().toString(), "-64", "64", Integer.class, true));
            }
            if (imageSetting.getCyanBalance() != null) {
                infoItems.add(new InfoItem.Property(context.getString(R.string.cyan_balance), imageSetting.getCyanBalance().toString(), "-64", "64", Integer.class, true));
            }
            if (imageSetting.getBlackBalance() != null) {
                if (serial == Printer.Serial.R600) {
                    infoItems.add(new InfoItem.Property(context.getString(R.string.black_balance), imageSetting.getBlackBalance().toString(), "-32", "32", Integer.class, true));
                } else {
                    infoItems.add(new InfoItem.Property(context.getString(R.string.black_balance), imageSetting.getBlackBalance().toString(), "-64", "64", Integer.class, true));
                }
            }
        }
    }

    private void interfaceSettingToItems(ArrayList<InfoItem> infoItems) {
        String[] offOn = {"OFF", "ON"};
        InterfaceSetting interfaceSetting = new InterfaceSetting();
        api.getDataOp(interfaceSetting);
        infoItems.add(new InfoItem.Title(context.getString(R.string.interface_setting), interfaceSetting));
        if (interfaceSetting.getIp() != null) {
            infoItems.add(new InfoItem.Property("IP", interfaceSetting.getIp(), null, null, String.class, true));
        }
        if (interfaceSetting.getMacAddress() != null) {
            infoItems.add(new InfoItem.Property("MAC", interfaceSetting.getMacAddress().toUpperCase(), null, null, String.class, false));
        }
        if (interfaceSetting.getSubnetMask() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.subnet_mask), interfaceSetting.getSubnetMask(), null, null, String.class, true));
        }
        if (interfaceSetting.getGateway() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.gateway), interfaceSetting.getGateway(), null, null, String.class, true));
        }
        if (interfaceSetting.getUseStaticIp() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.use_static_ip), interfaceSetting.getUseStaticIp() ? 1 : 0, offOn));
        }
        if (interfaceSetting.getTimeout() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.timeout), interfaceSetting.getTimeout().toString(), "0", "4294967295", Long.class, true));
        }
        if (interfaceSetting.getPrinterId() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.printer_id), interfaceSetting.getPrinterId().toString(), "0", "15", Integer.class, true));
        }
        if (interfaceSetting.getUseUsbId() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.use_usb_id), interfaceSetting.getUseUsbId() ? 1 : 0, offOn));
        }
    }

    private void printerSettingToItems(ArrayList<InfoItem> infoItems) {
        String[] offOn = {"OFF", "ON"};
        PrinterSetting printerSetting = new PrinterSetting();
        api.getDataOp(printerSetting);
        infoItems.add(new InfoItem.Title(context.getString(R.string.printer_setting), printerSetting));
        if (printerSetting.getLanguage() != null) {
            String[] language = {"中文", "日文", "英文"};
            infoItems.add(new InfoItem.Property(context.getString(R.string.language), printerSetting.getLanguage(), language));
        }
        if (printerSetting.getBuzzerEnabled() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.buzzer_enabled), printerSetting.getBuzzerEnabled() ? 1 : 0, offOn));
        }
        if (printerSetting.getLcdEnabled() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.lcd_eanbled), printerSetting.getLcdEnabled() ? 1 : 0, offOn));
        }
        if (printerSetting.getLcdBrightness() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.lcd_brightness), printerSetting.getLcdBrightness().toString(), "0", "100", Integer.class, true));
        }
        if (printerSetting.getLcdContrast() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.lcd_contrast), printerSetting.getLcdContrast().toString(), "0", "255", Integer.class, true));
        }
        if (printerSetting.getAutoShutDownTime() != null) {
            int sleepMode = printerSetting.getAutoShutDownTime();
            infoItems.add(new InfoItem.Property(context.getString(R.string.sleep_mode), Integer.toString(sleepMode), "min", "0", "1440", Integer.class, true));
        }
        if (printerSetting.getPrintMode() != null) {
            String[] items = {"标准", "快速"};
            infoItems.add(new InfoItem.Property(context.getString(R.string.print_mode), printerSetting.getPrintMode(), items));
        }
        if (printerSetting.getIgnoreRibbonWhenInit() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.ignore_ribbon_when_init), printerSetting.getIgnoreRibbonWhenInit() ? 1 : 0, offOn));
        }
        if (printerSetting.getNotEjectCardWhenInit() != null) {
            infoItems.add(new InfoItem.Property(context.getString(R.string.not_eject_paper_when_init), printerSetting.getNotEjectCardWhenInit() ? 1 : 0, offOn));
        }
    }

    @Override
    public void run() {
        try {
            List<InfoItem> infoItems = getInfos();
            handler.obtainMessage(READ_INFO, infoItems).sendToTarget();
            handler.obtainMessage(0, context.getString(R.string.op_successfully, context.getString(R.string.read_setting))).sendToTarget();
        } catch (OperationException e) {
            handler.obtainMessage(0, e.getMessage()).sendToTarget();
        }
    }
}
