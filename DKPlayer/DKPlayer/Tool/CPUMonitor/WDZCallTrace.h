//
//  WDZCallTrace.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/10.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WDZCallTrace : NSObject

+(void)strat;
+(void)startWithMaxDepth:(int)depth;
+(void)startWithMinCost:(double)ms;
+(void)startWithMaxDepth:(int)depth minCost:(double)ms;

+(void)stop;
+(void)save;
+(void)stopSaveAndClean;

@end

NS_ASSUME_NONNULL_END
