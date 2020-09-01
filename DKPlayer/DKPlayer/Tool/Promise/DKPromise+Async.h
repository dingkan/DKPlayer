//
//  DKPromise+Async.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^DKPromiseAsyncFulfillBlock)(id __nullable value);
typedef void(^DKPromiseAsyncRejectBlock)(NSError *error);
typedef void(^DKPromiseAsyncBlock)(DKPromiseAsyncFulfillBlock fulfill, DKPromiseAsyncRejectBlock reject);

@interface DKPromise<Value> (Async)


+(DKPromise *)async:(DKPromiseAsyncBlock)work;

+(DKPromise *)onQueue:(dispatch_queue_t)queue
                async:(DKPromiseAsyncBlock)work;

@end

@interface DKPromise(DKAsyncAdditions) 

+(DKPromise *(^)(DKPromiseAsyncBlock))async;

+(DKPromise *(^)(dispatch_queue_t, DKPromiseAsyncBlock))work;
@end

NS_ASSUME_NONNULL_END
