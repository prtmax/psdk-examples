#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EMAPIDemoDevice.h"
#import "EMAPIDemoLogEntry.h"
#import "EMAPIDemoESCBuilder.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const EMAPIDemoControllerDidChangeNotification;

@interface EMAPIDemoController : NSObject

@property(nonatomic, strong, readonly) NSMutableArray<EMAPIDemoDevice *> *devices;
@property(nonatomic, strong, readonly) NSMutableArray<EMAPIDemoLogEntry *> *requestLogs;
@property(nonatomic, strong, readonly) NSMutableArray<EMAPIDemoLogEntry *> *commandLogs;
@property(nonatomic, strong, readonly) NSMutableArray<EMAPIDemoLogEntry *> *reportLogs;
@property(nonatomic, assign, getter=isBluetoothEnabled) BOOL bluetoothEnabled;
@property(nonatomic, assign, getter=isScanning) BOOL scanning;
@property(nonatomic, assign, getter=isConnecting) BOOL connecting;
@property(nonatomic, assign, getter=isConnected) BOOL connected;
@property(nonatomic, assign, getter=isSimulationMode) BOOL simulationMode;
@property(nonatomic, copy, nullable) NSString *connectedDeviceName;
@property(nonatomic, copy, nullable) NSString *pendingActionLabel;
@property(nonatomic, strong, nullable) NSNumber *knownMtu;
@property(nonatomic, assign) NSUInteger transferSentBytes;
@property(nonatomic, assign) NSUInteger transferTotalBytes;
@property(nonatomic, copy, nullable) NSString *latestUpgradeStatus;

- (BOOL)isBusy;
- (NSString *)transferProgressText;
- (void)startScan;
- (void)stopScan;
- (void)connectDevice:(EMAPIDemoDevice *)device;
- (void)disconnect;
- (void)setSimulationModeEnabled:(BOOL)enabled;

- (void)sleepShutdown;
- (void)printSelfTestPage;
- (void)setShutdownTimeMinutes:(NSInteger)minutes;
- (void)queryRfidUid;
- (void)queryRfidCardInfo;
- (void)queryRfidPaperLength;
- (void)setRfidAuthFailureHandling;
- (void)setWifiConfigWithSsid:(NSString *)ssid password:(NSString *)password;
- (void)queryWifiConnectionState;
- (void)queryWifiHotspotInfo;
- (void)performWifiFileTransferAtURL:(nullable NSURL *)url fileType:(NSInteger)fileType;
- (void)queryDeviceInfo;
- (void)queryPrintStatus;
- (void)performEscPrintWithImage:(nullable UIImage *)image
                       paperType:(EMAPIDemoEscPaperType)paperType
                       printMode:(NSInteger)printMode
                       thickness:(NSInteger)thickness
                        compress:(BOOL)compress;
- (void)performOtaAtURL:(nullable NSURL *)url;

@end

NS_ASSUME_NONNULL_END
