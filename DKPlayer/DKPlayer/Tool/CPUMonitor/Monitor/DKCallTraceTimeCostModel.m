//
//  DKCallTraceTimeCostModel.m
//  DKPlayer
//
//  Created by 丁侃 on 2020/9/15.
//  Copyright © 2020 丁侃. All rights reserved.
//

#import "DKCallTraceTimeCostModel.h"

@implementation DKCallTraceTimeCostModel

-(NSString *)des{
    NSMutableString *str = [NSMutableString new];
    [str appendFormat:@"%2d| ",(int)_callDepth];
    [str appendFormat:@"%6.2f| ",_timeCost * 1000.0];
    for (NSUInteger i = 0; i < _callDepth; i ++) {
        [str appendFormat:@"    "];
    }
    [str appendFormat:@"%s[%@ %@]", (_isClassMethod ? "+" : "-"), _className, _methodName];
    return str;
}
@end
