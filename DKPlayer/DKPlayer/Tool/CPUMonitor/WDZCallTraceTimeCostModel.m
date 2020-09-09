//
//  WDZCallTraceTimeModel.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "WDZCallTraceTimeCostModel.h"

@implementation WDZCallTraceTimeCostModel

-(NSString *)des{
    NSMutableString *str = [NSMutableString new];
    [str appendFormat:@"%2d| ",(int)_callDepth];
    [str appendFormat:@"%6.2f| ",_timeCost * 1000.0];
    for (int i = 0 ; i < _callDepth; i ++) {
        [str appendFormat:@"    "];
    }
    [str appendFormat:@"%s[%@ %@]",(_isClassMethod ? "+" : "-"), _className, _methodName];
    return str;
}

@end

