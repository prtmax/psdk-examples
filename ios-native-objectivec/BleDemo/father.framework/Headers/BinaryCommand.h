//
//  BinaryCommand.h
//  Father
//
//  Created by IPRT on 2022/10/13.
//

#import "FastBinary.h"
#import "CommandClause.h"
NS_ASSUME_NONNULL_BEGIN

@interface BinaryCommand : FastBinary
-(BinaryCommand *)withData:(NSData *)data;
-(CommandClause *)clause;
@end

NS_ASSUME_NONNULL_END
