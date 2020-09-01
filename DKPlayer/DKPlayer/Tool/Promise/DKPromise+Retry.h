//
//  DKPromise+Retry.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

typedef id __nullable (^DKPromiseRetryAttempBlock)(void);
typedef BOOL(^DKPromiseRetryPredicateBlock)(NSInteger , NSError *);

@interface DKPromise<Value> (Retry)
+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry;

+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry attempts:(NSInteger)attempts;

+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry attempts:(NSInteger)attempts delay:(NSTimeInterval)delay;

+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry attempts:(NSInteger)attempts delay:(NSTimeInterval)delay onQueue:(dispatch_queue_t)queue;

+(DKPromise *)onQueue:(dispatch_queue_t)queue
             attempts:(NSInteger)attempts
                delay:(NSTimeInterval)delay
            predicate:(DKPromiseRetryPredicateBlock)predicate
                retry:(DKPromiseRetryAttempBlock)retry;
@end

@interface DKPromise (DKRetryAdditions) 

+(DKPromise *(^)(DKPromiseRetryAttempBlock))retry;
@end

NS_ASSUME_NONNULL_END
