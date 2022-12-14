//
//  WriteOptions.h
//  Father
//
//  Created by IPRT on 2022/10/25.
//

#import <Foundation/Foundation.h>
#import "IDataWriteCallback.h"
#import "CallbackData.h"
typedef void (^callbackData)(CallbackData *datawrite);
NS_ASSUME_NONNULL_BEGIN

@interface WriteOptions : NSObject
@property (nonatomic , readonly) WriteOptions * (^enableChunkWrite)(BOOL isEnableChunkWrite);
@property (nonatomic , readonly) WriteOptions * (^chunkSize)(int chunkSize);
@property (nonatomic , readonly) WriteOptions * (^callback)(IDataWriteCallback *cback);
@property (nonatomic , strong)NSData *writeData;
-(BOOL)getEnableChunkWrite;
-(int)getChunkSize;
-(IDataWriteCallback *)getCallback;
@end

NS_ASSUME_NONNULL_END
