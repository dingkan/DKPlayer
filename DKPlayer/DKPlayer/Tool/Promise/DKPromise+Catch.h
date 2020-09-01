//
//  DKPromise+Catch.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^DKPromiseCatchBlock)(NSError *error);

@interface DKPromise<Value> (Catch)

-(DKPromise *)catch:(DKPromiseCatchBlock)work;

-(DKPromise *)onQueue:(dispatch_queue_t)queue catch:(DKPromiseCatchBlock)work;

@end

@interface DKPromise(DKCatchAdditions)

-(DKPromise *(^)(DKPromiseCatchBlock))catch;

-(DKPromise *(^)(dispatch_queue_t, DKPromiseCatchBlock))catchOn;
@end

NS_ASSUME_NONNULL_END
