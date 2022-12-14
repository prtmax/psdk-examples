//
//  CLine.h
//  CPCL
//
//  Created by IPRT on 2022/10/10.
//

#import "BasicCPCLArg.h"
#import <father/CPCLCommand.h>
NS_ASSUME_NONNULL_BEGIN

@interface CLine : BasicCPCLArg
@property (nonatomic , readonly) CLine *(^lineWidth)(int clineWidth);
@property (nonatomic , readonly) CLine *(^startX)(int cStartX);
@property (nonatomic , readonly) CLine *(^startY)(int cStartY);
@property (nonatomic , readonly) CLine *(^endX)(int cEndX);
@property (nonatomic , readonly) CLine *(^endY)(int cEndY);
@property (nonatomic , readonly) CLine *(^isSolidLine)(BOOL cIsSolidLine);
@end

NS_ASSUME_NONNULL_END
