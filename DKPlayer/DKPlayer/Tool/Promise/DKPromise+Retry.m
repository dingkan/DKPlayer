//
//  DKPromise+Retry.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Retry.h"

static NSInteger DKPromiseRetryDefaultAttemptsCount = 1;
static NSTimeInterval DKPromiseRetryDefaultDelayTime = 1.0;

static void DKPromiseRetryAttemptFunc(DKPromise *promise, NSInteger attemptCount, NSTimeInterval delay, dispatch_queue_t queue, DKPromiseRetryAttempBlock work, DKPromiseRetryPredicateBlock predicate){
    
    __auto_type reject = ^(id __nullable value){
        
        if ([value isKindOfClass:[NSError class]]) {
            
            if (attemptCount <=0 || (predicate && !predicate(attemptCount,value))) {
                [promise rejected:value];
            }else{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    DKPromiseRetryAttemptFunc(promise, attemptCount - 1 , delay, queue, work, predicate);
                });
            }
            
        }else{
            [promise fulfilled:value];
        }
        
    };
    
    id value = work();
    
    if ([value isKindOfClass:[DKPromise class]]) {
        [(DKPromise *)value ObserverOnQueue:queue fulfill:reject reject:reject];
    }else{
        reject(value);
    }
    
}


@implementation DKPromise (Retry)

+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry {
    return [self retry:retry attempts:DKPromiseRetryDefaultAttemptsCount];
}

+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry attempts:(NSInteger)attempts{
    return [self retry:retry attempts:attempts delay:DKPromiseRetryDefaultDelayTime];
}

+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry attempts:(NSInteger)attempts delay:(NSTimeInterval)delay{
    return [self onQueue:DKPromise.defaultPromiseQueue attempts:attempts delay:delay predicate:nil retry:retry];
}

+(DKPromise *)retry:(DKPromiseRetryAttempBlock)retry attempts:(NSInteger)attempts delay:(NSTimeInterval)delay onQueue:(dispatch_queue_t)queue{
    return [self onQueue:queue attempts:attempts delay:delay predicate:nil retry:retry];
}

+(DKPromise *)onQueue:(dispatch_queue_t)queue
             attempts:(NSInteger)attempts
                delay:(NSTimeInterval)delay
            predicate:(DKPromiseRetryPredicateBlock)predicate
                retry:(DKPromiseRetryAttempBlock)retry{
    
    DKPromise *promise = [DKPromise pendingPromise];
    
    DKPromiseRetryAttemptFunc(promise, attempts, delay, queue, retry, predicate);
    
    return promise;
}
            

@end


@implementation DKPromise (DKRetryAdditions)

+(DKPromise *(^)(DKPromiseRetryAttempBlock))retry{
    return ^(DKPromiseRetryAttempBlock work){
        return [self retry:work];
    };
}

@end
