//
//  ESCButtonView.m
//  ESCDemo
//
//  Created by IPRT on 2022/11/4.
//

#import "ESCButtonView.h"

@implementation ESCButtonView
-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self setUI];
    }
    return self;
}
-(void)setUI{
    UIButton *btn0 = [self createButtonWithFrame:CGRectMake(20, 0, 150,50) andTitle:@"连续纸打印" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn2 = [self createButtonWithFrame:CGRectMake(20, 70, 150,50) andTitle:@"电池电量" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn4 = [self createButtonWithFrame:CGRectMake(20, 140, 150,50) andTitle:@"蓝牙名称" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn6 = [self createButtonWithFrame:CGRectMake(20, 210, 150,50) andTitle:@"蓝牙固件版本" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn8 = [self createButtonWithFrame:CGRectMake(20, 280, 150,50) andTitle:@"打印机SN号" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn1 = [self createButtonWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 170, 0, 150,50) andTitle:@"标签纸打印" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn3 = [self createButtonWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 170, 70, 150,50) andTitle:@"打印机状态" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn5 = [self createButtonWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 170, 140, 150,50) andTitle:@"蓝牙MAC地址" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn7 = [self createButtonWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 170, 210, 150,50) andTitle:@"打印机固件版本" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    UIButton *btn9 = [self createButtonWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 170, 280, 150,50) andTitle:@"打印机型号" andBackgroundColor:UIColor.blueColor andCornerRadius:10];
    [btn0 addTarget:self  action:@selector(continuousPaperPrinting) forControlEvents:UIControlEventTouchUpInside];
    [btn1 addTarget:self action:@selector(labelPaperPrinting) forControlEvents:UIControlEventTouchUpInside];
    [btn2 addTarget:self action:@selector(batteryLevelAction) forControlEvents:UIControlEventTouchUpInside];
    [btn3 addTarget:self action:@selector(printerStatusAction) forControlEvents:UIControlEventTouchUpInside];
    [btn4 addTarget:self action:@selector(nameAction) forControlEvents:UIControlEventTouchUpInside];
    [btn5 addTarget:self action:@selector(bleMACAddressAction) forControlEvents:UIControlEventTouchUpInside];
    [btn6 addTarget:self action:@selector(bleFirmwareVersionAction) forControlEvents:UIControlEventTouchUpInside];
    [btn7 addTarget:self action:@selector(printerFirmwareVersionAction) forControlEvents:UIControlEventTouchUpInside];
    [btn8 addTarget:self action:@selector(printerSNNumberAction) forControlEvents:UIControlEventTouchUpInside];
    [btn9 addTarget:self action:@selector(printerModelAction) forControlEvents:UIControlEventTouchUpInside];
}
-(UIButton *)createButtonWithFrame:(CGRect)frame andTitle:(NSString *)title andBackgroundColor:(UIColor *)backgroundColor andCornerRadius:(float)radius {
    UIButton *btn = [[UIButton alloc]initWithFrame:frame];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.backgroundColor = backgroundColor;
    btn.layer.cornerRadius = radius;
    [self addSubview:btn];
    return btn;
}
-(void)continuousPaperPrinting{
    if(self.continuousPaperPrintingClick){
        self.continuousPaperPrintingClick();
    }
}
-(void)labelPaperPrinting{
    if(self.labelPaperPrintingClick){
        self.labelPaperPrintingClick();
    }
}
-(void)nameAction{
    if(self.nameClick){
        self.nameClick();
    }
}
-(void)printAction{
    if(self.printClick){
        self.printClick();
    }
}
-(void)printerStatusAction{
    if(self.printerStatusClick)self.printerStatusClick();
}
-(void)batteryLevelAction{
    if(self.batteryLevelClick)self.batteryLevelClick();
}
-(void)bleMACAddressAction{
    if(self.bleMACAddressClick)self.bleMACAddressClick();
}
-(void)bleFirmwareVersionAction{
    if(self.bleFirmwareVersionClick)self.bleFirmwareVersionClick();
}
-(void)printerFirmwareVersionAction{
    if(self.printerFirmwareVersionClick)self.printerFirmwareVersionClick();
}
-(void)printerSNNumberAction{
    if(self.printerSNNumberClick)self.printerSNNumberClick();
}
-(void)printerModelAction{
    if(self.printerModelClick)self.printerModelClick();
}

@end
