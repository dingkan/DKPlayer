//
//  DKPromise+Delay.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface DKPromise (Delay)

-(DKPromise *)delay:(NSTimeInterval)time;

-(DKPromise *)onQueue:(dispatch_queue_t)queue
                 time:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
