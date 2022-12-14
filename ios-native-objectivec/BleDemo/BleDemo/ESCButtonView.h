//
//  ESCButtonView.h
//  ESCDemo
//
//  Created by IPRT on 2022/11/4.
//

#import <UIKit/UIKit.h>
typedef void (^ButtonClick)(void);
NS_ASSUME_NONNULL_BEGIN

@interface ESCButtonView : UIView
@property (nonatomic , copy)ButtonClick continuousPaperPrintingClick;
@property (nonatomic , copy)ButtonClick labelPaperPrintingClick;
@property (nonatomic , copy)ButtonClick printClick;//打印
@property (nonatomic , copy)ButtonClick nameClick;//打印机名称
@property (nonatomic , copy)ButtonClick printerStatusClick;//打印机状态
@property (nonatomic , copy)ButtonClick batteryLevelClick;//电池电量
@property (nonatomic , copy)ButtonClick bleMACAddressClick;//蓝牙MAC地址
@property (nonatomic , copy)ButtonClick bleFirmwareVersionClick;//蓝牙固件版本
@property (nonatomic , copy)ButtonClick printerFirmwareVersionClick;//打印机固件版本
@property (nonatomic , copy)ButtonClick printerSNNumberClick;//打印机SN号
@property (nonatomic , copy)ButtonClick printerModelClick;//打印机型号
@end

NS_ASSUME_NONNULL_END
