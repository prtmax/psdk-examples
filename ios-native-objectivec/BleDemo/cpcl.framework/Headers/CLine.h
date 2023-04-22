//
//  CLine.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import <father/CPCLCommand.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 线条
 */
@interface CLine : BasicCPCLArg

/// 线条宽度
@property (nonatomic , readonly) CLine *(^lineWidth)(int clineWidth);
/// 线条左上角x坐标
@property (nonatomic , readonly) CLine *(^startX)(int cStartX);
/// 线条左上角y坐标
@property (nonatomic , readonly) CLine *(^startY)(int cStartY);
/// 线条右下角x坐标
@property (nonatomic , readonly) CLine *(^endX)(int cEndX);
/// 线条右下角y坐标
@property (nonatomic , readonly) CLine *(^endY)(int cEndY);
/// 虚线\实线:  实线:true  虚线:false(默认实线)
@property (nonatomic , readonly) CLine *(^isSolidLine)(BOOL cIsSolidLine);

@end

NS_ASSUME_NONNULL_END
